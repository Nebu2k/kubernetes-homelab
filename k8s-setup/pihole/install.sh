#!/bin/bash

# PiHole Installation Script
# This script installs PiHole using kubectl

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

# Apply Ingress for PiHole
echo "🌐 Creating PiHole Ingress..."

# Validate that CF_PIHOLE_DOMAIN is set
if [ -z "$CF_PIHOLE_DOMAIN" ]; then
    echo "❌ Error: CF_PIHOLE_DOMAIN is not set. Please check your .env file."
    exit 1
fi

echo "ℹ️  Creating ingress for domain: ${CF_PIHOLE_DOMAIN}"
envsubst < k8s-setup/pihole/ingress.yaml | kubectl apply -f -

# Get LoadBalancer IP
echo "🌐 Getting LoadBalancer IP..."
EXTERNAL_IP=""
while [ -z $EXTERNAL_IP ]; do
    echo "⏳ Waiting for external IP..."
    EXTERNAL_IP=$(kubectl get svc pihole-dns-udp -n pihole --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    [ -z "$EXTERNAL_IP" ] && sleep 10
done

# Create DNS record for PiHole
echo "🌐 Creating DNS record for PiHole..."
if [ -f "scripts/create-dns-record.sh" ]; then
    ./scripts/create-dns-record.sh pihole "$CF_DEFAULT_TARGET"
else
    echo "⚠️  DNS record script not found. Please create DNS record manually:"
    echo "   $CF_PIHOLE_DOMAIN -> $CF_DEFAULT_TARGET"
fi

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
echo "   1. Visit https://$CF_PIHOLE_DOMAIN/admin"
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
