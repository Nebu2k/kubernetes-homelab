#!/bin/bash

# Cloudflare ACME Challenge Cleanup Script
# Deletes old _acme-challenge TXT records

set -e

# Load .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    echo "📄 Loading configuration from .env file..."
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "❌ Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Validate required environment variables
if [ -z "$DOMAIN" ] || [ -z "$ZONE_ID" ] || [ -z "$API_TOKEN" ]; then
    echo "❌ Error: Missing required environment variables in .env file"
    echo "Required: DOMAIN, ZONE_ID, API_TOKEN"
    exit 1
fi

echo "🔍 Looking for _acme-challenge TXT records in $DOMAIN..."

# Get all TXT records containing _acme-challenge
RECORDS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=TXT" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json")

# Check if request was successful
SUCCESS=$(echo "$RECORDS" | jq -r '.success')
if [ "$SUCCESS" != "true" ]; then
    echo "❌ Error fetching DNS records:"
    echo "$RECORDS" | jq -r '.errors[].message'
    exit 1
fi

# Filter for _acme-challenge records
ACME_RECORDS=$(echo "$RECORDS" | jq -r '.result[] | select(.name | contains("_acme-challenge")) | "\(.id)|\(.name)"')

if [ -z "$ACME_RECORDS" ]; then
    echo "✅ No _acme-challenge records found. All clean!"
    exit 0
fi

echo "🗑️  Found $(echo "$ACME_RECORDS" | wc -l | xargs) _acme-challenge records to delete:"
echo ""

# Delete each record
DELETED=0
FAILED=0

while IFS='|' read -r RECORD_ID RECORD_NAME; do
    echo "   Deleting: $RECORD_NAME"
    
    RESULT=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")
    
    DELETE_SUCCESS=$(echo "$RESULT" | jq -r '.success')
    if [ "$DELETE_SUCCESS" = "true" ]; then
        ((DELETED++))
    else
        echo "      ❌ Failed: $(echo "$RESULT" | jq -r '.errors[].message')"
        ((FAILED++))
    fi
done <<< "$ACME_RECORDS"

echo ""
echo "✅ Cleanup complete!"
echo "   Deleted: $DELETED"
if [ $FAILED -gt 0 ]; then
    echo "   Failed:  $FAILED"
fi
