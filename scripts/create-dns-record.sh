#!/bin/bash

# Cloudflare DNS CNAME Record Management Script
# Creates CNAME records in Cloudflare using the API

set -e

# Function to display usage
usage() {
    cat << 'USAGE'
Usage: ./create-dns-record.sh <subdomain> <domain> <target> <zone-id> <api-token>

Creates a CNAME record for <subdomain>.<domain> pointing to <target>

Parameters:
  subdomain    The subdomain to create (e.g., 'argocd', 'portainer')
  domain       Your Cloudflare domain (e.g., 'example.com')
  target       CNAME target (e.g., 'myserver.dyndns.org')
  zone-id      Your Cloudflare Zone ID
  api-token    Your Cloudflare API token

Examples:
  ./create-dns-record.sh argocd example.com myserver.dyndns.org <zone-id> <api-token>
  ./create-dns-record.sh portainer example.com 192.168.1.10 <zone-id> <api-token>

Note:
  Get your Zone ID and API token from Cloudflare dashboard:
  - Zone ID: Dashboard > Select Domain > Overview (right sidebar)
  - API Token: Dashboard > My Profile > API Tokens > Create Token
USAGE
    exit 1
}

# Check parameters
if [ $# -ne 5 ]; then
    echo "❌ Error: Exactly 5 parameters required"
    echo ""
    usage
fi

SUBDOMAIN="$1"
DOMAIN="$2"
TARGET="$3"
ZONE_ID="$4"
API_TOKEN="$5"

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
