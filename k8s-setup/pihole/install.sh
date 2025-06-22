#!/bin/bash

# PiHole Installation Script
# This script installs PiHole uskubectl get svc -n pihole

echo ""
echo "🎉 PiHole installation completed successfully!"
echo ""
echo "📝 Access Information:"
echo "   Web Interface: http://<node-ip>:30081 (z.B. http://192.168.2.7:30081)"
echo "   DNS Server IP: $EXTERNAL_IP"
echo "   Default Password: admin123 (change this!)"
echo "   Internal Access Only: No external domain required"tl

set -e

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi

# Set default PiHole domain if not specified
if [ -z "$CF_PIHOLE_DOMAIN" ]; then
    if [ -z "$CF_DOMAIN" ]; then
        echo "❌ Error: CF_DOMAIN must be set in .env file"
        exit 1
    fi
    CF_PIHOLE_DOMAIN="pihole.${CF_DOMAIN}"
    echo "ℹ️  Using default PiHole domain: ${CF_PIHOLE_DOMAIN}"
fi

# Export variables for envsubst
export CF_PIHOLE_DOMAIN
export CF_DOMAIN

echo "🔧 Installing PiHole..."
echo "📦 Domain: $CF_PIHOLE_DOMAIN"

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

# Apply manifests with environment variable substitution
echo "📋 Applying PiHole manifests..."

# Apply the main PiHole manifest
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
kubectl get ingress -n pihole

echo ""
echo "🎉 PiHole installation completed successfully!"
echo ""
echo "� Access Information:"
echo "   Web Interface: https://$CF_PIHOLE_DOMAIN"
echo "   DNS Server IP: $EXTERNAL_IP"
echo "   Default Password: admin123 (change this!)"
echo ""
echo "📋 DNS Configuration:"
echo "   Configure your router or devices to use $EXTERNAL_IP as DNS server"
echo ""
echo "🔧 Post-Installation Steps:"
echo "   1. Visit http://<any-node-ip>:30081/admin"
echo "   2. Login with password: admin123"
echo "   3. Change the admin password immediately!"
echo "   4. Import your existing configuration (see migration guide)"
echo ""
echo "📝 VLAN Configuration:"
echo "   All VLANs (192.168.2.0/24, 192.168.4.0/24, 192.168.5.0/24) can use:"
echo "   - DNS Server: $EXTERNAL_IP"
echo "   - Domain: elmstreet79.de"
echo ""
echo "📝 Migration Commands (run after installation):"
echo "   POD_NAME=\$(kubectl get pod -n pihole -l app=pihole -o jsonpath='{.items[0].metadata.name}')"
echo "   kubectl cp /data/pihole/etc-pihole/ pihole/\$POD_NAME:/etc/pihole/"
echo "   kubectl cp /data/pihole/etc-dnsmasq.d/ pihole/\$POD_NAME:/etc/dnsmasq.d/"
echo "   kubectl rollout restart deployment/pihole -n pihole"
echo ""
