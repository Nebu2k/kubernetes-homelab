#!/bin/sh
# AdGuard Home DNS-Rewrite Sync Script
# Split-horizon DNS for LAN/VPN clients.
#
# Reads `homelab.io/expose` (public OR internal) from Ingresses and Services and
# creates AdGuard Home DNS rewrites `host -> TARGET_IP` (the Traefik LoadBalancer),
# so LAN and VPN clients reach every service via the internal ingress and avoid NAT
# hairpinning. Public hosts additionally have public Cloudflare records (see
# cloudflare-sync); internal hosts exist ONLY here and are thus VPN-only.
#
# Rewrites are written to the AdGuard primary; adguardhome-sync replicates them to
# the secondary instances.
#
# Environment variables (from SealedSecret):
#   ADGUARD_URL       - Base URL of the AdGuard primary (e.g. http://192.168.2.16)
#   ADGUARD_USERNAME  - AdGuard admin username
#   ADGUARD_PASSWORD  - AdGuard admin password
#   TARGET_IP         - Rewrite target (Traefik LoadBalancer, e.g. 192.168.2.250)

set -e

echo "═══════════════════════════════════════════════════════"
echo "🛡️  AdGuard DNS-Rewrite Sync (internal split-horizon)"
echo "═══════════════════════════════════════════════════════"

for VAR in ADGUARD_URL ADGUARD_USERNAME ADGUARD_PASSWORD TARGET_IP; do
  eval "VAL=\${${VAR}}"
  if [ -z "${VAL}" ]; then
    echo "❌ Missing required environment variable: ${VAR}"
    exit 1
  fi
done

echo "   AdGuard: ${ADGUARD_URL}"
echo "   Target:  ${TARGET_IP}"
echo "═══════════════════════════════════════════════════════"
echo ""

AUTH="${ADGUARD_USERNAME}:${ADGUARD_PASSWORD}"

# Kubernetes API access
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
K8S_API="https://kubernetes.default.svc"
CA="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

COUNTER_DIR=$(mktemp -d)
echo "0" > "${COUNTER_DIR}/added"
echo "0" > "${COUNTER_DIR}/removed"

# --- Desired hosts: all exposed ingresses + services (public AND internal) ---
echo "📡 Fetching exposed Ingresses ..."
ALL_INGRESSES=$(curl -s --cacert "${CA}" -H "Authorization: Bearer ${TOKEN}" \
  "${K8S_API}/apis/networking.k8s.io/v1/ingresses")
INGRESS_HOSTS=$(echo "${ALL_INGRESSES}" | jq -r '
  .items[] |
  select(.metadata.annotations["homelab.io/expose"] == "public"
      or .metadata.annotations["homelab.io/expose"] == "internal") |
  .spec.rules[].host
' 2>/dev/null || echo "")

echo "📡 Fetching exposed Services ..."
ALL_SERVICES=$(curl -s --cacert "${CA}" -H "Authorization: Bearer ${TOKEN}" \
  "${K8S_API}/api/v1/services")
SERVICE_HOSTS=$(echo "${ALL_SERVICES}" | jq -r '
  .items[] |
  select(.metadata.annotations["homelab.io/expose"] == "public"
      or .metadata.annotations["homelab.io/expose"] == "internal") |
  select(.metadata.annotations["homelab.io/host"] != null) |
  .metadata.annotations["homelab.io/host"]
' 2>/dev/null || echo "")

DESIRED=$(printf "%s\n%s\n" "${INGRESS_HOSTS}" "${SERVICE_HOSTS}" | grep -v '^$' | grep -v '^null$' | sort -u)
printf "%s\n" "${DESIRED}" > "${COUNTER_DIR}/desired_hosts"
echo "✓ Found $(echo "${DESIRED}" | grep -c .) hosts to map → ${TARGET_IP}"
echo ""

# --- Existing rewrites managed by us (answer == TARGET_IP) ---
EXISTING=$(curl -s -u "${AUTH}" "${ADGUARD_URL}/control/rewrite/list" \
  | jq -r --arg ip "${TARGET_IP}" '.[] | select(.answer == $ip) | .domain' 2>/dev/null || echo "")
printf "%s\n" "${EXISTING}" > "${COUNTER_DIR}/existing_hosts"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📤 Adding missing rewrites..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "${DESIRED}" | while IFS= read -r HOST; do
  [ -z "${HOST}" ] && continue
  if grep -qx "${HOST}" "${COUNTER_DIR}/existing_hosts"; then
    echo "    ✓ ${HOST} → ${TARGET_IP} (unchanged)"
  else
    curl -s -u "${AUTH}" -X POST "${ADGUARD_URL}/control/rewrite/add" \
      -H "Content-Type: application/json" \
      -d "{\"domain\":\"${HOST}\",\"answer\":\"${TARGET_IP}\"}" > /dev/null
    echo "    ➕ ${HOST} → ${TARGET_IP} (added)"
    echo "$(($(cat "${COUNTER_DIR}/added") + 1))" > "${COUNTER_DIR}/added"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗑️  Removing stale rewrites..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "${EXISTING}" | while IFS= read -r HOST; do
  [ -z "${HOST}" ] && continue
  if ! grep -qx "${HOST}" "${COUNTER_DIR}/desired_hosts"; then
    curl -s -u "${AUTH}" -X POST "${ADGUARD_URL}/control/rewrite/delete" \
      -H "Content-Type: application/json" \
      -d "{\"domain\":\"${HOST}\",\"answer\":\"${TARGET_IP}\"}" > /dev/null
    echo "    🗑️  ${HOST} (removed)"
    echo "$(($(cat "${COUNTER_DIR}/removed") + 1))" > "${COUNTER_DIR}/removed"
  fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "📊 AdGuard Sync Summary"
echo "═══════════════════════════════════════════════════════"
echo "   ➕ Added:   $(cat "${COUNTER_DIR}/added")"
echo "   🗑️  Removed: $(cat "${COUNTER_DIR}/removed")"
