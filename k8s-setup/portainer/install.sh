#!/bin/bash

# Portainer Installation Script
# This script installs Portainer using Helm

set -e

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi

# Set default Portainer domain if not specified
if [ -z "$CF_PORTAINER_DOMAIN" ]; then
    if [ -z "$CF_DOMAIN" ]; then
        echo "❌ Error: CF_DOMAIN must be set in .env file"
        exit 1
    fi
    CF_PORTAINER_DOMAIN="portainer.${CF_DOMAIN}"
    echo "ℹ️  Using default Portainer domain: ${CF_PORTAINER_DOMAIN}"
fi

# Export variables for envsubst
export CF_PORTAINER_DOMAIN
export CF_DOMAIN

echo "🚀 Installing Portainer..."

# Add Portainer Helm repository
echo "📦 Adding Portainer Helm repository..."
if ! helm repo list | grep -q "^portainer"; then
    helm repo add portainer https://portainer.github.io/k8s/
    echo "✅ Portainer repository added"
else
    echo "ℹ️  Portainer repository already exists"
fi
helm repo update

# Create namespace
echo "📋 Creating portainer namespace..."
kubectl create namespace portainer --dry-run=client -o yaml | kubectl apply -f -

# Install Portainer
echo "⚙️  Installing Portainer..."
if [ "$FORCE_INSTALL" = "true" ]; then
    helm upgrade --install portainer portainer/portainer \
      --namespace portainer \
      --values k8s-setup/portainer/values.yaml \
      --wait
else
    helm install portainer portainer/portainer \
      --namespace portainer \
      --values k8s-setup/portainer/values.yaml \
      --wait
fi

echo "⏳ Waiting for Portainer to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=portainer -n portainer --timeout=300s

# Apply Ingress for Portainer
echo "🌐 Creating Portainer Ingress..."

# Validate that CF_PORTAINER_DOMAIN is set
if [ -z "$CF_PORTAINER_DOMAIN" ]; then
    echo "❌ Error: CF_PORTAINER_DOMAIN is not set. Please check your .env file."
    exit 1
fi

echo "ℹ️  Creating ingress for domain: ${CF_PORTAINER_DOMAIN}"
envsubst < k8s-setup/portainer/ingress.yaml | kubectl apply -f -

# Create DNS record for Portainer
echo "🌐 Creating DNS record for Portainer..."
if [ -f "scripts/create-dns-record.sh" ]; then
    ./scripts/create-dns-record.sh portainer "$CF_DEFAULT_TARGET"
else
    echo "⚠️  DNS record script not found. Please create DNS record manually:"
    echo "   $CF_PORTAINER_DOMAIN -> $CF_DEFAULT_TARGET"
fi

# Verify installation
echo "✅ Verifying Portainer installation..."
kubectl get pods -n portainer
kubectl get ingress -n portainer

# Get the initial admin password
echo ""
echo "🎉 Portainer installation completed successfully!"
echo ""
echo "📝 Access Information:"
echo "   URL: https://$CF_PORTAINER_DOMAIN"
echo "   Initial Setup: Create admin user within 5 minutes"
echo ""
echo "⚠️  IMPORTANT: Complete the initial setup within 5 minutes or the setup will timeout!"
echo ""
