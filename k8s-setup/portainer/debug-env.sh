#!/bin/bash

# Debug script to check environment variables
# Run this to verify your .env file is properly configured

set -e

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    echo "✅ Found .env file at: $ROOT_DIR/.env"
    set -a
    source "$ROOT_DIR/.env"
    set +a
else
    echo "❌ No .env file found at: $ROOT_DIR/.env"
    exit 1
fi

echo ""
echo "🔍 Environment Variables Check:"
echo "================================"

# Check required variables
echo "CF_DOMAIN: ${CF_DOMAIN:-'❌ NOT SET'}"
echo "CF_ARGOCD_DOMAIN: ${CF_ARGOCD_DOMAIN:-'❌ NOT SET'}"
echo "CF_PORTAINER_DOMAIN: ${CF_PORTAINER_DOMAIN:-'❌ NOT SET (will default to portainer.${CF_DOMAIN})'}"

# Set default Portainer domain if not specified
if [ -z "$CF_PORTAINER_DOMAIN" ]; then
    if [ -n "$CF_DOMAIN" ]; then
        CF_PORTAINER_DOMAIN="portainer.${CF_DOMAIN}"
        echo "ℹ️  Default Portainer domain will be: ${CF_PORTAINER_DOMAIN}"
    else
        echo "❌ Cannot set default Portainer domain - CF_DOMAIN is not set"
    fi
fi

# Export variables for envsubst
export CF_PORTAINER_DOMAIN
export CF_DOMAIN

echo ""
echo "🧪 Testing environment variable substitution:"
echo "=============================================="

# Test envsubst with a simple template
echo "Testing with CF_PORTAINER_DOMAIN = '${CF_PORTAINER_DOMAIN}'"
echo "Template: \${CF_PORTAINER_DOMAIN}"
echo "Result: $(echo '${CF_PORTAINER_DOMAIN}' | envsubst)"

echo ""
if [ -n "$CF_PORTAINER_DOMAIN" ] && [ "$CF_PORTAINER_DOMAIN" != "" ]; then
    echo "✅ CF_PORTAINER_DOMAIN is properly set and ready for use"
else
    echo "❌ CF_PORTAINER_DOMAIN is empty or not set"
    echo "   Please check your .env file and ensure CF_DOMAIN is set"
fi
