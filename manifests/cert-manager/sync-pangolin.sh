#!/bin/sh
set -e
set -o pipefail

# Required environment variables (provided by Kubernetes Secret):
# - API_KEY: Pangolin API authentication key
# - ORG_ID: Organization ID
# - SITE_ID: Site ID for target registration
# - API_BASE_URL: Base URL for Pangolin API
# - DOMAIN_SUFFIX: Domain suffix for resource FQDNs (e.g., elmstreet79.de)
# - DOMAIN_ID: Pangolin domain ID

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
  "https://kubernetes.default.svc/api/v1/services" | \
  jq -r --arg suffix "${DOMAIN_SUFFIX}" '.items[] | 
    select(.metadata.annotations["pangolin.io/expose"] == "true") | 
    {
      name: .metadata.name,
      namespace: .metadata.namespace,
      subdomain: ((.metadata.annotations["pangolin.io/subdomain"] // .metadata.name) as $sub | if $sub == "@" then "" else $sub end),
      auth: ((.metadata.annotations["pangolin.io/auth"] // "true") == "true"),
      port: (.spec.ports[0].port // .spec.ports[0].name),
      host: ((.metadata.annotations["pangolin.io/subdomain"] // .metadata.name) as $sub | if $sub == "@" then $suffix else ($sub + "." + $suffix) end)
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

while IFS= read -r service; do
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
  
  # Find the service port spec matching the annotation
  # SERVICE_PORT can be a name or number
  if echo "${SERVICE_PORT}" | grep -qE '^[0-9]+$'; then
    # Numeric port - find by port number
    PORT_SPEC=$(echo "${SVC_DATA}" | jq -r ".spec.ports[] | select(.port == ${SERVICE_PORT})")
  else
    # Named port - find by name
    PORT_SPEC=$(echo "${SVC_DATA}" | jq -r ".spec.ports[] | select(.name == \"${SERVICE_PORT}\")")
  fi
  
  if [ -z "${PORT_SPEC}" ]; then
    echo "    ⚠️  Could not find port spec for '${SERVICE_PORT}', skipping"
    continue
  fi
  
  
  # Get the targetPort from the port spec (can be name or number)
  TARGET_PORT_VALUE=$(echo "${PORT_SPEC}" | jq -r '.targetPort // .port')
  
  echo "    → Service port: ${SERVICE_PORT}, target port: ${TARGET_PORT_VALUE}"
  
  # Determine target IP and port based on service type
  if [ "${SVC_TYPE}" = "LoadBalancer" ]; then
    # LoadBalancer services use their own external IP
    TARGET_IP=$(echo "${SVC_DATA}" | jq -r '.status.loadBalancer.ingress[0].ip // empty')
    
    # For LoadBalancer, use the targetPort from service spec
    if echo "${TARGET_PORT_VALUE}" | grep -qE '^[0-9]+$'; then
      TARGET_PORT="${TARGET_PORT_VALUE}"
    else
      # Named targetPort on LoadBalancer - should not happen, but fallback to service port
      TARGET_PORT=$(echo "${PORT_SPEC}" | jq -r '.port')
    fi
    
    if [ -z "${TARGET_IP}" ]; then
      echo "    ⚠️  LoadBalancer IP not assigned yet, skipping"
      continue
    fi
    
    echo "    → LoadBalancer service: ${TARGET_IP}:${TARGET_PORT}"
    
  elif [ "${SVC_TYPE}" = "ClusterIP" ] || [ "${SVC_TYPE}" = "NodePort" ]; then
    # Check if this is an external service (Endpoints pointing outside cluster)
    ENDPOINTS=$(curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer ${TOKEN}" \
      "https://kubernetes.default.svc/api/v1/namespaces/${NAMESPACE}/endpoints/${NAME}")
    
    ENDPOINT_IP=$(echo "${ENDPOINTS}" | jq -r '.subsets[0].addresses[0].ip // empty')
    
    # Check if endpoint IP is outside cluster network (10.42.x.x or 10.43.x.x = cluster IPs)
    if [ -n "${ENDPOINT_IP}" ] && ! echo "${ENDPOINT_IP}" | grep -qE '^10\.(42|43)\.'; then
      # External endpoint - use it directly (e.g., dreambox, proxmox)
      TARGET_IP="${ENDPOINT_IP}"
      
      # Match endpoint port
      if echo "${TARGET_PORT_VALUE}" | grep -qE '^[0-9]+$'; then
        TARGET_PORT=$(echo "${ENDPOINTS}" | jq -r ".subsets[0].ports[] | select(.port == ${TARGET_PORT_VALUE}) | .port // empty" | head -n1)
      else
        TARGET_PORT=$(echo "${ENDPOINTS}" | jq -r ".subsets[0].ports[] | select(.name == \"${TARGET_PORT_VALUE}\") | .port // empty" | head -n1)
      fi
      
      if [ -z "${TARGET_PORT}" ]; then
        if echo "${TARGET_PORT_VALUE}" | grep -qE '^[0-9]+$'; then
          TARGET_PORT="${TARGET_PORT_VALUE}"
        else
          echo "    ⚠️  Could not resolve target port '${TARGET_PORT_VALUE}' in endpoints, skipping"
          continue
        fi
      fi
      
      echo "    → External service: ${TARGET_IP}:${TARGET_PORT}"
    else
      # Internal cluster service - route via Traefik LoadBalancer
      TARGET_IP="192.168.2.250"
      TARGET_PORT="443"
      echo "    → Internal cluster service - routing via Traefik LB: ${TARGET_IP}:${TARGET_PORT}"
    fi
    
  elif [ "${SVC_TYPE}" = "ExternalName" ]; then
    echo "    ⚠️  ExternalName services not supported, skipping"
    continue
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
        # Reload resources after update
        PANGOLIN_RESOURCES=$(curl -s -H "Authorization: Bearer ${API_KEY}" "${API_BASE_URL}/org/${ORG_ID}/resources" | jq -r ".data.resources // []")
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
          # Reload resources after update
          PANGOLIN_RESOURCES=$(curl -s -H "Authorization: Bearer ${API_KEY}" "${API_BASE_URL}/org/${ORG_ID}/resources" | jq -r ".data.resources // []")
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
    
    # Build JSON payload - conditionally include subdomain field
    if [ "${SUBDOMAIN}" = "" ]; then
      # Root domain - omit subdomain field
      JSON_PAYLOAD=$(jq -n \
        --arg name "${NAME}" \
        --arg domainId "${DOMAIN_ID}" \
        '{
          name: $name,
          http: true,
          protocol: "tcp",
          domainId: $domainId
        }')
    else
      # Subdomain - include subdomain field
      JSON_PAYLOAD=$(jq -n \
        --arg name "${NAME}" \
        --arg subdomain "${SUBDOMAIN}" \
        --arg domainId "${DOMAIN_ID}" \
        '{
          name: $name,
          subdomain: $subdomain,
          http: true,
          protocol: "tcp",
          domainId: $domainId
        }')
    fi
    
    # Use /org/:orgId/resource endpoint (domain-based HTTP resources)
    CREATE_RESPONSE=$(curl -s -X PUT \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      "${API_BASE_URL}/org/${ORG_ID}/resource" \
      -d "${JSON_PAYLOAD}")
    
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
        
        if echo "${UPDATE_RESPONSE}" | jq -e '.success' > /dev/null; then
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
        # Reload resources after create
        PANGOLIN_RESOURCES=$(curl -s -H "Authorization: Bearer ${API_KEY}" "${API_BASE_URL}/org/${ORG_ID}/resources" | jq -r ".data.resources // []")
      else
        echo "    ❌ Failed to create target: $(echo ${TARGET_RESPONSE} | jq -r '.message // "Unknown error"')"
      fi
    fi
  fi
done < <(echo "${ALL_SERVICES}" | jq -c '.[]')

# Step 2: Remove orphaned resources
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗑️  Checking for orphaned resources..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REMOVED=0

while IFS= read -r resource; do
  FULL_DOMAIN=$(echo "${resource}" | jq -r '.fullDomain // empty')
  RESOURCE_ID=$(echo "${resource}" | jq -r '.resourceId')
  
  # Skip if no domain
  if [ -z "${FULL_DOMAIN}" ]; then
    continue
  fi
  
  # Check if this host exists in our service list
  if ! echo "${ALL_SERVICES}" | jq -e ".[] | select(.host == \"${FULL_DOMAIN}\")" > /dev/null; then
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
  fi
done < <(echo "${PANGOLIN_RESOURCES}" | jq -rc 'if type == "array" then .[] else empty end')

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
