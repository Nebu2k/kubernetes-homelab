# Homelab K3s Setup

A complete, production-ready Kubernetes homelab setup with GitOps, automatic SSL, and DNS management.

## 🚀 Features

- **One-click installation** of complete K3s infrastructure
- **Automatic SSL certificates** via Let's Encrypt + Cloudflare DNS-01
- **Automatic DNS management** with Cloudflare API integration  
- **GitOps-ready** with ArgoCD for application deployment
- **Production hardened** NGINX Ingress with proper security headers
- **Environment-based configuration** using `.env` files

## 📦 Components

| Component | Purpose | Version |
|-----------|---------|---------|
| **MetalLB** | Load balancer for bare-metal clusters | Latest |
| **NGINX Ingress** | HTTP/HTTPS traffic routing | Latest |
| **ArgoCD** | GitOps continuous delivery | v3.0.6 |
| **Cert-Manager** | Automated SSL certificate management | v1.18.1 |
| **Portainer** | Container management web UI | v2.31.1 |

## 🔧 Prerequisites

- K3s cluster running **without Traefik** (install with `--disable traefik`)
- Helm 3.x installed and configured
- kubectl configured to access your cluster
- Cloudflare account with API token (for SSL and DNS automation)
- Reserved IP address for MetalLB (default: `192.168.2.254`)

## ⚡ Quick Start

### 1. Configuration

Create and customize your `.env` file:

```bash
# Copy the example and edit with your values
cp .env.example .env
```

Required variables in `.env`:
```env
# Your domain managed by Cloudflare
CF_DOMAIN=example.com

# Optional: Override default subdomains (defaults to service.${CF_DOMAIN})
# CF_ARGOCD_DOMAIN=argocd.example.com
# CF_PORTAINER_DOMAIN=portainer.example.com
# CF_PIHOLE_DOMAIN=pihole.example.com

# Cloudflare API credentials  
CF_ZONE_ID=your_cloudflare_zone_id
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token

# Target for DNS records (e.g., your dynamic DNS hostname)
CF_DEFAULT_TARGET=your-dynamic-dns.example.net

# Email for Let's Encrypt certificates
CF_CERT_EMAIL=admin@example.com
```

### 2. One-Click Installation

```bash
# Install everything
./install-all.sh

# Check installation status
./install-all.sh --status

# Force reinstall if needed
./install-all.sh --force
```

### 3. Access Your Services

After installation:
- **ArgoCD UI**: `https://argocd.yourdomain.com`
- **Portainer UI**: `https://portainer.yourdomain.com`
- **Get ArgoCD password**: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

## 🔑 Cloudflare Setup

