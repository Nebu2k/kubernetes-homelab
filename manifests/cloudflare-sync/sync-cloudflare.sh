#!/bin/sh
# Cloudflare DNS A/AAAA Sync Script
# Publishes PUBLIC services directly under the home connection's public IP.
#
# Reads `homelab.io/expose: public` from Ingresses and Services and creates/updates
# A and AAAA records in Cloudflare pointing at the home public IP, which is resolved
# at runtime from a DynDNS hostname (the router keeps that hostname up to date).
#
# Internal services are NOT published here — they are only reachable via VPN and get
# their DNS from AdGuard (see adguard-sync).
#
# Environment variables (from SealedSecret):
#   CF_API_TOKEN    - Cloudflare API token
#   CF_ZONE_ID      - Cloudflare Zone ID
#   CF_DOMAIN       - Base domain (e.g. elmstreet79.de)
#   DDNS_HOSTNAME   - DynDNS hostname tracking the home public IP (e.g. nebu2k.ipv64.net)

set -e

echo "═══════════════════════════════════════════════════════"
echo "🌐 Cloudflare DNS Sync (public services → home IP)"
echo "═══════════════════════════════════════════════════════"

# Validate required env vars
for VAR in CF_API_TOKEN CF_ZONE_ID CF_DOMAIN DDNS_HOSTNAME; do
  eval "VAL=\${${VAR}}"
  if [ -z "${VAL}" ]; then
    echo "❌ Missing required environment variable: ${VAR}"
    exit 1
  fi
done

# Resolve the home public IP from the DynDNS hostname (IPv4 + IPv6)
CF_IPV4=$(dig +short A "${DDNS_HOSTNAME}" | grep -E '^[0-9]+\.' | head -n1)
CF_IPV6=$(dig +short AAAA "${DDNS_HOSTNAME}" | grep -E '^[0-9a-fA-F:]+$' | head -n1)

if [ -z "${CF_IPV4}" ] && [ -z "${CF_IPV6}" ]; then
  echo "❌ Failed to resolve ${DDNS_HOSTNAME}, aborting"
  exit 1
fi

echo "   Zone: ${CF_ZONE_ID}"
echo "   Domain: ${CF_DOMAIN}"
echo "   DynDNS: ${DDNS_HOSTNAME}"
echo "   A target (home IPv4):  ${CF_IPV4:-none}"
echo "   AAAA target (home IPv6): ${CF_IPV6:-none}"
echo "═══════════════════════════════════════════════════════"
echo ""

# Get service account token for Kubernetes API
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
K8S_API="https://kubernetes.default.svc"
CA="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

CF_API="https://api.cloudflare.com/client/v4"

# Counter files for summary (also used for hosts list, subshell-safe)
COUNTER_DIR=$(mktemp -d)
echo "0" > "${COUNTER_DIR}/updated"
echo "0" > "${COUNTER_DIR}/skipped"
echo "0" > "${COUNTER_DIR}/removed"

# Helper: upsert a single record type for a host. Skips when target IP is empty.
# Returns 0 when a change was made, 1 when unchanged/skipped.
upsert_record() {
  TYPE="$1"   # A | AAAA
  HOST="$2"
  CONTENT="$3"

  [ -z "${CONTENT}" ] && return 1

  EXISTING=$(curl -s "${CF_API}/zones/${CF_ZONE_ID}/dns_records?name=${HOST}&type=${TYPE}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" | jq -r '.result[0] // empty')
  REC_ID=$(echo "${EXISTING}" | jq -r '.id // empty')
  REC_CONTENT=$(echo "${EXISTING}" | jq -r '.content // empty')

  BODY="{\"type\":\"${TYPE}\",\"name\":\"${HOST}\",\"content\":\"${CONTENT}\",\"ttl\":1,\"proxied\":false,\"comment\":\"managed-by: cloudflare-sync\"}"

  if [ -n "${REC_ID}" ]; then
    if [ "${REC_CONTENT}" = "${CONTENT}" ]; then
      echo "    ✓ ${TYPE} ${HOST} → ${CONTENT} (unchanged)"
      return 1
    fi
    curl -s -X PUT "${CF_API}/zones/${CF_ZONE_ID}/dns_records/${REC_ID}" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" \
      -d "${BODY}" > /dev/null
    echo "    ✓ ${TYPE} ${HOST} → ${CONTENT} (updated)"
    return 0
  fi
  curl -s -X POST "${CF_API}/zones/${CF_ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" \
    -d "${BODY}" > /dev/null
  echo "    ✓ ${TYPE} ${HOST} → ${CONTENT} (created)"
  return 0
}

