#!/bin/sh
# Cloudflare DNS A/AAAA Sync Script
# Reads pangolin.io/expose annotations from Ingresses and Services,
# creates/updates A and AAAA records in Cloudflare pointing to the Pangolin VPS.
#
# Environment variables (from SealedSecret):
#   CF_API_TOKEN    - Cloudflare API token
#   CF_ZONE_ID      - Cloudflare Zone ID
#   CF_DOMAIN       - Base domain (e.g. elmstreet79.de)
#   CF_IPV4         - A record target IP (Pangolin VPS)
#   CF_IPV6         - AAAA record target IP (Pangolin VPS)

set -e

echo "═══════════════════════════════════════════════════════"
echo "🌐 Cloudflare DNS Sync"
echo "═══════════════════════════════════════════════════════"
echo "   Zone: ${CF_ZONE_ID}"
echo "   Domain: ${CF_DOMAIN}"
echo "   A target: ${CF_IPV4}"
echo "   AAAA target: ${CF_IPV6}"
echo "═══════════════════════════════════════════════════════"
echo ""

# Validate required env vars
for VAR in CF_API_TOKEN CF_ZONE_ID CF_DOMAIN CF_IPV4 CF_IPV6; do
  eval "VAL=\${${VAR}}"
  if [ -z "${VAL}" ]; then
    echo "❌ Missing required environment variable: ${VAR}"
    exit 1
  fi
done

# Get service account token for Kubernetes API
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
K8S_API="https://kubernetes.default.svc"
CA="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

CF_API="https://api.cloudflare.com/client/v4"

# Counter files for summary (also used for hosts list, subshell-safe)
COUNTER_DIR=$(mktemp -d)
echo "0" > "${COUNTER_DIR}/created"
echo "0" > "${COUNTER_DIR}/updated"
echo "0" > "${COUNTER_DIR}/skipped"
echo "0" > "${COUNTER_DIR}/removed"

