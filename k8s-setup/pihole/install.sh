#!/bin/bash

# PiHole with Unbound Installation Script
# This script installs PiHole with Unbound using Helm

set -e

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi

# Set default PiHole domain if not specified (for web interface access)
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

echo "🚀 Installing PiHole with Unbound..."

# Add PiHole Helm repository
echo "📦 Adding PiHole Helm repository..."
if ! helm repo list | grep -q "^pihole"; then
    helm repo add pihole https://mojo2600.github.io/pihole-kubernetes/
    echo "✅ PiHole repository added"
else
    echo "ℹ️  PiHole repository already exists"
fi
helm repo update

# Create namespace
echo "📋 Creating pihole namespace..."
kubectl create namespace pihole --dry-run=client -o yaml | kubectl apply -f -

# Generate random admin password if not set
if [ -z "$PIHOLE_ADMIN_PASSWORD" ]; then
    PIHOLE_ADMIN_PASSWORD=$(openssl rand -base64 16)
    echo "🔐 Generated PiHole admin password: ${PIHOLE_ADMIN_PASSWORD}"
    echo "⚠️  Please save this password! It will be needed to access the web interface."
fi

# Create admin password secret
echo "🔐 Creating PiHole admin password secret..."
kubectl create secret generic pihole-admin-password \
    --from-literal=password="$PIHOLE_ADMIN_PASSWORD" \
    --namespace pihole \
    --dry-run=client -o yaml | kubectl apply -f -

# Install PiHole with Unbound
echo "⚙️  Installing PiHole with Unbound..."
if [ "$FORCE_INSTALL" = "true" ]; then
    helm upgrade --install pihole pihole/pihole \
      --namespace pihole \
      --values k8s-setup/pihole/values.yaml \
      --wait
else
    helm install pihole pihole/pihole \
      --namespace pihole \
      --values k8s-setup/pihole/values.yaml \
      --wait
fi

echo "⏳ Waiting for PiHole to be ready..."
kubectl wait --for=condition=ready pod -l app=pihole -n pihole --timeout=300s

# Apply LoadBalancer services for PiHole
echo "🌐 Creating PiHole LoadBalancer services..."
kubectl apply -f k8s-setup/pihole/loadbalancer.yaml

# Create DNS record for PiHole web interface (optional, only if ingress is later needed)
if [ -n "$CF_DEFAULT_TARGET" ]; then
    echo "🌐 Creating DNS record for PiHole web interface..."
    if [ -f "scripts/create-dns-record.sh" ]; then
        ./scripts/create-dns-record.sh pihole "$CF_DEFAULT_TARGET"
    else
        echo "⚠️  DNS record script not found. DNS record for web interface can be created manually if needed:"
        echo "   $CF_PIHOLE_DOMAIN -> $CF_DEFAULT_TARGET"
    fi
fi

# Verify installation
echo "✅ Verifying PiHole installation..."
kubectl get pods -n pihole
kubectl get svc -n pihole

# Get access information
PIHOLE_IP="192.168.2.250"

echo ""
echo "🎉 PiHole with Unbound installation completed successfully!"
echo ""
echo "📝 Access Information:"
echo "   DNS Server: ${PIHOLE_IP}:5353 (Test port - avoids conflicts with existing PiHole)"
echo "   Web Interface: http://${PIHOLE_IP}/admin"
echo "   Admin Password: ${PIHOLE_ADMIN_PASSWORD}"
echo ""
echo "🔧 Configuration:"
echo "   • Unbound is configured as the upstream DNS resolver"
echo "   • DNS is running on port 5353 for testing (change to 53 when ready)"
echo "   • Web interface is accessible via LoadBalancer IP"
echo "   • LoadBalancer IP: ${PIHOLE_IP}"
echo ""
echo "🧪 Testing:"
echo "   Test DNS resolution: nslookup google.com ${PIHOLE_IP} -port=5353"
echo "   Test ad blocking: nslookup doubleclick.net ${PIHOLE_IP} -port=5353"
echo "   Alternative: dig @${PIHOLE_IP} -p 5353 google.com"
echo ""
echo "⚙️  Next Steps:"
echo "   1. Test the DNS functionality with commands above"
echo "   2. When ready to go live, stop your existing Docker PiHole"
echo "   3. Update values.yaml and loadbalancer.yaml to use port 53"
echo "   4. Redeploy with standard DNS port 53"
echo ""
