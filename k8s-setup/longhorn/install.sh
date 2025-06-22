#!/bin/bash

# Longhorn Installation Script
# This script installs Longhorn v1.9.0 distributed storage for HA

set -e

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi

# Set default Longhorn domain if not specified
if [ -z "$CF_LONGHORN_DOMAIN" ]; then
    if [ -z "$CF_DOMAIN" ]; then
        echo "❌ Error: CF_DOMAIN must be set in .env file"
        exit 1
    fi
    CF_LONGHORN_DOMAIN="longhorn.${CF_DOMAIN}"
    echo "ℹ️  Using default Longhorn domain: ${CF_LONGHORN_DOMAIN}"
fi

# Export variables for envsubst
export CF_LONGHORN_DOMAIN
export CF_DOMAIN

echo "🚀 Installing Longhorn Storage v1.9.0..."
echo "📦 Domain: $CF_LONGHORN_DOMAIN"
echo "⚠️  Note: Using hotfix version for longhorn-manager to fix recurring jobs"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Error: helm is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Unable to connect to Kubernetes cluster"
    exit 1
fi

# Pre-installation checks
echo "🔍 Running pre-installation checks..."

# Check node requirements
echo "📋 Checking node requirements..."
kubectl get nodes -o wide

# Check for iscsi and nfs-common on nodes
echo "📋 Checking required packages on nodes..."
echo "ℹ️  Longhorn v1.9.0 requires iscsi-initiator-utils and nfs-common on all nodes"
echo "ℹ️  Run this on each node if not installed:"
echo "   sudo apt update && sudo apt install -y open-iscsi nfs-common"
echo ""
echo "📋 Kubernetes Version Requirements:"
echo "ℹ️  Longhorn v1.9.0 requires Kubernetes v1.25 or later"
KUBE_VERSION=$(kubectl version --short --client=false | head -n1 | awk '{print $3}')
echo "ℹ️  Current cluster version: $KUBE_VERSION"

# Add Longhorn Helm repository
echo "📦 Adding Longhorn Helm repository..."
if ! helm repo list | grep -q "^longhorn"; then
    helm repo add longhorn https://charts.longhorn.io
    echo "✅ Longhorn repository added"
else
    echo "ℹ️  Longhorn repository already exists"
fi
helm repo update

# Create namespace
echo "📋 Creating longhorn-system namespace..."
kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f -

# Install Longhorn
echo "⚙️  Installing Longhorn..."
if [ "$FORCE_INSTALL" = "true" ]; then
    helm upgrade --install longhorn longhorn/longhorn \
      --namespace longhorn-system \
      --values k8s-setup/longhorn/values.yaml \
      --wait \
      --timeout=600s
else
    helm install longhorn longhorn/longhorn \
      --namespace longhorn-system \
      --values k8s-setup/longhorn/values.yaml \
      --wait \
      --timeout=600s
fi

echo "⏳ Waiting for Longhorn to be ready..."
kubectl wait --for=condition=ready pod -l app=longhorn-manager -n longhorn-system --timeout=300s

# Create NodePort Service for Longhorn UI
echo "🌐 Creating NodePort Service for Longhorn UI..."
kubectl apply -f k8s-setup/longhorn/nodeport.yaml

echo "ℹ️  Longhorn UI available at:"
echo "ℹ️  http://<any-node-ip>:30080"
echo "ℹ️  Example: http://192.168.2.7:30080"

# Create optimized StorageClasses
echo "📋 Creating optimized StorageClasses..."
kubectl apply -f k8s-setup/longhorn/storage-classes.yaml

# Set Longhorn as default StorageClass and remove default from local-path
echo "🔧 Configuring default StorageClass..."
kubectl annotate storageclass longhorn storageclass.kubernetes.io/is-default-class=true --overwrite
kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class=false --overwrite || true

# Verify installation
echo "✅ Verifying Longhorn installation..."
kubectl get pods -n longhorn-system
kubectl get storageclass
echo ""
echo "📊 Longhorn Node Status:"
kubectl get nodes.longhorn.io -n longhorn-system

echo ""
echo "🎉 Longhorn v1.9.0 installation completed successfully!"
echo ""
echo "📝 Access Information:"
echo "   Longhorn UI: https://$CF_LONGHORN_DOMAIN"
echo "   Default StorageClass: longhorn (3 replicas)"
echo "   Fast StorageClass: longhorn-fast (1 replica)"
echo "   HA StorageClass: longhorn-ha (3 replicas, strict anti-affinity)"
echo ""
echo "🆕 New Features in v1.9.0:"
echo "   ✨ Offline replica rebuilding enabled"
echo "   ✨ Orphaned instance auto-deletion enabled"
echo "   ✨ Recurring system backup support"
echo "   ✨ Enhanced V2 Data Engine (experimental)"
echo "   ✨ Improved observability with new metrics"
echo ""
echo "📋 Storage Classes Available:"
echo "   - longhorn (default): 3 replicas, balanced performance/reliability"
echo "   - longhorn-fast: 1 replica, maximum performance"
echo "   - longhorn-ha: 3 replicas, strict node anti-affinity"
echo "   - local-path: K3s default (single node, not HA)"
echo ""
echo "🔧 Next Steps:"
echo "   1. Update existing services to use Longhorn storage"
echo "   2. Migrate data from local-path volumes (see migration guide)"
echo "   3. Monitor storage health via Longhorn UI"
echo "   4. Configure backup targets if needed"
echo "   5. Set up recurring system backups"
echo ""
echo "⚠️  Migration Required:"
echo "   Existing PVCs with local-path storage need manual migration!"
echo "   See: k8s-setup/longhorn/MIGRATION.md"
echo ""
echo "⚠️  Version Note:"
echo "   Using longhorn-manager:v1.9.0-hotfix-1 to fix recurring jobs regression"
echo "   This is recommended by the Longhorn team for production use"
