#!/bin/bash

# Homelab K3s Setup Uninstall Script
# This script removes all components installed by the homelab setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if kubectl is available and cluster is accessible
check_cluster_access() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot access Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
}

# Function to check if component is installed
check_component_installed() {
    local namespace=$1
    local release_name=$2
    
    if helm list -n "$namespace" 2>/dev/null | grep -q "$release_name"; then
        return 0  # Installed
    else
        return 1  # Not installed
    fi
}

# Function to uninstall Cert-Manager
uninstall_cert_manager() {
    print_status "Uninstalling Cert-Manager..."
    
    if check_component_installed "cert-manager" "cert-manager"; then
        # Delete ClusterIssuers first
        print_status "Removing ClusterIssuers..."
        kubectl delete clusterissuer letsencrypt-staging letsencrypt-prod --ignore-not-found=true
        
        # Delete any remaining certificates
        print_status "Removing certificates..."
        kubectl delete certificates --all --all-namespaces --ignore-not-found=true
        
        # Uninstall Helm release
        print_status "Uninstalling Cert-Manager Helm release..."
        helm uninstall cert-manager -n cert-manager
        
        # Wait for pods to terminate
        print_status "Waiting for Cert-Manager pods to terminate..."
        kubectl wait --for=delete pod --all -n cert-manager --timeout=120s || true
        
        # Delete CRDs
        print_status "Removing Cert-Manager CRDs..."
        kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.1/cert-manager.crds.yaml --ignore-not-found=true || {
            print_warning "Failed to delete CRDs via manifest, trying individual deletion..."
            kubectl delete crd certificaterequests.cert-manager.io --ignore-not-found=true
            kubectl delete crd certificates.cert-manager.io --ignore-not-found=true
            kubectl delete crd challenges.acme.cert-manager.io --ignore-not-found=true
            kubectl delete crd clusterissuers.cert-manager.io --ignore-not-found=true
            kubectl delete crd issuers.cert-manager.io --ignore-not-found=true
            kubectl delete crd orders.acme.cert-manager.io --ignore-not-found=true
        }
        
        # Delete namespace
        print_status "Removing cert-manager namespace..."
        kubectl delete namespace cert-manager --ignore-not-found=true
        
        print_success "Cert-Manager uninstalled successfully"
    else
        print_warning "Cert-Manager is not installed, skipping..."
    fi
    echo ""
}

# Function to uninstall Portainer
uninstall_portainer() {
    print_status "Uninstalling Portainer..."
    
    if check_component_installed "portainer" "portainer"; then
        # Delete Portainer Ingress
        print_status "Removing Portainer Ingress..."
        kubectl delete ingress portainer-ingress -n portainer --ignore-not-found=true
        
        # Uninstall Helm release
        print_status "Uninstalling Portainer Helm release..."
        helm uninstall portainer -n portainer
        
        # Wait for pods to terminate
        print_status "Waiting for Portainer pods to terminate..."
        kubectl wait --for=delete pod --all -n portainer --timeout=120s || true
        
        # Delete namespace (this will also remove PVCs)
        print_status "Removing portainer namespace..."
        kubectl delete namespace portainer --ignore-not-found=true
        
        print_success "Portainer uninstalled successfully"
    else
        print_warning "Portainer is not installed, skipping..."
    fi
    echo ""
}

# Function to uninstall ArgoCD
uninstall_argocd() {
    print_status "Uninstalling ArgoCD..."
    
    if check_component_installed "argocd" "argocd"; then
        # Delete ArgoCD Ingress
        print_status "Removing ArgoCD Ingress..."
        kubectl delete ingress argocd-server-ingress -n argocd --ignore-not-found=true
        
        # Delete ArgoCD applications first
        print_status "Removing ArgoCD applications..."
        kubectl delete applications --all -n argocd --ignore-not-found=true
        kubectl delete applicationsets --all -n argocd --ignore-not-found=true
        kubectl delete appprojects --all -n argocd --ignore-not-found=true
        
        # Uninstall Helm release
        print_status "Uninstalling ArgoCD Helm release..."
        helm uninstall argocd -n argocd
        
        # Wait for pods to terminate
        print_status "Waiting for ArgoCD pods to terminate..."
        kubectl wait --for=delete pod --all -n argocd --timeout=120s || true
        
        # Delete ArgoCD CRDs
        print_status "Removing ArgoCD CRDs..."
        kubectl delete crd applications.argoproj.io --ignore-not-found=true
        kubectl delete crd applicationsets.argoproj.io --ignore-not-found=true
        kubectl delete crd appprojects.argoproj.io --ignore-not-found=true
        
        # Delete namespace
        print_status "Removing argocd namespace..."
        kubectl delete namespace argocd --ignore-not-found=true
        
        print_success "ArgoCD uninstalled successfully"
    else
        print_warning "ArgoCD is not installed, skipping..."
    fi
    echo ""
}