sync_records() {
  HOST="$1"
  CHANGED=1
  upsert_record "A" "${HOST}" "${CF_IPV4}" && CHANGED=0
  upsert_record "AAAA" "${HOST}" "${CF_IPV6}" && CHANGED=0
  if [ "${CHANGED}" = "0" ]; then
    echo "$(($(cat "${COUNTER_DIR}/updated") + 1))" > "${COUNTER_DIR}/updated"
  else
    echo "$(($(cat "${COUNTER_DIR}/skipped") + 1))" > "${COUNTER_DIR}/skipped"
  fi
}

# --- Fetch Ingresses with homelab.io/expose=public ---
echo "📡 Fetching Ingresses with homelab.io/expose=public ..."
ALL_INGRESSES=$(curl -s --cacert "${CA}" -H "Authorization: Bearer ${TOKEN}" \
  "${K8S_API}/apis/networking.k8s.io/v1/ingresses")

INGRESS_HOSTS=$(echo "${ALL_INGRESSES}" | jq -r '
  .items[] |
  select(.metadata.annotations["homelab.io/expose"] == "public") |
  .spec.rules[].host
' 2>/dev/null || echo "")

# --- Fetch Services with homelab.io/expose=public and an explicit homelab.io/host ---
echo "📡 Fetching Services with homelab.io/expose=public ..."
ALL_SERVICES=$(curl -s --cacert "${CA}" -H "Authorization: Bearer ${TOKEN}" \
  "${K8S_API}/api/v1/services")

SERVICE_HOSTS=$(echo "${ALL_SERVICES}" | jq -r '
  .items[] |
  select(.metadata.annotations["homelab.io/expose"] == "public") |
  select(.metadata.annotations["homelab.io/host"] != null) |
  .metadata.annotations["homelab.io/host"]
' 2>/dev/null || echo "")

# --- Merge and deduplicate ---
HOSTS=$(printf "%s\n%s\n" "${INGRESS_HOSTS}" "${SERVICE_HOSTS}" | grep -v '^$' | grep -v '^null$' | sort -u)

HOST_COUNT=$(echo "${HOSTS}" | grep -c . || echo 0)
echo "✓ Found ${HOST_COUNT} public hosts to sync"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📤 Syncing DNS records..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

printf "%s\n" "${HOSTS}" > "${COUNTER_DIR}/desired_hosts"

echo "${HOSTS}" | while IFS= read -r HOST; do
  [ -z "${HOST}" ] && continue
  echo "  ${HOST}..."
  sync_records "${HOST}"
done

# --- Remove stale records (managed by us but no longer desired) ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗑️  Checking for stale records..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CF_ALL_A=$(curl -s "${CF_API}/zones/${CF_ZONE_ID}/dns_records?type=A&per_page=1000&comment=managed-by%3A+cloudflare-sync" \
  -H "Authorization: Bearer ${CF_API_TOKEN}")
CF_ALL_AAAA=$(curl -s "${CF_API}/zones/${CF_ZONE_ID}/dns_records?type=AAAA&per_page=1000&comment=managed-by%3A+cloudflare-sync" \
  -H "Authorization: Bearer ${CF_API_TOKEN}")

MANAGED_RECORDS=$(echo "${CF_ALL_A}" | jq -r '.result[] | "\(.id) \(.name)"'; \
  echo "${CF_ALL_AAAA}" | jq -r '.result[] | "\(.id) \(.name)"')

echo "${MANAGED_RECORDS}" | while IFS= read -r LINE; do
  [ -z "${LINE}" ] && continue
  REC_ID=$(echo "${LINE}" | cut -d' ' -f1)
  REC_NAME=$(echo "${LINE}" | cut -d' ' -f2-)

  if ! grep -qx "${REC_NAME}" "${COUNTER_DIR}/desired_hosts"; then
    curl -s -X DELETE "${CF_API}/zones/${CF_ZONE_ID}/dns_records/${REC_ID}" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" > /dev/null
    echo "    🗑️  Removed ${REC_NAME} (${REC_ID})"
    echo "$(($(cat "${COUNTER_DIR}/removed") + 1))" > "${COUNTER_DIR}/removed"
  fi
done

# --- Summary ---
echo ""
echo "═══════════════════════════════════════════════════════"
echo "📊 DNS Sync Summary"
echo "═══════════════════════════════════════════════════════"
echo "   ✓ Skipped (unchanged):  $(cat "${COUNTER_DIR}/skipped")"
echo "   🔄 Updated/Created:     $(cat "${COUNTER_DIR}/updated")"
echo "   🗑️  Removed (stale):     $(cat "${COUNTER_DIR}/removed")"