# Helper: ensure A and AAAA records exist for a given hostname
sync_records() {
  local HOST="$1"
  local SUBDOMAIN="$2"

  # Fetch existing A and AAAA records for this name
  local EXISTING_A=$(curl -s "${CF_API}/zones/${CF_ZONE_ID}/dns_records?name=${HOST}&type=A" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" | jq -r '.result[0] // empty')
  local EXISTING_AAAA=$(curl -s "${CF_API}/zones/${CF_ZONE_ID}/dns_records?name=${HOST}&type=AAAA" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" | jq -r '.result[0] // empty')

  local A_ID=$(echo "${EXISTING_A}" | jq -r '.id // empty')
  local A_CONTENT=$(echo "${EXISTING_A}" | jq -r '.content // empty')
  local AAAA_ID=$(echo "${EXISTING_AAAA}" | jq -r '.id // empty')
  local AAAA_CONTENT=$(echo "${EXISTING_AAAA}" | jq -r '.content // empty')

  local CHANGED=false

  # --- A Record ---
  if [ -n "${A_ID}" ]; then
    if [ "${A_CONTENT}" = "${CF_IPV4}" ]; then
      echo "    ✓ A ${HOST} → ${CF_IPV4} (unchanged)"
    else
      curl -s -X PUT "${CF_API}/zones/${CF_ZONE_ID}/dns_records/${A_ID}" \
        -H "Authorization: Bearer ${CF_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"A\",\"name\":\"${HOST}\",\"content\":\"${CF_IPV4}\",\"ttl\":1,\"proxied\":false,\"comment\":\"managed-by: cloudflare-sync\"}" > /dev/null
      echo "    ✓ A ${HOST} → ${CF_IPV4} (updated)"
      CHANGED=true
    fi
  else
    curl -s -X POST "${CF_API}/zones/${CF_ZONE_ID}/dns_records" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"A\",\"name\":\"${HOST}\",\"content\":\"${CF_IPV4}\",\"ttl\":1,\"proxied\":false,\"comment\":\"managed-by: cloudflare-sync\"}" > /dev/null
    echo "    ✓ A ${HOST} → ${CF_IPV4} (created)"
    CHANGED=true
  fi

  # --- AAAA Record ---
  if [ -n "${AAAA_ID}" ]; then
    if [ "${AAAA_CONTENT}" = "${CF_IPV6}" ]; then
      echo "    ✓ AAAA ${HOST} → ${CF_IPV6} (unchanged)"
    else
      curl -s -X PUT "${CF_API}/zones/${CF_ZONE_ID}/dns_records/${AAAA_ID}" \
        -H "Authorization: Bearer ${CF_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"AAAA\",\"name\":\"${HOST}\",\"content\":\"${CF_IPV6}\",\"ttl\":1,\"proxied\":false,\"comment\":\"managed-by: cloudflare-sync\"}" > /dev/null
      echo "    ✓ AAAA ${HOST} → ${CF_IPV6} (updated)"
      CHANGED=true
    fi
  else
    curl -s -X POST "${CF_API}/zones/${CF_ZONE_ID}/dns_records" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"AAAA\",\"name\":\"${HOST}\",\"content\":\"${CF_IPV6}\",\"ttl\":1,\"proxied\":false,\"comment\":\"managed-by: cloudflare-sync\"}" > /dev/null
    echo "    ✓ AAAA ${HOST} → ${CF_IPV6} (created)"
    CHANGED=true
  fi

  if [ "${CHANGED}" = "true" ]; then
    echo "$(($(cat "${COUNTER_DIR}/updated") + 1))" > "${COUNTER_DIR}/updated"
  else
    echo "$(($(cat "${COUNTER_DIR}/skipped") + 1))" > "${COUNTER_DIR}/skipped"
  fi
}

# --- Fetch Ingresses with pangolin.io/expose ---
echo "📡 Fetching Ingresses with pangolin.io/expose annotation..."
ALL_INGRESSES=$(curl -s --cacert "${CA}" -H "Authorization: Bearer ${TOKEN}" \
  "${K8S_API}/apis/networking.k8s.io/v1/ingresses")

INGRESS_HOSTS=$(echo "${ALL_INGRESSES}" | jq -r '
  .items[] |
  select(.metadata.annotations["pangolin.io/expose"] == "true") |
  .spec.rules[].host
' 2>/dev/null || echo "")

# --- Fetch Services with pangolin.io/expose ---
echo "📡 Fetching Services with pangolin.io/expose annotation..."
ALL_SERVICES=$(curl -s --cacert "${CA}" -H "Authorization: Bearer ${TOKEN}" \
  "${K8S_API}/api/v1/services")

SERVICE_HOSTS=$(echo "${ALL_SERVICES}" | jq -r --arg domain "${CF_DOMAIN}" '
  .items[] |
  select(.metadata.annotations["pangolin.io/expose"] == "true") |
  select(.metadata.annotations["pangolin.io/subdomain"] != null) |
  .metadata.annotations["pangolin.io/subdomain"] + "." + $domain
' 2>/dev/null || echo "")

# --- Merge and deduplicate ---
HOSTS=$(printf "%s\n%s\n" "${INGRESS_HOSTS}" "${SERVICE_HOSTS}" | grep -v '^$' | grep -v '^null$' | sort -u)

HOST_COUNT=$(echo "${HOSTS}" | wc -l | tr -d ' ')
echo "✓ Found ${HOST_COUNT} unique hosts to sync"
echo ""

# --- Sync each host ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📤 Syncing DNS records..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

printf "%s\n" "${HOSTS}" > "${COUNTER_DIR}/desired_hosts"

echo "${HOSTS}" | while IFS= read -r HOST; do
  [ -z "${HOST}" ] && continue
  # Extract subdomain from host (strip .elmstreet79.de)
  SUBDOMAIN=$(echo "${HOST}" | sed "s/\.${CF_DOMAIN}$//")
  echo "  ${HOST}..."
  sync_records "${HOST}" "${SUBDOMAIN}"
done

# --- Remove stale records (A/AAAA pointing to our IPs but no longer in desired hosts) ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗑️  Checking for stale records..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Fetch all A and AAAA records with our managed comment (paginated: up to 1000)
CF_ALL_A=$(curl -s "${CF_API}/zones/${CF_ZONE_ID}/dns_records?type=A&per_page=1000&comment=managed-by%3A+cloudflare-sync" \
  -H "Authorization: Bearer ${CF_API_TOKEN}")
CF_ALL_AAAA=$(curl -s "${CF_API}/zones/${CF_ZONE_ID}/dns_records?type=AAAA&per_page=1000&comment=managed-by%3A+cloudflare-sync" \
  -H "Authorization: Bearer ${CF_API_TOKEN}")

# Output as "id name"
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
SKIPPED=$(cat "${COUNTER_DIR}/skipped")
UPDATED=$(cat "${COUNTER_DIR}/updated")
REMOVED=$(cat "${COUNTER_DIR}/removed")

echo ""
echo "═══════════════════════════════════════════════════════"
echo "📊 DNS Sync Summary"
echo "═══════════════════════════════════════════════════════"
echo "   ✓ Skipped (unchanged):  ${SKIPPED}"
echo "   🔄 Updated/Created:     ${UPDATED}"
echo "   🗑️  Removed (stale):     ${REMOVED}"
echo "═══════════════════════════════════════════════════════"
echo "✅ Cloudflare DNS sync complete!"
echo ""

rm -rf "${COUNTER_DIR}"