# Function to uninstall NGINX Ingress Controller
uninstall_nginx_ingress() {
    print_status "Uninstalling NGINX Ingress Controller..."
    
    if check_component_installed "ingress-nginx" "ingress-nginx"; then
        # Delete custom headers ConfigMap
        print_status "Removing custom headers ConfigMap..."
        kubectl delete configmap custom-headers -n ingress-nginx --ignore-not-found=true
        
        # Delete any remaining ingresses
        print_status "Removing ingresses..."
        kubectl delete ingress --all --all-namespaces --ignore-not-found=true
        
        # Uninstall Helm release
        print_status "Uninstalling NGINX Ingress Controller Helm release..."
        helm uninstall ingress-nginx -n ingress-nginx
        
        # Wait for pods to terminate
        print_status "Waiting for NGINX Ingress Controller pods to terminate..."
        kubectl wait --for=delete pod --all -n ingress-nginx --timeout=120s || true
        
        # Delete validating webhook configurations
        print_status "Removing webhook configurations..."
        kubectl delete validatingwebhookconfigurations ingress-nginx-admission --ignore-not-found=true
        kubectl delete mutatingwebhookconfigurations ingress-nginx-admission --ignore-not-found=true
        
        # Delete namespace
        print_status "Removing ingress-nginx namespace..."
        kubectl delete namespace ingress-nginx --ignore-not-found=true
        
        print_success "NGINX Ingress Controller uninstalled successfully"
    else
        print_warning "NGINX Ingress Controller is not installed, skipping..."
    fi
    echo ""
}

# Function to uninstall MetalLB
uninstall_metallb() {
    print_status "Uninstalling MetalLB..."
    
    if check_component_installed "metallb-system" "metallb"; then
        # Delete IP address pools and L2 advertisements
        print_status "Removing MetalLB configuration..."
        kubectl delete ipaddresspools --all -n metallb-system --ignore-not-found=true
        kubectl delete l2advertisements --all -n metallb-system --ignore-not-found=true
        kubectl delete bgpadvertisements --all -n metallb-system --ignore-not-found=true
        kubectl delete bgppeers --all -n metallb-system --ignore-not-found=true
        
        # Uninstall Helm release
        print_status "Uninstalling MetalLB Helm release..."
        helm uninstall metallb -n metallb-system
        
        # Wait for pods to terminate
        print_status "Waiting for MetalLB pods to terminate..."
        kubectl wait --for=delete pod --all -n metallb-system --timeout=120s || true
        
        # Delete webhook configurations
        print_status "Removing MetalLB webhook configurations..."
        kubectl delete validatingwebhookconfigurations metallb-webhook-configuration --ignore-not-found=true
        kubectl delete mutatingwebhookconfigurations metallb-webhook-configuration --ignore-not-found=true
        
        # Delete MetalLB CRDs
        print_status "Removing MetalLB CRDs..."
        kubectl delete crd bfdprofiles.metallb.io --ignore-not-found=true
        kubectl delete crd bgpadvertisements.metallb.io --ignore-not-found=true
        kubectl delete crd bgppeers.metallb.io --ignore-not-found=true
        kubectl delete crd communities.metallb.io --ignore-not-found=true
        kubectl delete crd ipaddresspools.metallb.io --ignore-not-found=true
        kubectl delete crd l2advertisements.metallb.io --ignore-not-found=true
        kubectl delete crd servicebgpstatuses.metallb.io --ignore-not-found=true
        kubectl delete crd servicel2statuses.metallb.io --ignore-not-found=true
        
        # Delete namespace
        print_status "Removing metallb-system namespace..."
        kubectl delete namespace metallb-system --ignore-not-found=true
        
        print_success "MetalLB uninstalled successfully"
    else
        print_warning "MetalLB is not installed, skipping..."
    fi
    echo ""
}

# Function to clean up any remaining resources
cleanup_remaining_resources() {
    print_status "Cleaning up remaining resources..."
    
    # Remove any remaining PVCs
    print_status "Removing PVCs from homelab namespaces..."
    kubectl delete pvc --all -n metallb-system --ignore-not-found=true
    kubectl delete pvc --all -n ingress-nginx --ignore-not-found=true
    kubectl delete pvc --all -n argocd --ignore-not-found=true
    kubectl delete pvc --all -n cert-manager --ignore-not-found=true
    
    # Remove any remaining secrets
    print_status "Removing TLS secrets..."
    kubectl delete secret -l cert-manager.io/certificate-name --all-namespaces --ignore-not-found=true
    
    # Remove any remaining ClusterRoles and ClusterRoleBindings
    print_status "Removing cluster-wide RBAC resources..."
    kubectl delete clusterrole -l app.kubernetes.io/name=metallb --ignore-not-found=true
    kubectl delete clusterrole -l app.kubernetes.io/name=ingress-nginx --ignore-not-found=true
    kubectl delete clusterrole -l app.kubernetes.io/name=argocd --ignore-not-found=true
    kubectl delete clusterrole -l app.kubernetes.io/name=cert-manager --ignore-not-found=true
    
    kubectl delete clusterrolebinding -l app.kubernetes.io/name=metallb --ignore-not-found=true
    kubectl delete clusterrolebinding -l app.kubernetes.io/name=ingress-nginx --ignore-not-found=true
    kubectl delete clusterrolebinding -l app.kubernetes.io/name=argocd --ignore-not-found=true
    kubectl delete clusterrolebinding -l app.kubernetes.io/name=cert-manager --ignore-not-found=true
    
    # Clean up any orphaned finalizers (force cleanup if needed)
    print_status "Checking for resources with stuck finalizers..."
    local stuck_namespaces=$(kubectl get namespaces --field-selector=status.phase=Terminating -o name 2>/dev/null || true)
    if [[ -n "$stuck_namespaces" ]]; then
        print_warning "Found namespaces stuck in Terminating state:"
        echo "$stuck_namespaces"
        print_warning "You may need to manually remove finalizers if deletion takes too long."
    fi
    
    print_success "Cleanup completed"
    echo ""
}

