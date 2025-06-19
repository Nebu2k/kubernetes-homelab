#!/bin/bash

# MetalLB Installation Script
# This script installs MetalLB using Helm

set -e

echo "🚀 Installing MetalLB..."

# Add MetalLB Helm repository
echo "📦 Adding MetalLB Helm repository..."
if ! helm repo list | grep -q "^metallb"; then
    helm repo add metallb https://metallb.github.io/metallb
    echo "✅ MetalLB repository added"
else
    echo "ℹ️  MetalLB repository already exists"
fi
helm repo update

# Create namespace and install MetalLB
echo "⚙️  Installing MetalLB..."
if [ "$FORCE_INSTALL" = "true" ]; then
    helm upgrade --install metallb metallb/metallb \
      --namespace metallb-system \
      --create-namespace \
      --values k8s-setup/metallb/values.yaml \
      --wait
else
    helm install metallb metallb/metallb \
      --namespace metallb-system \
      --create-namespace \
      --values k8s-setup/metallb/values.yaml \
      --wait
fi

echo "⏳ Waiting for MetalLB to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=metallb -n metallb-system --timeout=300s

# Apply IP address pool configuration
echo "🌐 Configuring IP address pool..."
kubectl apply -f k8s-setup/metallb/ip-pool.yaml

# Verify installation
echo "✅ Verifying MetalLB installation..."
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system
kubectl get l2advertisements -n metallb-system

echo "🎉 MetalLB installation completed successfully!"
echo "📝 IP Pool configured: 192.168.2.254/32"
