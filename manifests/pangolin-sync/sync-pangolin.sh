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

# Resolve cluster egress IPs via DynDNS (IPv4 + IPv6)
NSLOOKUP_OUT=$(nslookup nebu2k.ipv64.net)
EGRESS_IPV4=$(echo "${NSLOOKUP_OUT}" | grep -E '^Address: [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | awk '{print $2}')
EGRESS_IPV6=$(echo "${NSLOOKUP_OUT}" | grep -E '^Address: [0-9a-fA-F:]+$' | awk '{print $2}')
if [ -z "${EGRESS_IPV4}" ] && [ -z "${EGRESS_IPV6}" ]; then
  echo "❌ Failed to resolve nebu2k.ipv64.net, aborting"
  exit 1
fi
# Build space-separated list of CIDR values for rule management
# Include public egress IPs + internal networks
EGRESS_CIDRS=""
[ -n "${EGRESS_IPV4}" ] && EGRESS_CIDRS="${EGRESS_IPV4}/32"
[ -n "${EGRESS_IPV6}" ] && EGRESS_CIDRS="${EGRESS_CIDRS} ${EGRESS_IPV6}/128"
# Add internal networks
EGRESS_CIDRS="${EGRESS_CIDRS} 192.168.2.0/24 2a00:1e:7c41:df00::/64"
echo "   Egress IPv4: ${EGRESS_IPV4:-none} (nebu2k.ipv64.net)"
echo "   Egress IPv6: ${EGRESS_IPV6:-none} (nebu2k.ipv64.net)"
echo "   Internal IPv4: 192.168.2.0/24"
echo "   Internal IPv6: 2a00:1e:7c41:df00::/64"
echo ""

# Get service account token
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Step 1: Fetch Ingresses with Pangolin annotations
echo "📡 Fetching Ingresses with pangolin.io/expose annotation..."

# Fetch all ingresses cluster-wide
ALL_INGRESSES_RAW=$(curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer ${TOKEN}" \
  "https://kubernetes.default.svc/apis/networking.k8s.io/v1/ingresses?limit=500")

# Check if response has items (valid response)
if echo "${ALL_INGRESSES_RAW}" | jq -e '.items' > /dev/null 2>&1; then
  INGRESS_SERVICES=$(echo "${ALL_INGRESSES_RAW}" | jq --arg suffix "${DOMAIN_SUFFIX}" '[.items[] |
    select(.metadata.annotations["pangolin.io/expose"]? == "true") |
    . as $ing |
    .spec.rules[] |
    {
      name: .http.paths[0].backend.service.name,
      namespace: $ing.metadata.namespace,
      subdomain: (if .host == $suffix then "" else (.host | split(".")[0]) end),
      auth: (($ing.metadata.annotations["pangolin.io/auth"] // "true") == "true"),
      port: (.http.paths[0].backend.service.port.number // .http.paths[0].backend.service.port.name),
      host: .host,
      method: ($ing.metadata.annotations["pangolin.io/method"] // null),
      source: "ingress"
    }]')
else
  echo "  ⚠️  Could not fetch ingresses (check RBAC permissions)"
  INGRESS_SERVICES="[]"
fi

INGRESS_COUNT=$(echo "${INGRESS_SERVICES}" | jq 'length')
echo "✓ Found ${INGRESS_COUNT} ingresses with pangolin.io/expose annotation"

# Step 2: Fetch Services with Pangolin annotations
echo "📡 Fetching Services with pangolin.io/expose annotation..."
SERVICE_SERVICES=$(curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer ${TOKEN}" \
  "https://kubernetes.default.svc/api/v1/services" | \
  jq -r --arg suffix "${DOMAIN_SUFFIX}" '[.items[]? |
    select(.metadata.annotations["pangolin.io/expose"]? == "true") |
    {
      name: .metadata.name,
      namespace: .metadata.namespace,
      subdomain: ((.metadata.annotations["pangolin.io/subdomain"] // .metadata.name) as $sub | if $sub == "@" then "" else $sub end),
      auth: ((.metadata.annotations["pangolin.io/auth"] // "true") == "true"),
      port: (.spec.ports[0].port // .spec.ports[0].name),
      host: ((.metadata.annotations["pangolin.io/subdomain"] // .metadata.name) as $sub | if $sub == "@" then $suffix else ($sub + "." + $suffix) end),
      method: (.metadata.annotations["pangolin.io/method"] // null),
      source: "service"
    }] // []')

SERVICE_SERVICE_COUNT=$(echo "${SERVICE_SERVICES}" | jq 'length')
echo "✓ Found ${SERVICE_SERVICE_COUNT} services with pangolin.io/expose annotation"

# Step 3: Merge and deduplicate (Ingress takes precedence over Service)
echo "🔄 Merging sources and removing duplicates..."
ALL_SERVICES=$(printf '%s\n%s' "${INGRESS_SERVICES}" "${SERVICE_SERVICES}" | jq -s --arg suffix "${DOMAIN_SUFFIX}" '
  (.[0] + .[1]) |
  group_by(.host) |
  map(
    if (map(select(.source == "ingress")) | length) > 0 then
      map(select(.source == "ingress"))[0]
    else
      .[0]
    end
  )
')

TOTAL_COUNT=$(echo "${ALL_SERVICES}" | jq 'length')
echo "✓ Total unique services to sync: ${TOTAL_COUNT}"
echo ""

# Display services
echo "Services to sync:"
echo "${ALL_SERVICES}" | jq -r '.[] | "  • \(.host) → \(.namespace)/\(.name):\(.port) (auth: \(.auth), source: \(.source))"'
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

# Use temp files to track counters (workaround for subshell issue with pipes)
COUNTER_DIR="/tmp/pangolin-sync-$$"
mkdir -p "${COUNTER_DIR}"
echo "0" > "${COUNTER_DIR}/added"
echo "0" > "${COUNTER_DIR}/updated"
echo "0" > "${COUNTER_DIR}/skipped"

echo "${ALL_SERVICES}" | jq -c '.[]' | while IFS= read -r service; do
  HOST=$(echo "${service}" | jq -r '.host')
  SUBDOMAIN=$(echo "${service}" | jq -r '.subdomain')
  NAME=$(echo "${service}" | jq -r '.name')
  NAMESPACE=$(echo "${service}" | jq -r '.namespace')
  SERVICE_PORT=$(echo "${service}" | jq -r '.port')
  REQUIRE_AUTH=$(echo "${service}" | jq -r '.auth')
  NEEDS_RECONCILE=false

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
    # Check if endpoint points to a Pod (has targetRef.kind == "Pod")
    # If it has a Pod reference, it's a cluster pod (even with hostNetwork) and should use LB
    ENDPOINT_IS_POD=$(echo "${ENDPOINTS}" | jq -r '.subsets[0].addresses[0].targetRef.kind // empty')

    # External service = IP outside cluster network AND not pointing to a Pod
    if [ -n "${ENDPOINT_IP}" ] && ! echo "${ENDPOINT_IP}" | grep -qE '^10\.(42|43)\.' && [ "${ENDPOINT_IS_POD}" != "Pod" ]; then
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
      # Internal cluster service (or hostNetwork pod) - route via Traefik LoadBalancer
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

  # Check if resource already exists in Pangolin (match by fullDomain)
  EXISTING_RESOURCE_ID=$(echo "${PANGOLIN_RESOURCES}" | jq -r ".[] | select(.fullDomain == \"${HOST}\") | .resourceId")
  EXISTING_TARGETS_JSON=$(echo "${PANGOLIN_RESOURCES}" | jq -r ".[] | select(.fullDomain == \"${HOST}\") | .targets")

  # Determine expected method:
  # - Internal cluster services routed via Traefik LB (192.168.2.250:443) → always https
  # - External services: use Service port (443 → https, else http)
  # - Annotation pangolin.io/method overrides everything
  ANNOTATION_METHOD=$(echo "${service}" | jq -r '.method // empty')
  SVC_PORT_NUM=$(echo "${PORT_SPEC}" | jq -r '.port')

  if [ -n "${ANNOTATION_METHOD}" ]; then
    EXPECTED_METHOD="${ANNOTATION_METHOD}"
  elif [ "${TARGET_IP}" = "192.168.2.250" ]; then
    EXPECTED_METHOD="https"
  elif [ "${SVC_PORT_NUM}" = "443" ]; then
    EXPECTED_METHOD="https"
  else
    EXPECTED_METHOD="http"
  fi
  echo "    → Desired target: ${EXPECTED_METHOD}://${TARGET_IP}:${TARGET_PORT}"

  if [ -n "${EXISTING_RESOURCE_ID}" ]; then
    # Resource exists - reconcile ALL targets
    EXISTING_TARGET_COUNT=$(echo "${EXISTING_TARGETS_JSON}" | jq 'length')
    # Check if we have exactly one target with correct IP, port and method
    CORRECT_TARGET_COUNT=$(echo "${EXISTING_TARGETS_JSON}" | jq --arg ip "${TARGET_IP}" --argjson port "${TARGET_PORT}" --arg method "${EXPECTED_METHOD}" \
      '[.[] | select(.ip == $ip and .port == $port and .method == $method)] | length')

    # If we have exactly 1 correct target and no other targets, we're done
    if [ "${EXISTING_TARGET_COUNT}" = "1" ] && [ "${CORRECT_TARGET_COUNT}" = "1" ]; then
      echo "    ✓ ${HOST} (already correct)"
      RULES_CHANGED=false

      # Ensure egress CIDR rules exist for auth: true services
      if [ "${REQUIRE_AUTH}" = "true" ]; then
        EXISTING_RULES=$(curl -s -H "Authorization: Bearer ${API_KEY}" \
          "${API_BASE_URL}/resource/${EXISTING_RESOURCE_ID}/rules")

        # Remove stale CIDR rules (not in current EGRESS_CIDRS)
        for LINE in $(echo "${EXISTING_RULES}" | jq -r '.data.rules[] | select(.match == "CIDR") | .ruleId | tostring'); do
          RULE_VAL=$(echo "${EXISTING_RULES}" | jq -r --arg id "${LINE}" '.data.rules[] | select((.ruleId | tostring) == $id) | .value')
          KEEP=false
          for CIDR in ${EGRESS_CIDRS}; do
            [ "${RULE_VAL}" = "${CIDR}" ] && KEEP=true
          done
          if [ "${KEEP}" = "false" ]; then
            curl -s -X DELETE \
              -H "Authorization: Bearer ${API_KEY}" \
              "${API_BASE_URL}/resource/${EXISTING_RESOURCE_ID}/rule/${LINE}" > /dev/null
            echo "    🗑️  Removed stale CIDR rule (${RULE_VAL})"
            RULES_CHANGED=true
          fi
        done

        # Add missing egress CIDR rules
        PRIO=10
        for CIDR in ${EGRESS_CIDRS}; do
          HAS=$(echo "${EXISTING_RULES}" | jq -r --arg c "${CIDR}" '[.data.rules[] | select(.match == "CIDR" and .value == $c)] | length')
          if [ "${HAS}" = "0" ]; then
            curl -s -X PUT \
              -H "Authorization: Bearer ${API_KEY}" \
              -H "Content-Type: application/json" \
              "${API_BASE_URL}/resource/${EXISTING_RESOURCE_ID}/rule" \
              -d "{
                \"action\": \"ACCEPT\",
                \"match\": \"CIDR\",
                \"value\": \"${CIDR}\",
                \"priority\": ${PRIO},
                \"enabled\": true
              }" > /dev/null
            echo "    ✓ Egress CIDR rule added (${CIDR})"
            RULES_CHANGED=true
          fi
          PRIO=$((PRIO + 1))
        done

        # Ensure applyRules is enabled (POST is idempotent, Pangolin does not return this field in GET)
        curl -s -X POST \
          -H "Authorization: Bearer ${API_KEY}" \
          -H "Content-Type: application/json" \
          "${API_BASE_URL}/resource/${EXISTING_RESOURCE_ID}" \
          -d '{"applyRules": true}' > /dev/null
      fi

      if [ "${RULES_CHANGED}" = "true" ]; then
        echo "$(($(cat "${COUNTER_DIR}/updated") + 1))" > "${COUNTER_DIR}/updated"
      else
        echo "$(($(cat "${COUNTER_DIR}/skipped") + 1))" > "${COUNTER_DIR}/skipped"
      fi
    else
      # Need to reconcile - API doesn't support deleting individual targets
      # So we delete the entire resource and recreate it with correct target
      echo "    🗑️  Reconciling targets (found ${EXISTING_TARGET_COUNT}, expected 1)..."
      echo "    → Deleting entire resource to recreate with correct target"

      DELETE_RESPONSE=$(curl -s -X DELETE \
        -H "Authorization: Bearer ${API_KEY}" \
        "${API_BASE_URL}/resource/${EXISTING_RESOURCE_ID}")

      # Check if deletion was successful
      if [ -n "${DELETE_RESPONSE}" ] && echo "${DELETE_RESPONSE}" | jq -e '.success' > /dev/null 2>&1; then
        echo "    ✓ Deleted resource"
      else
        echo "    ✓ Resource deleted"
      fi

      # Clear the resource ID and set flag for recreation
      EXISTING_RESOURCE_ID=""
      NEEDS_RECONCILE=true

      # Reload resources after deletion
      PANGOLIN_RESOURCES=$(curl -s -H "Authorization: Bearer ${API_KEY}" "${API_BASE_URL}/org/${ORG_ID}/resources" | jq -r ".data.resources // []")
    fi
  fi

  # Create resource if it doesn't exist (either new or was deleted for reconciliation)
  if [ -z "${EXISTING_RESOURCE_ID}" ]; then
    # Create new resource
    if [ "${NEEDS_RECONCILE}" = "true" ]; then
      echo "    ➕ Recreating ${HOST} with correct target"
    else
      echo "    ➕ Creating ${HOST}"
    fi
    
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
      else
        # For protected services (auth: true), create egress CIDR rules
        PRIO=10
        for CIDR in ${EGRESS_CIDRS}; do
          RULE_RESPONSE=$(curl -s -X PUT \
            -H "Authorization: Bearer ${API_KEY}" \
            -H "Content-Type: application/json" \
            "${API_BASE_URL}/resource/${RESOURCE_ID}/rule" \
            -d "{
              \"action\": \"ACCEPT\",
              \"match\": \"CIDR\",
              \"value\": \"${CIDR}\",
              \"priority\": ${PRIO},
              \"enabled\": true
            }")

          if echo "${RULE_RESPONSE}" | jq -e '.success' > /dev/null 2>&1; then
            echo "    ✓ Egress CIDR rule created (${CIDR})"
          else
            echo "    ⚠️  Failed to create egress CIDR rule (${CIDR}): $(echo ${RULE_RESPONSE} | jq -r '.message // "unknown"')"
          fi
          PRIO=$((PRIO + 1))
        done

        # Enable applyRules on the resource
        curl -s -X POST \
          -H "Authorization: Bearer ${API_KEY}" \
          -H "Content-Type: application/json" \
          "${API_BASE_URL}/resource/${RESOURCE_ID}" \
          -d '{"applyRules": true}' > /dev/null
        echo "    ✓ applyRules enabled"
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
          \"method\": \"${EXPECTED_METHOD}\"
        }")
      
      if echo "${TARGET_RESPONSE}" | jq -e '.success' > /dev/null; then
        if [ "${NEEDS_RECONCILE}" = "true" ]; then
          echo "    ✓ Reconciled ${HOST} → ${TARGET_IP}:${TARGET_PORT}"
          echo "$(($(cat "${COUNTER_DIR}/updated") + 1))" > "${COUNTER_DIR}/updated"
        else
          echo "    ✓ Created ${HOST} → ${TARGET_IP}:${TARGET_PORT}"
          echo "$(($(cat "${COUNTER_DIR}/added") + 1))" > "${COUNTER_DIR}/added"
        fi
        # Reload resources after create
        PANGOLIN_RESOURCES=$(curl -s -H "Authorization: Bearer ${API_KEY}" "${API_BASE_URL}/org/${ORG_ID}/resources" | jq -r ".data.resources // []")
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
echo "0" > "${COUNTER_DIR}/removed"

echo "${PANGOLIN_RESOURCES}" | jq -rc 'if type == "array" then .[] else empty end' | while IFS= read -r resource; do
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
      echo "$(($(cat "${COUNTER_DIR}/removed") + 1))" > "${COUNTER_DIR}/removed"
    else
      echo "    ❌ Failed to remove: $(echo "${DELETE_RESPONSE}" | jq -r '.message // "Unknown error"')"
    fi
  fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "📊 Sync Summary"
echo "═══════════════════════════════════════════════════════"
SKIPPED=$(cat "${COUNTER_DIR}/skipped")
ADDED=$(cat "${COUNTER_DIR}/added")
UPDATED=$(cat "${COUNTER_DIR}/updated")
REMOVED=$(cat "${COUNTER_DIR}/removed")
echo "   ✓ Skipped (unchanged):  ${SKIPPED}"
echo "   ➕ Added:                ${ADDED}"
echo "   🔄 Updated:              ${UPDATED}"
echo "   ✗ Removed:              ${REMOVED}"
echo "═══════════════════════════════════════════════════════"
echo "✅ Pangolin sync complete!"
echo ""

# Cleanup temp directory
rm -rf "${COUNTER_DIR}"
