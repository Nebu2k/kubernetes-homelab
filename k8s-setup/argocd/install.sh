#!/bin/bash

# ArgoCD Installation Script
# This script installs ArgoCD using Helm

set -e

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi

# Set default ArgoCD domain if not specified
if [ -z "$CF_ARGOCD_DOMAIN" ]; then
    if [ -z "$CF_DOMAIN" ]; then
        echo "❌ Error: CF_DOMAIN must be set in .env file"
        exit 1
    fi
    CF_ARGOCD_DOMAIN="argocd.${CF_DOMAIN}"
    echo "ℹ️  Using default ArgoCD domain: ${CF_ARGOCD_DOMAIN}"
fi

# Export variables for envsubst
export CF_ARGOCD_DOMAIN
export CF_DOMAIN

echo "🚀 Installing ArgoCD..."

# Add ArgoCD Helm repository
echo "📦 Adding ArgoCD Helm repository..."
if ! helm repo list | grep -q "^argo"; then
    helm repo add argo https://argoproj.github.io/argo-helm
    echo "✅ ArgoCD repository added"
else
    echo "ℹ️  ArgoCD repository already exists"
fi
helm repo update

# Install ArgoCD
echo "⚙️  Installing ArgoCD..."
if [ "$FORCE_INSTALL" = "true" ]; then
    helm upgrade --install argocd argo/argo-cd \
      --namespace argocd \
      --create-namespace \
      --values k8s-setup/argocd/values.yaml \
      --wait
else
    helm install argocd argo/argo-cd \
      --namespace argocd \
      --create-namespace \
      --values k8s-setup/argocd/values.yaml \
      --wait
fi

echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Apply Ingress for ArgoCD
echo "🌐 Creating ArgoCD Ingress..."
envsubst < k8s-setup/argocd/ingress.yaml | kubectl apply -f -

# Create DNS record for ArgoCD
echo "🌐 Creating DNS record for ArgoCD..."
if [ -f "scripts/create-dns-record.sh" ]; then
    ./scripts/create-dns-record.sh argocd "$CF_DEFAULT_TARGET"
else
    echo "⚠️  DNS record script not found. Please create DNS record manually:"
    echo "   $CF_ARGOCD_DOMAIN -> $CF_DEFAULT_TARGET"
fi

# Get initial admin password
echo "🔑 Getting ArgoCD initial admin password..."
ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Verify installation
echo "✅ Verifying ArgoCD installation..."
kubectl get pods -n argocd
kubectl get ingress -n argocd

echo "🎉 ArgoCD installation completed successfully!"
echo ""
echo "📝 Access Information:"
echo "   URL: https://$CF_ARGOCD_DOMAIN"
echo "   Username: admin"
echo "   Password: $ADMIN_PASSWORD"
echo ""
echo "⚠️  IMPORTANT: Please change the admin password after first login!"
