#!/bin/bash

# Master Installation Script for Homelab K3s Setup
# This script orchestrates the installation of all components

set -e

# Global variables
FORCE_INSTALL=false

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

# Load .env file from root if present
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
else
    print_error ".env file not found in root directory. Please create one with required variables."
    exit 1
fi

# Check required variables
if [ -z "$CF_ARGOCD_DOMAIN" ] || [ -z "$CF_DOMAIN" ]; then
    print_error "Required variables CF_ARGOCD_DOMAIN and CF_DOMAIN must be set in .env file"
    exit 1
fi

# Function to check if kubectl is available and cluster is reachable
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed or not in PATH"
        exit 1
    fi
    
    # Check if cluster is reachable
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check if k3s is running without traefik
    if kubectl get svc -n kube-system traefik &> /dev/null; then
        print_warning "Traefik is detected in the cluster. This setup assumes k3s without traefik."
        print_warning "Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_error "Installation cancelled"
            exit 1
        fi
    fi
    
    print_success "Prerequisites check passed"
}

# Function to install MetalLB
install_metallb() {
    if ! $FORCE_INSTALL && check_metallb; then
        print_warning "MetalLB is already installed, skipping... (use --force to reinstall)"
        return 0
    fi
    
    print_status "Installing MetalLB..."
    cd /Users/speters/workspace/homelab
    if $FORCE_INSTALL; then
        FORCE_INSTALL=true ./k8s-setup/metallb/install.sh
    else
        ./k8s-setup/metallb/install.sh
    fi
    print_success "MetalLB installation completed"
    echo ""
}

# Function to install NGINX Ingress
install_nginx_ingress() {
    if ! $FORCE_INSTALL && check_nginx_ingress; then
        print_warning "NGINX Ingress Controller is already installed, skipping... (use --force to reinstall)"
        return 0
    fi
    
    print_status "Installing NGINX Ingress Controller..."
    cd /Users/speters/workspace/homelab
    if $FORCE_INSTALL; then
        FORCE_INSTALL=true ./k8s-setup/nginx-ingress/install.sh
    else
        ./k8s-setup/nginx-ingress/install.sh
    fi
    print_success "NGINX Ingress Controller installation completed"
    echo ""
}

# Function to install ArgoCD
install_argocd() {
    if ! $FORCE_INSTALL && check_argocd; then
        print_warning "ArgoCD is already installed, skipping... (use --force to reinstall)"
        return 0
    fi
    
    print_status "Installing ArgoCD..."
    cd /Users/speters/workspace/homelab
    if $FORCE_INSTALL; then
        FORCE_INSTALL=true ./k8s-setup/argocd/install.sh
    else
        ./k8s-setup/argocd/install.sh
    fi
    print_success "ArgoCD installation completed"
    echo ""
}

# Function to install Cert-Manager
install_cert_manager() {
    if ! $FORCE_INSTALL && check_cert_manager; then
        print_warning "Cert-Manager is already installed, skipping... (use --force to reinstall)"
        return 0
    fi
    
    print_status "Installing Cert-Manager..."
    cd /Users/speters/workspace/homelab
    if $FORCE_INSTALL; then
        FORCE_INSTALL=true ./k8s-setup/cert-manager/install.sh
    else
        ./k8s-setup/cert-manager/install.sh
    fi
    print_success "Cert-Manager installation completed"
    echo ""
}

# Function to check if MetalLB is already installed
check_metallb() {
    if helm list -n metallb-system | grep -q "metallb"; then
        return 0  # Already installed
    else
        return 1  # Not installed
    fi
}

# Function to check if NGINX Ingress is already installed
check_nginx_ingress() {
    if helm list -n ingress-nginx | grep -q "ingress-nginx"; then
        return 0  # Already installed
    else
        return 1  # Not installed
    fi
}

# Function to check if ArgoCD is already installed
check_argocd() {
    if helm list -n argocd | grep -q "argocd"; then
        return 0  # Already installed
    else
        return 1  # Not installed
    fi
}

# Function to check if Cert-Manager is already installed
check_cert_manager() {
    if helm list -n cert-manager | grep -q "cert-manager"; then
        return 0  # Already installed
    else
        return 1  # Not installed
    fi
}

# Function to show installation status
show_installation_status() {
    print_status "Checking current installation status..."
    echo ""
    
    echo "📋 Component Status:"
    
    # Check MetalLB
    if check_metallb; then
        echo "  ✅ MetalLB: Installed"
    else
        echo "  ❌ MetalLB: Not installed"
    fi
    
    # Check NGINX Ingress
    if check_nginx_ingress; then
        echo "  ✅ NGINX Ingress Controller: Installed"
    else
        echo "  ❌ NGINX Ingress Controller: Not installed"
    fi
    
    # Check ArgoCD
    if check_argocd; then
        echo "  ✅ ArgoCD: Installed"
    else
        echo "  ❌ ArgoCD: Not installed"
    fi
    
    # Check Cert-Manager
    if check_cert_manager; then
        echo "  ✅ Cert-Manager: Installed"
    else
        echo "  ❌ Cert-Manager: Not installed"
    fi
    
    echo ""
}

# Main installation function
main() {
    echo "🏠 Homelab K3s Setup Installation"
    echo "=================================="
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Show current installation status
    show_installation_status
    
    # Confirm installation
    print_warning "This will install the following components:"
    echo "  1. MetalLB (Load Balancer)"
    echo "  2. NGINX Ingress Controller"
    echo "  3. ArgoCD (GitOps)"
    echo "  4. Cert-Manager (Certificate Management)"
    echo ""
    print_warning "The installation will use IP 192.168.2.254 for the load balancer."
    print_warning "Continue with installation? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled"
        exit 1
    fi
    echo ""
    
    # Install components in order
    install_metallb
    install_nginx_ingress
    install_argocd
    install_cert_manager
    
    # Final status
    print_success "🎉 All components installed successfully!"
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Update DNS records to point your domains to 192.168.2.254"
    echo "  2. Update domain names in ArgoCD and Cert-Manager configuration files if needed"
    echo "  3. Access ArgoCD at https://$CF_ARGOCD_DOMAIN"
    echo ""
    echo "📝 ArgoCD Admin Password:"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    echo ""
    echo ""
    print_warning "Remember to change the ArgoCD admin password after first login!"
}

# Run main function or show status
if [[ "$1" == "--status" ]] || [[ "$1" == "-s" ]]; then
    echo "🏠 Homelab K3s Setup Status"
    echo "==========================="
    echo ""
    show_installation_status
    exit 0
elif [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
    FORCE_INSTALL=true
    echo "🔧 Force installation mode enabled"
    main "${@:2}"
elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "🏠 Homelab K3s Setup Script"
    echo "=========================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --status, -s     Show current installation status"
    echo "  --force, -f      Force reinstall even if components exist"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0               Normal installation (skips existing components)"
    echo "  $0 --force       Force reinstall all components"
    echo "  $0 --status      Check installation status"
    echo ""
    exit 0
else
    main "$@"
fi
