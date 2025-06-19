#!/bin/bash

# Cert-Manager Installation Script
# This script installs Cert-Manager using Helm

set -e

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

# Create Cloudflare API Token secret if environment variable is set
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    echo "🔑 Creating Cloudflare API Token secret..."
    kubectl create secret generic cloudflare-api-token \
        --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
        --namespace cert-manager \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ Cloudflare API Token secret created successfully!"
elif kubectl get secret cloudflare-api-token -n cert-manager &>/dev/null; then
    echo "ℹ️  Cloudflare API Token secret already exists"
else
    echo "⚠️  CLOUDFLARE_API_TOKEN environment variable not set."
    echo "   DNS-01 challenges will not work without this secret."
    echo "   You can create it manually later with:"
    echo "   kubectl create secret generic cloudflare-api-token --from-literal=api-token=YOUR_TOKEN --namespace cert-manager"
fi

# Apply ClusterIssuer for Let's Encrypt
echo "🔐 Creating Let's Encrypt ClusterIssuers..."
kubectl apply -f k8s-setup/cert-manager/cluster-issuer.yaml

# Verify installation
echo "✅ Verifying Cert-Manager installation..."
kubectl get pods -n cert-manager
kubectl get clusterissuer

echo "🎉 Cert-Manager installation completed successfully!"
echo ""
echo "📝 ClusterIssuers created:"
echo "   - letsencrypt-staging (for testing)"
echo "   - letsencrypt-prod (for production)"
echo ""
