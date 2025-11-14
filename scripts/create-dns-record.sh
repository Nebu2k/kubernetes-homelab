#!/bin/bash

# Cloudflare DNS CNAME Record Management Script
# Creates CNAME records in Cloudflare using the API

set -e

# Load .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    echo "📄 Loading configuration from .env file..."
    # Export variables from .env
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "❌ Error: .env file not found at $ENV_FILE"
    echo "Please create a .env file from .env.example"
    exit 1
fi

# Function to display usage
usage() {
    cat << 'USAGE'
Usage: ./create-dns-record.sh <subdomain>

Creates a CNAME record for <subdomain>.<DOMAIN> pointing to <TARGET>
Uses configuration from .env file in the homelab directory.

Parameters:
  subdomain    The subdomain to create (e.g., 'argocd', 'portainer')

Examples:
  ./create-dns-record.sh argocd
  ./create-dns-record.sh portainer

Configuration:
  Edit the .env file in the homelab directory to set:
  - DOMAIN          Your Cloudflare domain (e.g., 'example.com')
  - TARGET          CNAME target (e.g., 'myserver.dyndns.org' or IP)
  - ZONE_ID         Your Cloudflare Zone ID
  - API_TOKEN       Your Cloudflare API token

Note:
  Get your Zone ID and API token from Cloudflare dashboard:
  - Zone ID: Dashboard > Select Domain > Overview (right sidebar)
  - API Token: Dashboard > My Profile > API Tokens > Create Token
USAGE
    exit 1
}

# Check parameters
if [ $# -ne 1 ]; then
    echo "❌ Error: Exactly 1 parameter required"
    echo ""
    usage
fi

SUBDOMAIN="$1"

# Validate required environment variables
if [ -z "$DOMAIN" ] || [ -z "$TARGET" ] || [ -z "$ZONE_ID" ] || [ -z "$API_TOKEN" ]; then
    echo "❌ Error: Missing required environment variables in .env file"
    echo "Required: DOMAIN, TARGET, ZONE_ID, API_TOKEN"
    exit 1
fi

RECORD_NAME="${SUBDOMAIN}.${DOMAIN}"

echo "🌐 Creating CNAME record: $RECORD_NAME -> $TARGET"

# Check if record already exists
echo "🔍 Checking if DNS record already exists..."
EXISTING_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id // empty')

if [ -n "$EXISTING_RECORD" ]; then
    echo "🔄 DNS record already exists, updating..."
    RESULT=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$EXISTING_RECORD" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"CNAME\",\"name\":\"$RECORD_NAME\",\"content\":\"$TARGET\",\"ttl\":1,\"proxied\":true}")
else
    echo "➕ Creating new DNS record..."
    RESULT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
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
