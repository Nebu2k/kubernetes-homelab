#!/bin/bash

# Cert-Manager Installation Script
# This script installs Cert-Manager using Helm
#
# Required environment variables:
#   - CF_CERT_EMAIL: Email address for Let's Encrypt registration
#   - CLOUDFLARE_API_TOKEN: Cloudflare API token for DNS-01 challenges (optional)
#
# Example usage:
#   export CF_CERT_EMAIL="your-email@example.com"
#   export CLOUDFLARE_API_TOKEN="your-cloudflare-token"
#   ./install.sh

set -e

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi

echo "🚀 Installing Cert-Manager..."

# Add Cert-Manager Helm repository
echo "📦 Adding Cert-Manager Helm repository..."
if ! helm repo list | grep -q "^jetstack"; then
    helm repo add jetstack https://charts.jetstack.io
    echo "✅ Cert-Manager repository added"
else
    echo "ℹ️  Cert-Manager repository already exists"
fi
helm repo update

# Install Cert-Manager CRDs
echo "⚙️  Installing Cert-Manager CRDs..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.1/cert-manager.crds.yaml

# Install Cert-Manager
echo "⚙️  Installing Cert-Manager..."
if [ "$FORCE_INSTALL" = "true" ]; then
    helm upgrade --install cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --values k8s-setup/cert-manager/values.yaml \
      --wait
else
    helm install cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --values k8s-setup/cert-manager/values.yaml \
      --wait
fi

echo "⏳ Waiting for Cert-Manager to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s

# Create or update Cloudflare API Token secret if environment variable is set
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    if kubectl get secret cloudflare-api-token -n cert-manager &>/dev/null; then
        echo "� Updating existing Cloudflare API Token secret..."
        kubectl delete secret cloudflare-api-token -n cert-manager
        kubectl create secret generic cloudflare-api-token \
            --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
            --namespace cert-manager
        echo "✅ Cloudflare API Token secret updated successfully!"
    else
        echo "🔑 Creating Cloudflare API Token secret..."
        kubectl create secret generic cloudflare-api-token \
            --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
            --namespace cert-manager
        echo "✅ Cloudflare API Token secret created successfully!"
    fi
elif kubectl get secret cloudflare-api-token -n cert-manager &>/dev/null; then
    echo "ℹ️  Cloudflare API Token secret already exists (no update provided)"
else
    echo "⚠️  CLOUDFLARE_API_TOKEN environment variable not set."
    echo "   DNS-01 challenges will not work without this secret."
    echo "   You can create it manually later with:"
    echo "   kubectl create secret generic cloudflare-api-token --from-literal=api-token=YOUR_TOKEN --namespace cert-manager"
fi

# Apply ClusterIssuer for Let's Encrypt
echo "🔐 Creating Let's Encrypt ClusterIssuers..."
if [ -n "$CF_CERT_EMAIL" ]; then
    echo "📧 Using email: $CF_CERT_EMAIL for Let's Encrypt registration"
    envsubst < k8s-setup/cert-manager/cluster-issuer.yaml | kubectl apply -f -
else
    echo "⚠️  CF_CERT_EMAIL environment variable not set."
    echo "   Please set it to your email address for Let's Encrypt registration:"
    echo "   export CF_CERT_EMAIL=your-email@example.com"
    echo "   Then re-run this script."
    exit 1
fi

# Verify installation
echo "✅ Verifying Cert-Manager installation..."
kubectl get pods -n cert-manager
echo ""
echo "🔍 Checking ClusterIssuer status..."
kubectl get clusterissuer
echo ""
echo "⏳ Waiting for ClusterIssuers to be ready (this may take a moment)..."
sleep 10
kubectl describe clusterissuer letsencrypt-staging | grep -A 3 "Status:"
kubectl describe clusterissuer letsencrypt-prod | grep -A 3 "Status:"

echo "🎉 Cert-Manager installation completed successfully!"
echo ""
echo "📝 ClusterIssuers created:"
echo "   - letsencrypt-staging (for testing)"
echo "   - letsencrypt-prod (for production)"
echo ""
