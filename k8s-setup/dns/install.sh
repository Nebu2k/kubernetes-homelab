#!/bin/bash

# DNS Services Installation Script
# This script installs Blocky (DNS blocker) and Unbound (recursive DNS resolver) using Helm and Kubernetes manifests

set -e

echo "🚀 Installing Blocky and Unbound..."

# Add Blocky Helm repository
echo "📦 Adding Blocky Helm repository..."
if ! helm repo list | grep -q "^blocky"; then
    helm repo add blocky https://0xerr0r.github.io/blocky
    echo "✅ Blocky repository added"
else
    echo "ℹ️ Blocky repository already exists"
fi
helm repo update

# Create namespace first
echo "📁 Creating dns namespace..."
kubectl create namespace dns --dry-run=client -o yaml | kubectl apply -f -

# Install Blocky
echo "⚙️  Installing Blocky..."
if [ "$FORCE_INSTALL" = "true" ]; then
    helm upgrade --install blocky blocky/blocky \
      --namespace dns \
      --values k8s-setup/dns/blocky.yaml \
      --wait
else
    helm install blocky blocky/blocky \
      --namespace dns \
      --values k8s-setup/dns/blocky.yaml \
      --wait
fi

# Install Unbound
echo "⚙️  Installing Unbound..."
kubectl apply -f k8s-setup/dns/unbound.yaml

echo "⏳ Waiting for Blocky to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=blocky -n dns --timeout=300s

echo "⏳ Waiting for Unbound to be ready..."
kubectl wait --for=condition=ready pod -l app=unbound -n dns --timeout=300s

# Verify installation
echo "✅ Verifying DNS services installation..."
kubectl get pods -n dns
kubectl get svc -n dns

# Get the external IP
echo "🌐 Getting LoadBalancer IP..."
EXTERNAL_IP=$(kubectl get svc blocky -n dns -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "📝 Blocky LoadBalancer IP: $EXTERNAL_IP"

# Test DNS resolution
echo "🧪 Testing DNS resolution..."
if [ ! -z "$EXTERNAL_IP" ]; then
    echo "Testing DNS query to Blocky..."
    nslookup google.com $EXTERNAL_IP || echo "⚠️  DNS test failed - service might still be starting"
fi

echo "🎉 Blocky and Unbound installation completed successfully!"
echo "📝 Blocky should be available at: 192.168.2.250"
echo "📝 HTTP interface available at: http://192.168.2.250:4000"