# Function to show uninstallation status
show_uninstall_status() {
    print_status "Checking remaining components..."
    echo ""
    
    echo "📋 Remaining Components:"
    
    # Check MetalLB
    if check_component_installed "metallb-system" "metallb"; then
        echo "  ⚠️  MetalLB: Still installed"
    else
        echo "  ✅ MetalLB: Removed"
    fi
    
    # Check NGINX Ingress
    if check_component_installed "ingress-nginx" "ingress-nginx"; then
        echo "  ⚠️  NGINX Ingress Controller: Still installed"
    else
        echo "  ✅ NGINX Ingress Controller: Removed"
    fi
    
    # Check ArgoCD
    if check_component_installed "argocd" "argocd"; then
        echo "  ⚠️  ArgoCD: Still installed"
    else
        echo "  ✅ ArgoCD: Removed"
    fi
    
    # Check Cert-Manager
    if check_component_installed "cert-manager" "cert-manager"; then
        echo "  ⚠️  Cert-Manager: Still installed"
    else
        echo "  ✅ Cert-Manager: Removed"
    fi
    
    # Check Portainer
    if check_component_installed "portainer" "portainer"; then
        echo "  ⚠️  Portainer: Still installed"
    else
        echo "  ✅ Portainer: Removed"
    fi
    
    echo ""
}

# Main uninstall function
main() {
    echo "🗑️  Homelab K3s Setup Uninstall"
    echo "==============================="
    echo ""
    
    # Check cluster access first
    check_cluster_access
    
    print_warning "This will completely remove all homelab components:"
    echo "  1. Cert-Manager (including all certificates)"
    echo "  2. ArgoCD (including all applications)"
    echo "  3. NGINX Ingress Controller (including all ingresses)"
    echo "  4. MetalLB (including load balancer configuration)"
    echo ""
    print_warning "This action cannot be undone!"
    echo ""
    print_warning "Do you want to continue? (yes/NO)"
    read -r response
    if [[ ! "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
        print_error "Uninstall cancelled"
        exit 1
    fi
    echo ""
    
    # Uninstall in reverse order (last installed first)
    uninstall_cert_manager
    uninstall_portainer
    uninstall_argocd
    uninstall_nginx_ingress
    uninstall_metallb
    
    # Clean up remaining resources
    cleanup_remaining_resources
    
    # Show final status
    show_uninstall_status
    
    print_success "🎉 All homelab components have been uninstalled!"
    echo ""
    echo "📝 What was removed:"
    echo "  ✅ All Helm releases"
    echo "  ✅ All namespaces and resources"
    echo "  ✅ All CRDs and webhook configurations"
    echo "  ✅ All certificates and secrets"
    echo "  ✅ All cluster-wide RBAC resources"
    echo ""
    print_status "Your cluster is now clean and ready for a fresh installation."
}

# Run main function or show status
if [[ "$1" == "--status" ]] || [[ "$1" == "-s" ]]; then
    echo "🗑️  Homelab K3s Uninstall Status"
    echo "==============================="
    echo ""
    show_uninstall_status
    exit 0
elif [[ "$1" == "--dry-run" ]] || [[ "$1" == "-d" ]]; then
    echo "🧪 Homelab K3s Uninstall - Dry Run"
    echo "==================================="
    echo ""
    check_cluster_access
    print_status "This would uninstall the following components:"
    echo ""
    show_uninstall_status
    echo ""
    print_warning "To actually perform the uninstall, run without --dry-run"
    exit 0
elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "🗑️  Homelab K3s Setup Uninstall Script"
    echo "======================================"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --status, -s     Show current installation status"
    echo "  --dry-run, -d    Show what would be uninstalled without doing it"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0               Interactive uninstall (asks for confirmation)"
    echo "  $0 --status      Check what components are installed"
    echo "  $0 --dry-run     Preview what would be uninstalled"
    echo ""
    exit 0
else
    main "$@"
fi
