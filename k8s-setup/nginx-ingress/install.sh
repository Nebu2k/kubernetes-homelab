#!/bin/bash

# NGINX Ingress Controller Installation Script
# This script installs NGINX Ingress Controller using Helm

set -e

echo "🚀 Installing NGINX Ingress Controller..."

# Add NGINX Ingress Helm repository
echo "📦 Adding NGINX Ingress Helm repository..."
if ! helm repo list | grep -q "^ingress-nginx"; then
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    echo "✅ NGINX Ingress repository added"
else
    echo "ℹ️  NGINX Ingress repository already exists"
fi
helm repo update

# Create namespace first
echo "📁 Creating ingress-nginx namespace..."
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

# Apply custom headers ConfigMap before installation
echo "⚙️  Creating custom headers ConfigMap..."
kubectl apply -f k8s-setup/nginx-ingress/custom-headers.yaml

# Install NGINX Ingress Controller (with ConfigMap already in place)
echo "⚙️  Installing NGINX Ingress Controller..."
if [ "$FORCE_INSTALL" = "true" ]; then
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --namespace ingress-nginx \
      --values k8s-setup/nginx-ingress/values.yaml \
      --wait
else
    helm install ingress-nginx ingress-nginx/ingress-nginx \
      --namespace ingress-nginx \
      --values k8s-setup/nginx-ingress/values.yaml \
      --wait
fi

echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx --timeout=300s

# Verify installation
echo "✅ Verifying NGINX Ingress Controller installation..."
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Get the external IP
echo "🌐 Getting LoadBalancer IP..."
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "📝 LoadBalancer IP: $EXTERNAL_IP"

echo "🎉 NGINX Ingress Controller installation completed successfully!"
echo "📝 External IP should be: 192.168.2.254"
