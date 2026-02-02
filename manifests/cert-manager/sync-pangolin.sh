#!/bin/sh
set -e
set -o pipefail

API_KEY="${API_KEY}"
ORG_ID="${ORG_ID}"
SITE_ID="${SITE_ID}"
API_BASE_URL="${API_BASE_URL}"
DOMAIN_SUFFIX="${DOMAIN_SUFFIX}"
DOMAIN_ID="${DOMAIN_ID}"

echo "═══════════════════════════════════════════════════════"
echo "🔄 Pangolin Resource Sync"
echo "═══════════════════════════════════════════════════════"
echo "   API: ${API_BASE_URL}"
echo "   Org: ${ORG_ID}"
echo "   Site: ${SITE_ID}"
echo "   Domain: *.${DOMAIN_SUFFIX}"
echo "═══════════════════════════════════════════════════════"
echo ""

# Get service account token
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Fetch Services with Pangolin labels
echo "📡 Fetching Services with pangolin.io/expose annotation..."
ALL_SERVICES=$(curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer ${TOKEN}" \
  "https://kubernetes.default.svc/api/v1/services?limit=500" | \
  jq -r --arg suffix "${DOMAIN_SUFFIX}" '.items[] | 
    select(.metadata.annotations["pangolin.io/expose"] == "true") | 
    {
      name: .metadata.name,
      namespace: .metadata.namespace,
      subdomain: (.metadata.annotations["pangolin.io/subdomain"] // .metadata.name),
      auth: ((.metadata.annotations["pangolin.io/auth"] // "true") == "true"),
      port: (.metadata.annotations["pangolin.io/port"] // .spec.ports[0].port // .spec.ports[0].name),
      host: (let $sub = .metadata.annotations["pangolin.io/subdomain"] // .metadata.name; if $sub == "@" then $suffix else $sub + "." + $suffix end)
    }' | jq -s '.')

SERVICE_COUNT=$(echo "${ALL_SERVICES}" | jq 'length')
echo "✓ Found ${SERVICE_COUNT} services with pangolin.io/expose label"
echo ""

# Display services
echo "Services to sync:"
echo "${ALL_SERVICES}" | jq -r '.[] | "  • \(.host) → \(.namespace)/\(.name):\(.port) (auth: \(.auth))"'
echo ""

# Fetch current Pangolin resources
echo "📥 Fetching existing Pangolin resources..."
PANGOLIN_RESOURCES=$(curl -s -H "Authorization: Bearer ${API_KEY}" \
  "${API_BASE_URL}/org/${ORG_ID}/resources" | \
  jq -r '.data.resources // []')

PANGOLIN_COUNT=$(echo "${PANGOLIN_RESOURCES}" | jq 'length')
echo "✓ Found ${PANGOLIN_COUNT} existing Pangolin resources"
echo ""

# Step 1: Create/Update resources in Pangolin
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📤 Syncing resources to Pangolin..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ADDED=0
UPDATED=0
SKIPPED=0

echo "${ALL_SERVICES}" | jq -c '.[]' | while IFS= read -r service; do
  HOST=$(echo "${service}" | jq -r '.host')
  SUBDOMAIN=$(echo "${service}" | jq -r '.subdomain')
  NAME=$(echo "${service}" | jq -r '.name')
  NAMESPACE=$(echo "${service}" | jq -r '.namespace')
  SERVICE_PORT=$(echo "${service}" | jq -r '.port')
  REQUIRE_AUTH=$(echo "${service}" | jq -r '.auth')

  # Resolve service backend IP
  echo "  Resolving ${NAMESPACE}/${NAME}:${SERVICE_PORT}..."
  
  # Get service details
  SVC_DATA=$(curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer ${TOKEN}" \
    "https://kubernetes.default.svc/api/v1/namespaces/${NAMESPACE}/services/${NAME}")
  
  SVC_TYPE=$(echo "${SVC_DATA}" | jq -r '.spec.type // "ClusterIP"')
  
  # Resolve named ports to numbers (e.g., "http" → 80)
  if ! echo "${SERVICE_PORT}" | grep -qE '^[0-9]+$'; then
    echo "    → Resolving named port '${SERVICE_PORT}'..."
    NUMERIC_PORT=$(echo "${SVC_DATA}" | jq -r ".spec.ports[] | select(.name == \"${SERVICE_PORT}\") | .port // empty")
    
    if [ -z "${NUMERIC_PORT}" ]; then
      echo "    ⚠️  Could not resolve named port '${SERVICE_PORT}', skipping"
      continue
    fi
    
    SERVICE_PORT="${NUMERIC_PORT}"
    echo "    → Resolved to port ${SERVICE_PORT}"
  fi
  
  if [ "${SVC_TYPE}" = "ClusterIP" ] || [ "${SVC_TYPE}" = "ExternalName" ]; then
    # For ClusterIP, check if it's an external service (has Endpoints)
    ENDPOINTS=$(curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer ${TOKEN}" \
      "https://kubernetes.default.svc/api/v1/namespaces/${NAMESPACE}/endpoints/${NAME}")
    
    TARGET_IP=$(echo "${ENDPOINTS}" | jq -r '.subsets[0].addresses[0].ip // empty')
    
    # Try matching by port number first, then fall back to port name
    TARGET_PORT=$(echo "${ENDPOINTS}" | jq -r ".subsets[0].ports[] | select(.port == ${SERVICE_PORT} or .name == \"${SERVICE_PORT}\") | .port // empty" | head -n1)
    
    if [ -z "${TARGET_PORT}" ]; then
      # Fallback: use SERVICE_PORT directly
      TARGET_PORT="${SERVICE_PORT}"
    fi
    
    if [ -z "${TARGET_IP}" ]; then
      # Fallback to service cluster IP (for internal services)
      TARGET_IP=$(echo "${SVC_DATA}" | jq -r '.spec.clusterIP // empty')
      TARGET_PORT="${SERVICE_PORT}"
    fi
  elif [ "${SVC_TYPE}" = "LoadBalancer" ]; then
    TARGET_IP=$(echo "${SVC_DATA}" | jq -r '.status.loadBalancer.ingress[0].ip // empty')
    TARGET_PORT="${SERVICE_PORT}"
  else
    echo "    ⚠️  Unknown service type: ${SVC_TYPE}, skipping"
    continue
  fi

  if [ -z "${TARGET_IP}" ]; then
    echo "    ⚠️  Could not resolve backend IP for ${NAME}, skipping"
    continue
  fi
  
  if [ -z "${TARGET_PORT}" ]; then
    echo "    ⚠️  Could not resolve target port for ${NAME}, skipping"
    continue
  fi

  echo "    → Target: https://${TARGET_IP}:${TARGET_PORT}"

  # Check if resource already exists in Pangolin (match by fullDomain)
  EXISTING_RESOURCE_ID=$(echo "${PANGOLIN_RESOURCES}" | jq -r ".[] | select(.fullDomain == \"${HOST}\") | .resourceId")
  EXISTING_TARGETS=$(echo "${PANGOLIN_RESOURCES}" | jq -r ".[] | select(.fullDomain == \"${HOST}\") | .targets | length")

  if [ -n "${EXISTING_RESOURCE_ID}" ]; then
    # Resource exists - check if targets need update
    if [ "${EXISTING_TARGETS}" = "0" ]; then
      echo "    🔄 Updating ${HOST} (adding target)"
      
      TARGET_RESPONSE=$(curl -s -X PUT \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        "${API_BASE_URL}/resource/${EXISTING_RESOURCE_ID}/target" \
        -d "{
          \"siteId\": ${SITE_ID},
          \"ip\": \"${TARGET_IP}\",
          \"port\": ${TARGET_PORT},
          \"method\": \"https\"
        }")
      
      if echo "${TARGET_RESPONSE}" | jq -e '.success' > /dev/null; then
        echo "    ✓ Updated ${HOST} → ${TARGET_IP}:${TARGET_PORT}"
        UPDATED=$((UPDATED + 1))
      else
        echo "    ❌ Failed to add target: $(echo ${TARGET_RESPONSE} | jq -r '.message // "Unknown error"')"
      fi
    else
      # Target exists - check if IP/port changed
      EXISTING_TARGET=$(echo "${PANGOLIN_RESOURCES}" | jq -r ".[] | select(.fullDomain == \"${HOST}\") | .targets[0]")
      EXISTING_TARGET_ID=$(echo "${EXISTING_TARGET}" | jq -r '.targetId // empty')
      EXISTING_IP=$(echo "${EXISTING_TARGET}" | jq -r '.ip // empty')
      EXISTING_PORT=$(echo "${EXISTING_TARGET}" | jq -r '.port // empty')
      
      if [ "${EXISTING_IP}" != "${TARGET_IP}" ] || [ "${EXISTING_PORT}" != "${TARGET_PORT}" ]; then
        echo "    🔄 Updating ${HOST} target (${EXISTING_IP}:${EXISTING_PORT} → ${TARGET_IP}:${TARGET_PORT})"
        
        # Delete old target
        if [ -n "${EXISTING_TARGET_ID}" ]; then
          DELETE_TARGET_RESPONSE=$(curl -s -X DELETE \
            -H "Authorization: Bearer ${API_KEY}" \
            "${API_BASE_URL}/resource/${EXISTING_RESOURCE_ID}/target/${EXISTING_TARGET_ID}")
        fi
        
        # Create new target
        TARGET_RESPONSE=$(curl -s -X PUT \
          -H "Authorization: Bearer ${API_KEY}" \
          -H "Content-Type: application/json" \
          "${API_BASE_URL}/resource/${EXISTING_RESOURCE_ID}/target" \
          -d "{
            \"siteId\": ${SITE_ID},
            \"ip\": \"${TARGET_IP}\",
            \"port\": ${TARGET_PORT},
            \"method\": \"https\"
          }")
        
        if echo "${TARGET_RESPONSE}" | jq -e '.success' > /dev/null; then
          echo "    ✓ Updated ${HOST} → ${TARGET_IP}:${TARGET_PORT}"
          UPDATED=$((UPDATED + 1))
        else
          echo "    ❌ Failed to update target: $(echo ${TARGET_RESPONSE} | jq -r '.message // "Unknown error"')"
        fi
      else
        echo "    ✓ ${HOST} (already exists)"
        SKIPPED=$((SKIPPED + 1))
      fi
    fi
  else
    # Create new resource
    echo "    ➕ Creating ${HOST}"
    
    # Use /org/:orgId/resource endpoint (domain-based HTTP resources)
    CREATE_RESPONSE=$(curl -s -X PUT \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      "${API_BASE_URL}/org/${ORG_ID}/resource" \
      -d "{
        \"name\": \"${NAME}\",
        \"subdomain\": \"${SUBDOMAIN}\",
        \"http\": true,
        \"protocol\": \"tcp\",
        \"domainId\": \"${DOMAIN_ID}\"
      }")
    
    RESOURCE_ID=$(echo "${CREATE_RESPONSE}" | jq -r '.data.resourceId // empty')
    
    if [ -z "${RESOURCE_ID}" ]; then
      echo "    ❌ Failed: $(echo ${CREATE_RESPONSE} | jq -r '.message // "Unknown error"')"
    else
      # For public services (auth: false), disable SSO via POST update
      if [ "${REQUIRE_AUTH}" = "false" ]; then
        echo "    → Disabling SSO (public service)"
        UPDATE_RESPONSE=$(curl -s -X POST \
          -H "Authorization: Bearer ${API_KEY}" \
          -H "Content-Type: application/json" \
          "${API_BASE_URL}/resource/${RESOURCE_ID}" \
          -d '{"sso": false}')
        
        if echo "${UPDATE_RESPONSE}" | jq -e '.success' > /dev/null 2>&1; then
          echo "    ✓ SSO disabled"
        fi
      fi
      
      # Create target (backend)
      TARGET_RESPONSE=$(curl -s -X PUT \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        "${API_BASE_URL}/resource/${RESOURCE_ID}/target" \
        -d "{
          \"siteId\": ${SITE_ID},
          \"ip\": \"${TARGET_IP}\",
          \"port\": ${TARGET_PORT},
          \"method\": \"https\"
        }")
      
      if echo "${TARGET_RESPONSE}" | jq -e '.success' > /dev/null; then
        echo "    ✓ Created ${HOST} → ${TARGET_IP}:${TARGET_PORT}"
        ADDED=$((ADDED + 1))
      else
        echo "    ❌ Failed to create target: $(echo ${TARGET_RESPONSE} | jq -r '.message // "Unknown error"')"
      fi
    fi
  fi
done

# Step 2: Remove orphaned resources
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗑️  Checking for orphaned resources..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REMOVED=0

echo "${PANGOLIN_RESOURCES}" | jq -c --argjson k8s_services "${ALL_SERVICES}" '
  ($k8s_services | map(.host)) as $k8s_hosts |
  .[] | select(.fullDomain and ($k8s_hosts | index(.fullDomain) | not))
' | while IFS= read -r resource; do
  FULL_DOMAIN=$(echo "${resource}" | jq -r '.fullDomain')
  RESOURCE_ID=$(echo "${resource}" | jq -r '.resourceId')

  echo "  ✗ Removing orphaned resource: ${FULL_DOMAIN}"
  
  DELETE_RESPONSE=$(curl -s -X DELETE \
    -H "Authorization: Bearer ${API_KEY}" \
    "${API_BASE_URL}/resource/${RESOURCE_ID}")
  if echo "${DELETE_RESPONSE}" | jq -e '.success' > /dev/null; then
    echo "    ✓ Removed"
    REMOVED=$((REMOVED + 1))
  else
    echo "    ❌ Failed to remove: $(echo "${DELETE_RESPONSE}" | jq -r '.message // "Unknown error"')"
  fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "📊 Sync Summary"
echo "═══════════════════════════════════════════════════════"
echo "   ✓ Skipped (unchanged):  ${SKIPPED}"
echo "   ➕ Added:                ${ADDED}"
echo "   🔄 Updated:              ${UPDATED}"
echo "   ✗ Removed:              ${REMOVED}"
echo "═══════════════════════════════════════════════════════"
echo "✅ Pangolin sync complete!"
echo ""
