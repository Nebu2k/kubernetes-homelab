#!/bin/bash

# Cloudflare DNS CNAME Record Management Script
# This script creates CNAME records in Cloudflare using the API

set -e

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi


# Function to display usage
usage() {
    echo "Usage: $0 <subdomain> [target]"
    echo ""
    echo "Creates a CNAME record for <subdomain>.$CF_DOMAIN"
    echo ""
    echo "Parameters:"
    echo "  subdomain    The subdomain to create (e.g., 'argocd', 'grafana', 'test')"
    echo "  target       Optional. CNAME target (default: $CF_DEFAULT_TARGET)"
    echo ""
    echo "Examples:"
    echo "  $0 argocd                    # Creates argocd.$CF_DOMAIN -> $CF_DEFAULT_TARGET"
    echo "  $0 grafana                   # Creates grafana.$CF_DOMAIN -> $CF_DEFAULT_TARGET"
    echo "  $0 test custom.example.com   # Creates test.$CF_DOMAIN -> custom.example.com"
    echo ""
    echo "Prerequisites:"
    echo "  - Cloudflare API token secret must exist in cert-manager namespace"
    echo "  - kubectl must be configured and working"
    exit 1
}

# Check parameters
if [ -z "$1" ]; then
    echo "❌ Error: Subdomain is required"
    usage
fi

SUBDOMAIN="$1"
if [ -n "$2" ]; then
    TARGET="$2"
else
    TARGET="$CF_DEFAULT_TARGET"
fi

RECORD_NAME="${SUBDOMAIN}.${CF_DOMAIN}"

echo "🌐 Creating CNAME record: $RECORD_NAME -> $TARGET"

# Get API token from environment variable or Kubernetes secret
echo "🔑 Retrieving Cloudflare API token..."
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    echo "ℹ️  Using API token from environment variable"
    API_TOKEN="$CLOUDFLARE_API_TOKEN"
else
    echo "ℹ️  Retrieving API token from Kubernetes secret..."
    if ! kubectl get namespace cert-manager &>/dev/null; then
        echo "❌ Error: cert-manager namespace not found and CLOUDFLARE_API_TOKEN not set"
        echo "Either set CLOUDFLARE_API_TOKEN environment variable or install cert-manager first"
        exit 1
    fi
    
    API_TOKEN=$(kubectl get secret cloudflare-api-token -n cert-manager -o jsonpath='{.data.api-token}' 2>/dev/null | base64 -d)
    if [ -z "$API_TOKEN" ]; then
        echo "❌ Error: Could not retrieve Cloudflare API token from secret"
        echo "Make sure the secret 'cloudflare-api-token' exists in the cert-manager namespace"
        echo "Or set CLOUDFLARE_API_TOKEN environment variable"
        exit 1
    fi
fi

# Check if record already exists
echo "🔍 Checking if DNS record already exists..."
EXISTING_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?name=$RECORD_NAME" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id // empty')

if [ -n "$EXISTING_RECORD" ]; then
    echo "🔄 DNS record already exists, updating..."
    RESULT=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$EXISTING_RECORD" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"CNAME\",\"name\":\"$RECORD_NAME\",\"content\":\"$TARGET\",\"ttl\":1,\"proxied\":true}")
else
    echo "➕ Creating new DNS record..."
    RESULT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"CNAME\",\"name\":\"$RECORD_NAME\",\"content\":\"$TARGET\",\"ttl\":1,\"proxied\":true}")
fi

# Check if request was successful
SUCCESS=$(echo "$RESULT" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
    echo "✅ DNS record created/updated successfully!"
    echo "📝 $RECORD_NAME -> $TARGET"
    echo ""
    echo "Note: DNS propagation may take a few minutes."
else
    echo "❌ Error creating DNS record:"
    echo "$RESULT" | jq -r '.errors[].message'
    exit 1
fi
