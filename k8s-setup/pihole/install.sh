#!/bin/bash

# PiHole Installation Script
# This script installs PiHole using Kubernetes manifests

set -e

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi

echo "🔧 Installing PiHole..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Unable to connect to Kubernetes cluster"
    exit 1
fi

# Apply manifests
echo "📋 Applying PiHole manifests..."
kubectl apply -f k8s-setup/pihole/pihole.yaml

echo "⏳ Waiting for PiHole to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/pihole -n pihole

# Get LoadBalancer IP for DNS service
echo "🌐 Getting LoadBalancer IP..."
EXTERNAL_IP=""
while [ -z $EXTERNAL_IP ]; do
    echo "⏳ Waiting for external IP..."
    EXTERNAL_IP=$(kubectl get svc pihole-dns -n pihole --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    [ -z "$EXTERNAL_IP" ] && sleep 10
done

echo "ℹ️  PiHole DNS service available at: $EXTERNAL_IP"
echo "ℹ️  Web interface configured for internal access only (NodePort)"

# Verify installation
echo "✅ Verifying PiHole installation..."
kubectl get pods -n pihole
kubectl get svc -n pihole

echo ""
echo "🎉 PiHole installation completed successfully!"
echo ""
echo "📝 Access Information:"
echo "   Web Interface: http://<node-ip>:30081/admin (z.B. http://192.168.2.7:30081/admin)"
echo "   DNS Server IP: $EXTERNAL_IP"
echo "   ⚠️  PASSWORD SETUP REQUIRED - No default password set!"
echo "   Internal Access Only: No external domain required"
echo ""
echo "🔐 IMPORTANT: Set Admin Password After Installation!"
echo "   1. Find the pod: kubectl get pods -n pihole"
echo "   2. Set password: kubectl exec -n pihole <POD_NAME> -it -- pihole setpassword"
echo "   3. Or use: kubectl exec -n pihole <POD_NAME> -- pihole setpassword 'YourPassword'"
echo ""
echo "📋 DNS Configuration:"
echo "   Configure your router or devices to use $EXTERNAL_IP as DNS server"
echo ""
echo "🔧 Post-Installation Steps:"
echo "   1. Set admin password using commands above"
echo "   2. Visit http://<any-node-ip>:30081/admin"
echo "   3. Login with your new password"
echo "   4. Import your existing configuration (see migration guide)"
echo ""
echo "📝 VLAN Configuration:"
echo "   All VLANs (192.168.2.0/24, 192.168.4.0/24, 192.168.5.0/24) can use:"
echo "   - DNS Server: $EXTERNAL_IP"
echo "   - Domain: elmstreet79.de"
echo ""