### API Token Creation
1. Go to [Cloudflare Dashboard → API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Create token with **"Edit zone DNS"** template
3. Select your domain zone
4. Copy the token to your `.env` file

### Zone ID
1. Go to your domain overview in Cloudflare
2. Find **Zone ID** in the right sidebar
3. Copy to your `.env` file

**What the automated setup does:**

- ✅ Installs all infrastructure components
- ✅ Creates SSL certificates automatically (DNS-01 challenge)
- ✅ Creates DNS records automatically (CNAME to your dynamic DNS)
- ✅ Configures ingress routing
- ✅ Sets up ArgoCD with HTTPS access

## 🛠️ Manual Installation

For advanced users or custom setups:

If you prefer manual DNS management or don't use Cloudflare:

```bash
# Install all components (without SSL automation)
./install-all.sh

# Manually create DNS records pointing to 192.168.2.254
# Manually create SSL certificates if needed
```

### Automated Uninstallation

To completely remove all homelab components:

```bash
# Preview what would be uninstalled (dry run)
./uninstall-all.sh --dry-run

# Check current installation status
./uninstall-all.sh --status

# Interactive uninstall (asks for confirmation)
./uninstall-all.sh

# Show help
./uninstall-all.sh --help
```

**⚠️ Warning**: The uninstall script will completely remove all homelab components including:

- All Helm releases and their resources
- All namespaces (metallb-system, ingress-nginx, argocd, cert-manager)
- All Custom Resource Definitions (CRDs)
- All certificates and TLS secrets
- All cluster-wide RBAC resources
- All webhook configurations

This action cannot be undone!

## Installation Order

Follow the installation in this specific order:

1. [MetalLB](#metallb-installation)
2. [NGINX Ingress Controller](#nginx-ingress-installation)
3. [ArgoCD](#argocd-installation)
4. [Cert-Manager](#cert-manager-installation)

## MetalLB Installation

```bash
# Add MetalLB Helm repository
helm repo add metallb https://metallb.github.io/metallb
helm repo update

# Install MetalLB
helm install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace \
  --values k8s-setup/metallb/values.yaml

# Apply IP address pool configuration
kubectl apply -f k8s-setup/metallb/ip-pool.yaml
```

## NGINX Ingress Installation

```bash
# Add NGINX Ingress Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values k8s-setup/nginx-ingress/values.yaml
```

## ArgoCD Installation

```bash
# Add ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
./k8s-setup/argocd/install.sh
```

> **Hinweis:** Das Installationsscript ersetzt automatisch alle Variablen in der Ingress-YAML mit `envsubst` und wendet sie an. Ein manueller Zwischenschritt ist nicht nötig.

## Cert-Manager Installation

**Automatic Installation (Recommended):**

```bash
# Set Cloudflare API token for automatic SSL certificate management
export CLOUDFLARE_API_TOKEN=your_api_token_here

# Install Cert-Manager with automatic Cloudflare integration
./k8s-setup/cert-manager/install.sh
```

**Manual Installation:**

```bash
# Add Cert-Manager Helm repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install Cert-Manager CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.1/cert-manager.crds.yaml

# Install Cert-Manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --values k8s-setup/cert-manager/values.yaml

# Apply ClusterIssuer for Let's Encrypt
kubectl apply -f k8s-setup/cert-manager/cluster-issuer.yaml

# Manually create Cloudflare API token secret (if needed)
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token="your_api_token_here" \
  --namespace cert-manager
```

**SSL Certificate Features:**
- ✅ **DNS-01 Challenge**: Works with Cloudflare proxy enabled
- ✅ **Automatic Renewal**: Certificates auto-renew every 60 days  
- ✅ **Wildcard Support**: Can create `*.yourdomain.com` certificates
- ✅ **No Ingress Conflicts**: No HTTP-01 challenge issues

## Verification

After installation, verify that all components are running:

```bash
# Check MetalLB
kubectl get pods -n metallb-system

# Check NGINX Ingress
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Check ArgoCD
kubectl get pods -n argocd
kubectl get ingress -n argocd

# Check Cert-Manager
kubectl get pods -n cert-manager
kubectl get clusterissuer
```

## Accessing Services

- **ArgoCD UI**: `https://argocd.yourdomain.com` (DNS record created automatically with Cloudflare integration)
- **Portainer UI**: `https://portainer.yourdomain.com` (DNS record created automatically with Cloudflare integration)
- **PiHole UI**: `https://pihole.yourdomain.com` (DNS record created automatically with Cloudflare integration)
- **NGINX Ingress LoadBalancer IP**: `192.168.2.254`

## DNS Management

The homelab includes automatic DNS record management for Cloudflare:

```bash
# Create DNS records for any service
./scripts/create-dns-record.sh subdomain [target]

# Examples:
./scripts/create-dns-record.sh argocd                    # argocd.${CF_DOMAIN} -> ${CF_DEFAULT_TARGET}
./scripts/create-dns-record.sh portainer                 # portainer.${CF_DOMAIN} -> ${CF_DEFAULT_TARGET}
./scripts/create-dns-record.sh pihole                    # pihole.${CF_DOMAIN} -> ${CF_DEFAULT_TARGET}
./scripts/create-dns-record.sh grafana                   # grafana.${CF_DOMAIN} -> ${CF_DEFAULT_TARGET}
./scripts/create-dns-record.sh test custom.example.com   # test.${CF_DOMAIN} -> custom.example.com
```

## Using Environment Variables in YAML (envsubst)

If you use variables like `${CF_DOMAIN}` in your YAML files, you must substitute them before applying to Kubernetes. Kubernetes does not understand shell variables in YAML.

**How to use:**

1. Load your .env file into the shell:
   ```bash
   export $(grep -v '^#' .env | xargs)
   ```
2. Substitute variables and apply:
   ```bash
   envsubst < k8s-setup/argocd/ingress.yaml | kubectl apply -f -
   ```

**Note:**
- If you forget to load the .env file, variables will be empty and Kubernetes will reject the resource with an error like:
  > Invalid value: "": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters...
- Always check that your variables are set before running `envsubst`.

## Notes

- SSL certificates are automatically created using DNS-01 challenges (works with Cloudflare proxy)
- DNS records are automatically created during service installation
- ArgoCD initial admin password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- All services use HTTPS with valid Let's Encrypt certificates

## Environment Variables

This setup uses the following environment variables (set in `.env` file):

```env
# Cloudflare API token for DNS and SSL management
CLOUDFLARE_API_TOKEN=cf_api_token_123456

# Cloudflare Zone ID for your domain (find in Cloudflare dashboard)
CF_ZONE_ID=cf_zone_id_abcdef

# Main domain for the homelab
CF_DOMAIN=example.com

# Optional: Override default subdomains (defaults to service.${CF_DOMAIN})
# CF_ARGOCD_DOMAIN=argocd.example.com
# CF_PORTAINER_DOMAIN=portainer.example.com
# CF_PIHOLE_DOMAIN=pihole.example.com

# Default target for DNS records (e.g., dynamic DNS)
CF_DEFAULT_TARGET=dynamic-dns.example.net

**Note:** After modifying the `.env` file, run `envsubst < .env` to substitute the variables in the configuration files.
```
