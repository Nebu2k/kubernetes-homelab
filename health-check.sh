#!/bin/bash

# Homelab K3s Stack Health Check Script
# This script performs comprehensive health checks on all stack components

set -e

echo "🏥 Homelab K3s Stack Health Check"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✅ SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi

# Check kubectl connectivity
print_info "Checking cluster connectivity..."
if kubectl cluster-info &> /dev/null; then
    CLUSTER=$(kubectl config current-context)
    print_success "Connected to cluster: $CLUSTER"
else
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

echo ""

# Check MetalLB
print_info "Checking MetalLB..."
METALLB_VERSION=$(kubectl get deployment metallb-controller -n metallb-system -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d':' -f2 || echo "NOT_FOUND")
METALLB_CONTROLLER_READY=$(kubectl get pods -n metallb-system -l app.kubernetes.io/component=controller --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
METALLB_SPEAKER_READY=$(kubectl get pods -n metallb-system -l app.kubernetes.io/component=speaker --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
METALLB_POOLS=$(kubectl get ipaddresspools -n metallb-system --no-headers 2>/dev/null | wc -l)
METALLB_L2ADS=$(kubectl get l2advertisements -n metallb-system --no-headers 2>/dev/null | wc -l)

if [[ "$METALLB_VERSION" != "NOT_FOUND" && "$METALLB_CONTROLLER_READY" -gt 0 && "$METALLB_SPEAKER_READY" -gt 0 && "$METALLB_POOLS" -gt 0 ]]; then
    print_success "MetalLB: $METALLB_VERSION (Controller: $METALLB_CONTROLLER_READY, Speakers: $METALLB_SPEAKER_READY, IP Pools: $METALLB_POOLS)"
else
    print_error "MetalLB: Issues detected"
    echo "  Version: $METALLB_VERSION"
    echo "  Controller Pods: $METALLB_CONTROLLER_READY"
    echo "  Speaker Pods: $METALLB_SPEAKER_READY"
    echo "  IP Address Pools: $METALLB_POOLS"
    echo "  L2 Advertisements: $METALLB_L2ADS"
fi

echo ""

# Check nginx ingress controller
print_info "Checking nginx ingress controller..."
NGINX_VERSION=$(kubectl get deployment ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d':' -f2 | cut -d'@' -f1 || echo "NOT_FOUND")
NGINX_READY=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
NGINX_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "NO_IP")

if [[ "$NGINX_VERSION" != "NOT_FOUND" && "$NGINX_READY" -gt 0 && "$NGINX_IP" != "NO_IP" ]]; then
    print_success "nginx ingress controller: $NGINX_VERSION (IP: $NGINX_IP)"
else
    print_error "nginx ingress controller: Issues detected"
    echo "  Version: $NGINX_VERSION"
    echo "  Ready Pods: $NGINX_READY"
    echo "  Load Balancer IP: $NGINX_IP"
fi

# Check cert-manager
print_info "Checking cert-manager..."
CERT_VERSION=$(kubectl get deployment cert-manager -n cert-manager -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d':' -f2 || echo "NOT_FOUND")
CERT_READY=$(kubectl get pods -n cert-manager --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
CERT_ISSUERS=$(kubectl get clusterissuers --no-headers 2>/dev/null | grep -c "True" || echo "0")

if [[ "$CERT_VERSION" != "NOT_FOUND" && "$CERT_READY" -ge 3 && "$CERT_ISSUERS" -ge 2 ]]; then
    print_success "cert-manager: $CERT_VERSION ($CERT_READY pods, $CERT_ISSUERS issuers)"
else
    print_error "cert-manager: Issues detected"
    echo "  Version: $CERT_VERSION"
    echo "  Ready Pods: $CERT_READY"
    echo "  Ready Issuers: $CERT_ISSUERS"
fi

# Check ArgoCD
print_info "Checking ArgoCD..."
ARGOCD_VERSION=$(kubectl get deployment argocd-server -n argocd -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d':' -f2 || echo "NOT_FOUND")
ARGOCD_READY=$(kubectl get pods -n argocd --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
ARGOCD_APPS=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l)

if [[ "$ARGOCD_VERSION" != "NOT_FOUND" && "$ARGOCD_READY" -ge 6 ]]; then
    print_success "ArgoCD: $ARGOCD_VERSION ($ARGOCD_READY pods, $ARGOCD_APPS applications)"
else
    print_error "ArgoCD: Issues detected"
    echo "  Version: $ARGOCD_VERSION"
    echo "  Ready Pods: $ARGOCD_READY"
    echo "  Applications: $ARGOCD_APPS"
fi

# Check SSL certificates
print_info "Checking SSL certificates..."
CERT_COUNT=$(kubectl get certificates -A --no-headers 2>/dev/null | wc -l | tr -d ' \n')
CERT_READY=$(kubectl get certificates -A --no-headers 2>/dev/null | grep -c "True" | tr -d ' \n' || echo "0")

if [[ "$CERT_COUNT" -gt 0 && "$CERT_READY" -eq "$CERT_COUNT" ]]; then
    print_success "SSL Certificates: $CERT_READY/$CERT_COUNT ready"
else
    print_warning "SSL Certificates: $CERT_READY/$CERT_COUNT ready"
fi

# Check ArgoCD HTTPS accessibility
print_info "Checking ArgoCD HTTPS accessibility..."
if curl -s -o /dev/null -w "%{http_code}" https://$CF_ARGOCD_DOMAIN | grep -q "200"; then
    RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" https://$CF_ARGOCD_DOMAIN)
    print_success "ArgoCD HTTPS: Accessible (${RESPONSE_TIME}s response time)"
else
    print_error "ArgoCD HTTPS: Not accessible"
fi

echo ""
echo "=============================="
print_info "Health check completed!"

# Summary
echo ""
print_info "📊 Component Summary:"
echo "• MetalLB: $METALLB_VERSION"
echo "• nginx ingress controller: $NGINX_VERSION"
echo "• cert-manager: $CERT_VERSION"  
echo "• ArgoCD: $ARGOCD_VERSION"
echo "• Load Balancer IP: $NGINX_IP"
echo "• SSL Certificates: $CERT_READY/$CERT_COUNT"
echo "• ArgoCD Applications: $ARGOCD_APPS"

echo ""
print_info "🔗 Quick Links:"
echo "• ArgoCD UI: https://$CF_ARGOCD_DOMAIN"
echo "• ArgoCD CLI Login: argocd login $CF_ARGOCD_DOMAIN --username admin"
