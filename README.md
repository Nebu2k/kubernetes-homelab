# Kubernetes Homelab - GitOps with ArgoCD

Production-ready K3s cluster managed via GitOps using ArgoCD App-of-Apps pattern.

## 🎯 Architecture

**Key Principle**: ArgoCD manages everything EXCEPT itself (prevents self-management conflicts).

### Deployment Flow

```text
1. Manual: K3s + Kube-VIP → HA Control Plane
2. Manual: ArgoCD via Helm → GitOps Engine
3. GitOps: bootstrap/root-app.yaml → App-of-Apps
4. GitOps: Everything else deployed automatically with Sync-Waves
```

### Sync-Wave Order

| Wave | Component |
|------|-----------|
| 0 | Sealed Secrets, Coredns Config |
| 1 | Reloader, Kured, Metallb |
| 2 | Cert Manager |
| 3 | Traefik |
| 4 | Longhorn |
| 5 | Landing Page, Portainer, Teslamate |
| 6 | Kube Prometheus Stack |
| 7 | Unifi Poller, Home Assistant |
| 8 | Uptime Kuma, Newt |
| 9 | N8n, Homepage |
| 11 | Proxmox Exporter |
| 12 | Argocd Config |
| 16 | Private Services |

## 📁 Repository Structure

```text
homelab/
├── bootstrap/
│   └── root-app.yaml              # App-of-Apps (deploys everything)
├── apps/
│   ├── kustomization.yaml         # List of all apps
│   ├── coredns-config.yaml            # Wave 0
│   ├── sealed-secrets.yaml            # Wave 0
│   ├── kured.yaml                     # Wave 1
│   ├── metallb.yaml                   # Wave 1
│   ├── reloader.yaml                  # Wave 1
│   ├── cert-manager.yaml              # Wave 2
│   ├── traefik.yaml                   # Wave 3
│   ├── longhorn.yaml                  # Wave 4
│   ├── landing-page.yaml              # Wave 5
│   ├── portainer.yaml                 # Wave 5
│   ├── teslamate.yaml                 # Wave 5
│   ├── kube-prometheus-stack.yaml     # Wave 6
│   ├── home-assistant.yaml            # Wave 7
│   ├── unifi-poller.yaml              # Wave 7
│   ├── newt.yaml                      # Wave 8
│   ├── uptime-kuma.yaml               # Wave 8
│   ├── homepage.yaml                  # Wave 9
│   ├── n8n.yaml                       # Wave 9
│   ├── proxmox-exporter.yaml          # Wave 11
│   ├── argocd-config.yaml             # Wave 12
│   └── private-services.yaml          # Wave 16
└── manifests/
    ├── argocd/
    │   ├── argocd-cm-patch.yaml
    │   ├── argocd-rbac-cm-patch.yaml
    │   ├── argocd-server-patch.yaml
    │   ├── ingress.yaml
    │   └── kustomization.yaml
    ├── cert-manager/
    │   ├── cloudflare-dns-sync-configmap.yaml
    │   ├── cloudflare-dns-sync-jobs.yaml
    │   ├── cloudflare-dns-sync-rbac.yaml
    │   ├── cloudflare-token-sealed.yaml
    │   ├── cloudflare-token-unsealed.yaml
    │   ├── cluster-issuer.yaml
    │   ├── kustomization.yaml
    │   └── values.yaml
    ├── coredns/
    │   ├── coredns-custom.yaml
    │   └── kustomization.yaml
    ├── home-assistant/
    │   ├── configmap-configuration.yaml
    │   ├── deployment.yaml
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   ├── matter-pvc.yaml
    │   ├── middleware-real-ip.yaml
    │   ├── namespace.yaml
    │   ├── pvc.yaml
    │   └── service.yaml
    ├── homepage/
    │   ├── adguard-credentials-sealed.yaml
    │   ├── adguard-credentials-unsealed.yaml
    │   ├── argocd-token-secret-sealed.yaml
    │   ├── argocd-token-secret-unsealed.yaml
    │   ├── clusterrole.yaml
    │   ├── clusterrolebinding.yaml
    │   ├── configmap.yaml
    │   ├── deployment.yaml
    │   ├── grafana-credentials-sealed.yaml
    │   ├── grafana-credentials-unsealed.yaml
    │   ├── ingress.yaml
    │   ├── internal-ca-copy.yaml
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   ├── nextcloud-token-sealed.yaml
    │   ├── nextcloud-token-unsealed.yaml
    │   ├── plex-token-sealed.yaml
    │   ├── plex-token-unsealed.yaml
    │   ├── portainer-token-sealed.yaml
    │   ├── portainer-token-unsealed.yaml
    │   ├── proxmox-secret-sealed.yaml
    │   ├── service.yaml
    │   ├── serviceaccount.yaml
    │   ├── unifi-token-sealed.yaml
    │   └── unifi-token-unsealed.yaml
    ├── kube-prometheus-stack/
    │   ├── alertmanager-ingress.yaml
    │   ├── aws-credentials-sealed.yaml
    │   ├── aws-credentials-unsealed.yaml
    │   ├── grafana-ingress.yaml
    │   ├── kustomization.yaml
    │   ├── prometheus-ingress.yaml
    │   ├── prometheus-rules.yaml
    │   └── values.yaml
    ├── kured/
    │   └── values.yaml
    ├── landing-page/
    │   ├── configmap.yaml
    │   ├── deployment.yaml
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   └── service.yaml
    ├── longhorn/
    │   ├── disable-local-path-default.yaml
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   ├── node-config.yaml
    │   ├── recurring-backup-jobs.yaml
    │   ├── s3-secret-sealed.yaml
    │   ├── s3-secret-unsealed.yaml
    │   ├── servicemonitor.yaml
    │   └── values.yaml
    ├── metallb/
    │   ├── kustomization.yaml
    │   ├── metallb-ip-pool.yaml
    │   └── values.yaml
    ├── n8n/
    │   ├── deployment.yaml
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   ├── postgresql-pvc.yaml
    │   ├── postgresql-secret-sealed.yaml
    │   ├── postgresql-secret-unsealed.yaml
    │   ├── postgresql-service.yaml
    │   ├── postgresql-statefulset.yaml
    │   ├── pvc.yaml
    │   └── service.yaml
    ├── newt/
    │   ├── kustomization.yaml
    │   ├── newt-auth-sealed.yaml
    │   ├── newt-auth-unsealed.yaml
    │   └── values.yaml
    ├── portainer/
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   ├── servers-transport.yaml
    │   └── values.yaml
    ├── private-services/
    │   ├── adguard-credentials-sealed.yaml
    │   ├── adguard-credentials-unsealed.yaml
    │   ├── adguard-dns-sync-job.yaml
    │   ├── adguard-dns-sync-rbac.yaml
    │   ├── adguard-ingress.yaml
    │   ├── adguard-macmini-ingress.yaml
    │   ├── adguard-sync-ingress.yaml
    │   ├── beszel-ingress.yaml
    │   ├── dreambox-ingress.yaml
    │   ├── fr24-ingress.yaml
    │   ├── glances-macmini-ingress.yaml
    │   ├── internal-cluster-issuer.yaml
    │   ├── kustomization.yaml
    │   ├── minio-ingress.yaml
    │   ├── minio-middleware.yaml
    │   ├── nextcloud-ingress.yaml
    │   ├── plex-ingress.yaml
    │   ├── proxmox-ingress.yaml
    │   ├── servers-transport.yaml
    │   └── unifi-ingress.yaml
    ├── proxmox-exporter/
    │   ├── configmap.yaml
    │   ├── deployment.yaml
    │   ├── kustomization.yaml
    │   ├── pve-api-credentials-sealed.yaml
    │   ├── pve-api-credentials-unsealed.yaml
    │   ├── service.yaml
    │   └── servicemonitor.yaml
    ├── reloader/
    │   └── values.yaml
    ├── teslamate/
    │   ├── database-deployment.yaml
    │   ├── database-pdb.yaml
    │   ├── database-pvc.yaml
    │   ├── grafana-deployment.yaml
    │   ├── grafana-ingress.yaml
    │   ├── grafana-pvc.yaml
    │   ├── kustomization.yaml
    │   ├── mosquitto-deployment.yaml
    │   ├── mosquitto-pvc.yaml
    │   ├── namespace.yaml
    │   ├── teslamate-deployment.yaml
    │   ├── teslamate-ingress.yaml
    │   ├── teslamate-secret-sealed.yaml
    │   └── teslamate-secret-unsealed.yaml
    ├── traefik/
    │   └── values.yaml
    ├── unifi-poller/
    │   ├── deployment.yaml
    │   ├── kustomization.yaml
    │   ├── service.yaml
    │   ├── servicemonitor.yaml
    │   ├── unifi-config-sealed.yaml
    │   └── unifi-config-unsealed.yaml
    └── uptime-kuma/
        ├── deployment.yaml
        ├── ingress.yaml
        ├── kustomization.yaml
        ├── namespace.yaml
        ├── pvc.yaml
        └── service.yaml
```

## 🚀 Fresh Installation

### Prerequisites

- 2+ nodes
- Domain with Cloudflare DNS
- Cloudflare API Token (Zone.DNS Edit permission)
- S3-compatible storage for Longhorn backups (optional)

### Step 1: Install K3s Cluster (**on raspi4**)

**First control plane node:**

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=stable sh -s - server \
  --cluster-init \
  --tls-san 192.168.2.249 \
  --tls-san raspi4 \
  --tls-san 192.168.2.2 \
  --disable traefik \
  --write-kubeconfig-mode 644

# Save token for additional nodes
sudo cat /var/lib/rancher/k3s/server/node-token
```

### Step 2: Install Kube-VIP (**on raspi4** - Control Plane HA)

```bash
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-vip-ds
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: kube-vip-ds
  template:
    metadata:
      labels:
        name: kube-vip-ds
    spec:
      hostNetwork: true
      nodeSelector:
        node-role.kubernetes.io/control-plane: "true"
      serviceAccountName: kube-vip
      containers:
      - name: kube-vip
        image: ghcr.io/kube-vip/kube-vip:v1.0.1
        args: ["manager"]
        env:
        - name: vip_arp
          value: "true"
        - name: port
          value: "6443"
        - name: vip_cidr
          value: "32"
        - name: cp_enable
          value: "true"
        - name: cp_namespace
          value: kube-system
        - name: vip_leaderelection
          value: "true"
        - name: address
          value: "192.168.2.249"  # TODO: Your VIP
        securityContext:
          capabilities:
            add: ["NET_ADMIN", "NET_RAW"]
      tolerations:
      - effect: NoSchedule
        operator: Exists
      - effect: NoExecute
        operator: Exists
EOF

# Wait for Kube-VIP to be ready
sleep 10

# Test VIP
ping -c 3 192.168.2.249
```

### Step 3: Configure kubectl with VIP (**on your laptop**)

```bash
scp raspi4:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i '' 's/127.0.0.1/192.168.2.249/g' ~/.kube/config
kubectl get nodes
```

### Step 4: Join Additional Control Plane Nodes (**on raspi5**)

```bash
# Join via VIP (not node IP!)
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=stable sh -s - server \
  --server https://192.168.2.249:6443 \
  --token <token-from-step-1> \
  --tls-san 192.168.2.249 \
  --tls-san raspi5 \
  --tls-san 192.168.2.9 \
  --disable traefik \
  --write-kubeconfig-mode 644
```

### Step 4.5: Join Worker Nodes with Longhorn Storage (**on k3s-worker-1**)

**Prerequisites:**

- Second disk installed (e.g., 2TB NVMe for Longhorn storage)
- Static IP configured via DHCP reservation in router

**1. Install system essentials:**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git vim htop net-tools iptables qemu-guest-agent
sudo systemctl start qemu-guest-agent
```

**2. Prepare second disk for Longhorn:**

```bash
# Identify disk (usually /dev/sdb for second disk)
lsblk

# Format disk with ext4
sudo mkfs.ext4 -L longhorn-storage /dev/sdb

# Create Longhorn mountpoint
sudo mkdir -p /var/lib/longhorn

# Get UUID for permanent mounting
sudo blkid /dev/sdb

# Add to fstab (replace <uuid> with actual UUID from blkid)
echo "UUID=<uuid> /var/lib/longhorn ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab

# Mount and verify
sudo mount -a
df -h /var/lib/longhorn
```

**3. Join as K3s worker:**

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.2.249:6443 \
  K3S_TOKEN=<token-from-step-1> \
  sh -
```

⚠️ **For Multipass VMs with multiple network interfaces:**

If the VM has both a NAT interface (e.g., 192.168.64.x) and a bridged interface (e.g., 192.168.2.x), explicitly specify the correct interface:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.2.249:6443 \
  K3S_TOKEN=<token-from-step-1> \
  INSTALL_K3S_EXEC="--node-ip=<bridged-ip> --flannel-iface=ens4" \
  sh -
```

Replace `<bridged-ip>` with the IP from your cluster network (e.g., 192.168.2.x) and adjust `ens4` to match your bridged interface name (check with `ip addr show`).

**4. Label node as worker (from your laptop):**

```bash
kubectl label node k3s-worker-1 node-role.kubernetes.io/worker=worker
```

**5. Verify Longhorn detects storage:**

```bash
# From your laptop
kubectl get nodes
kubectl get pods -n longhorn-system -o wide | grep k3s-worker-1

# Check Longhorn UI (http://longhorn.elmstreet79.de)
# Node → k3s-worker-1 → should show full disk capacity
```

⚠️ **Note:** Longhorn automatically detects `/var/lib/longhorn` - no additional configuration needed!

### Step 5: Install ArgoCD via Helm (**on your laptop**)

⚠️ **ArgoCD is NOT managed via GitOps** (prevents self-management conflicts)

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install with your domain
# Note: Installs latest version (no --version flag)
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set global.domain=argocd.elmstreet79.de \
  --set configs.cm.url=https://argocd.elmstreet79.de \
  --set 'configs.params.server\.insecure'=true

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

**Why `server.insecure=true`?**

- ArgoCD runs on HTTP internally
- Traefik terminates TLS
- Prevents redirect loops

**Note:** If you changed the domain in Step 5, update the Helm values accordingly.

### Step 6: Fork & Configure Repository (**on your laptop**)

```bash
# Fork https://github.com/Nebu2k/kubernetes-homelab
git clone https://github.com/YOUR_USERNAME/kubernetes-homelab
cd kubernetes-homelab

# Install Git hooks (enables auto-README regeneration on commit)
.githooks/install.sh
```

**⚙️ Configure for your environment:**

> ⚠️ **Warning:** The repository is pre-configured for `elmstreet79.de`. If using your own domain, update:

1. **MetalLB IP Pool** (adjust to your network):

   ```bash
   vim manifests/metallb/metallb-ip-pool.yaml
   # Change: 192.168.2.250-192.168.2.253
   ```

2. **Cert-Manager Email**:

   ```bash
   vim manifests/cert-manager/cluster-issuer.yaml
   # Change: certs@elmstreet79.de
   ```

3. **Cloudflare API Token** (required):

   ```bash
   # Create from example
   cp manifests/cert-manager/cloudflare-token-unsealed.yaml.example \
      manifests/cert-manager/cloudflare-token-unsealed.yaml
   
   # Add your Cloudflare API token
   vim manifests/cert-manager/cloudflare-token-unsealed.yaml
   # Change: api-token: "your-cloudflare-api-token-here"
   
   # Note: Sealing happens AFTER cluster bootstrap (Step 7+)
   # For now, keep it unsealed locally (gitignored)
   ```

   **Generate secure passwords/keys:**

   ```bash
   # Generate a secure password (32 bytes, base64 encoded)
   openssl rand -base64 32
   
   # Generate a longer encryption key (64 bytes, base64 encoded)
   openssl rand -base64 64
   ```

4. **Longhorn S3 Backup** (optional):

   ```bash
   # Create from example
   cp manifests/longhorn/s3-secret-unsealed.yaml.example \
      manifests/longhorn/s3-secret-unsealed.yaml
   
   # Update MinIO/S3 credentials
   vim manifests/longhorn/s3-secret-unsealed.yaml
   # Change: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ENDPOINTS
   
   # Note: Sealing happens AFTER cluster bootstrap (Step 7+)
   # For now, keep it unsealed locally (gitignored)
   ```

   ⚠️ **Note:** `*-unsealed.yaml` files are gitignored for security. Only `.example` templates are committed.

5. **Traefik Dashboard Domain** (required if using different domain):

   The Traefik dashboard is configured in the Helm values file:

   ```bash
   vim manifests/traefik/values.yaml
   # Update line 45: matchRule: Host(`traefik.your-domain.com`)
   # Update annotations with your domain
   ```

6. **Cloudflare DNS Sync Configuration** (optional - adjust DynDNS target):

   If you want to change the DynDNS target for public DNS records:

   ```bash
   vim manifests/cert-manager/cloudflare-dns-sync-configmap.yaml
   # Update TARGET to your DynDNS hostname (e.g., your-hostname.ipv64.net)
   # Update ZONE_ID to your Cloudflare Zone ID
   ```

   **Get Cloudflare Zone ID** (if needed):
   - Cloudflare Dashboard → Your Domain → Overview (right sidebar)

**Commit and push:**

```bash
git add -A
git commit -m "Configure for my environment"
git push
```

### Step 7: Bootstrap GitOps (**on your laptop**)

```bash
# Deploy App-of-Apps
kubectl apply -f bootstrap/root-app.yaml

# Watch ArgoCD deploy everything (~5-10 minutes)
kubectl get applications -n argocd -w
```

**What happens:**

- Sealed Secrets Controller installs first (Sync-Wave 0)
- MetalLB, Cert-Manager, Traefik, etc. follow in order
- Some apps will stay "Progressing" until secrets are sealed (next step)

### Step 7.5: Seal Secrets (**on your laptop** - AFTER Step 7)

⚠️ **Wait until Sealed Secrets Controller is ready:**

```bash
# Check if controller is running
kubectl wait --for=condition=available --timeout=300s \
  deployment/sealed-secrets-controller -n kube-system
```

**Option A: Download public certificate for offline sealing (Recommended)**

This allows you to seal secrets even when not connected to the cluster:

```bash
# Download the public certificate (one-time setup)
kubeseal --fetch-cert --controller-namespace=kube-system > sealed-secrets-pub-cert.pem

# Now seal your secrets offline using the certificate
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/cert-manager/cloudflare-token-unsealed.yaml \
  > manifests/cert-manager/cloudflare-token-sealed.yaml

# Seal AdGuard credentials for DNS sync:
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/private-services/adguard-credentials-unsealed.yaml \
  > manifests/private-services/adguard-credentials-sealed.yaml

# If using Longhorn S3 backup:
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/longhorn/s3-secret-unsealed.yaml \
  > manifests/longhorn/s3-secret-sealed.yaml
```

**Option B: Seal directly from cluster** (requires cluster access):

```bash
# Seal your secrets (must be connected to cluster)
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/cert-manager/cloudflare-token-unsealed.yaml \
  > manifests/cert-manager/cloudflare-token-sealed.yaml

# Seal AdGuard credentials for DNS sync:
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/private-services/adguard-credentials-unsealed.yaml \
  > manifests/private-services/adguard-credentials-sealed.yaml

# If using Longhorn S3 backup:
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/longhorn/s3-secret-unsealed.yaml \
  > manifests/longhorn/s3-secret-sealed.yaml
```

**Commit and deploy:**

```bash
# Commit and push
git add manifests/*/kustomization.yaml
git add manifests/*/*-sealed.yaml
git commit -m "🔐 Add sealed secrets"
git push

# ArgoCD will auto-sync and apply the secrets
kubectl get applications -n argocd -w
```

⚠️ **Note:** The public certificate (`sealed-secrets-pub-cert.pem`) is cluster-specific. If you rebuild the cluster or reinstall Sealed Secrets, you'll need to fetch a new certificate. The certificate file is gitignored for security.

### Step 7.6: Configure Homepage Widgets (**on your laptop** - AFTER Grafana is ready)

**Create sealed secrets for Homepage widgets:**

⚠️ **Important:** For each widget secret, copy the example file, edit with your credentials, then seal it.

```bash

# 1. Adguard Credentials
cp manifests/homepage/adguard-credentials-unsealed.yaml.example \
   manifests/homepage/adguard-credentials-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/adguard-credentials-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/adguard-credentials-unsealed.yaml \
  > manifests/homepage/adguard-credentials-sealed.yaml


# 2. Argocd Token Secret
cp manifests/homepage/argocd-token-secret-unsealed.yaml.example \
   manifests/homepage/argocd-token-secret-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/argocd-token-secret-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/argocd-token-secret-unsealed.yaml \
  > manifests/homepage/argocd-token-secret-sealed.yaml


# 3. Grafana Credentials
cp manifests/homepage/grafana-credentials-unsealed.yaml.example \
   manifests/homepage/grafana-credentials-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/grafana-credentials-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/grafana-credentials-unsealed.yaml \
  > manifests/homepage/grafana-credentials-sealed.yaml


# 4. Nextcloud Token
cp manifests/homepage/nextcloud-token-unsealed.yaml.example \
   manifests/homepage/nextcloud-token-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/nextcloud-token-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/nextcloud-token-unsealed.yaml \
  > manifests/homepage/nextcloud-token-sealed.yaml


# 5. Plex Token
cp manifests/homepage/plex-token-unsealed.yaml.example \
   manifests/homepage/plex-token-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/plex-token-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/plex-token-unsealed.yaml \
  > manifests/homepage/plex-token-sealed.yaml


# 6. Portainer Token
cp manifests/homepage/portainer-token-unsealed.yaml.example \
   manifests/homepage/portainer-token-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/portainer-token-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/portainer-token-unsealed.yaml \
  > manifests/homepage/portainer-token-sealed.yaml


# 7. Proxmox Secret
cp manifests/homepage/proxmox-secret-unsealed.yaml.example \
   manifests/homepage/proxmox-secret-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/proxmox-secret-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/proxmox-secret-unsealed.yaml \
  > manifests/homepage/proxmox-secret-sealed.yaml


# 8. Unifi Token
cp manifests/homepage/unifi-token-unsealed.yaml.example \
   manifests/homepage/unifi-token-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/unifi-token-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/unifi-token-unsealed.yaml \
  > manifests/homepage/unifi-token-sealed.yaml


# Commit and push
git add manifests/homepage/*-sealed.yaml
git commit -m "Add Homepage widget credentials"
git push
```

⚠️ **Note:** If you rebuild the cluster, passwords may change (e.g., Grafana admin password), so you'll need to recreate the affected sealed secrets.

### Step 8: Verify Deployment (**on your laptop**)

```bash
# All apps should be Synced + Healthy
kubectl get applications -n argocd

# MetalLB assigned LoadBalancer IP
kubectl get svc -n traefik
# EXTERNAL-IP should show 192.168.2.250

# Certificates issued (takes 2-5 min for DNS-01)
kubectl get certificate -A
# All should show READY=True

# Ingresses configured
kubectl get ingress -A
```

### Step 9: Access UIs (**from your laptop browser**)

⚠️ **DNS Records**: All public DNS records (HTTPS services) are **automatically created** by the Cloudflare DNS Sync job after deployment! No manual DNS configuration needed.

**ArgoCD:**

```text
URL: https://argocd.elmstreet79.de
User: admin
Pass: <from-step-5>
```

⚠️ **Change password immediately!**

1. User Info → Update Password
2. Then delete initial secret:

```bash
kubectl -n argocd delete secret argocd-initial-admin-secret
```

**Portainer:**

```text
URL: https://portainer.elmstreet79.de
```

⚠️ **Create admin account within 5 minutes!**

If timeout, restart the pod:

```bash
kubectl delete pod -n portainer -l app.kubernetes.io/name=portainer
```

**Longhorn:**

```text
URL: http://longhorn.elmstreet79.de
(Internal DNS only, managed by AdGuard DNS Sync)
```

**Homepage (Homelab Dashboard):**

```text
URL: https://home.elmstreet79.de
```

🏠 **Features:** Unified dashboard with links to all services, real-time Kubernetes cluster metrics, auto-discovery of ingresses, dark theme, widgets for Proxmox/ArgoCD/Grafana

**Uptime Kuma (Uptime Monitoring):**

```text
URL: https://uptime.elmstreet79.de
```

⚠️ **First visit:** Create admin account on initial access. Then add monitors for your services.

**Private Services:**

Private Services provide internal DNS names for services running outside Kubernetes (e.g., Docker containers on Raspberry Pis) without exposing them publicly. This architecture uses:

1. **Internal DNS Names**: Services accessible via `*.elmstreet79.de` only within the local network
2. **Automated DNS Management**: PostSync Hook + CronJob automatically sync Kubernetes Ingresses to AdGuard Home DNS Rewrites
3. **Single Source of Truth**: AdGuard Home manages all internal DNS rewrites, CoreDNS forwards queries to AdGuard
4. **No Public SSL**: Internal services use HTTP only (no cert-manager annotations)

**Architecture:**

```text
External Service → Kubernetes Service (ClusterIP) → Manual Endpoints → External IP:Port
                ↓
            IngressRoute → Traefik LoadBalancer (192.168.2.250)
                ↓
            AdGuard DNS Sync Job → AdGuard API → DNS Rewrite (*.elmstreet79.de → 192.168.2.250)
                ↓
            CoreDNS → Forward *.elmstreet79.de → AdGuard DNS (192.168.2.2, 192.168.2.4)
```

**Examples:**

```text
AdGuard Home: http://adguard.elmstreet79.de → 192.168.2.2:8080
Beszel Monitor: http://beszel.elmstreet79.de → 192.168.2.9:8090
MinIO Console: http://minio.elmstreet79.de → 192.168.2.9:9393
MinIO API: http://minio-api.elmstreet79.de → 192.168.2.9:9300
Longhorn: http://longhorn.elmstreet79.de → Internal K8s service
```

**AdGuard DNS Sync Automation:**

- **PostSync Hook**: Runs automatically after every ArgoCD sync
- **Filter Logic**: Only syncs Ingresses WITHOUT `cert-manager.io/cluster-issuer` annotation
- **AdGuard API**: Creates/updates/deletes DNS Rewrites pointing to Traefik LoadBalancer IP (192.168.2.250)
- **Auto-Cleanup**: Removes orphaned DNS entries when Ingresses are deleted

**Public Services with SSL:**

Public services (accessible from the internet) use a separate DNS sync system:

**Cloudflare DNS Sync Automation:**

- **PostSync Hook**: Runs automatically after every ArgoCD sync
- **CronJob**: Fallback every 6 hours
- **Filter Logic**: Only syncs Ingresses WITH `cert-manager.io/cluster-issuer` annotation
- **Cloudflare API**: Creates/updates/deletes CNAME records pointing to DynDNS target (e.g., `nebu2k.ipv64.net`)
- **Auto-Cleanup**: Removes orphaned DNS records when Ingresses are deleted
- **Let's Encrypt**: Cert-Manager automatically provisions SSL certificates via DNS-01 challenge

**Examples:**

```text
TeslaLogger: https://teslalogger.elmstreet79.de (→ 192.168.2.9:3000)
Dreambox: https://dreambox.elmstreet79.de (→ 192.168.2.11:80)
(External services routed via Traefik IngressRoute with TLS)
```

### Internal CA for Private Services

The cluster includes an **Internal Certificate Authority** for issuing self-signed certificates to private services (services without public SSL certificates). This is automatically deployed via `private-services.yaml` (Sync-Wave 16).

**Architecture:**

1. **Self-Signed CA**: Created by cert-manager in `cert-manager` namespace
2. **Internal ClusterIssuer**: Issues certificates for internal services
3. **Automatic Distribution**: CronJob copies CA certificate to `homepage` namespace every 12 hours
4. **Use Case**: Homepage can trust internal services with self-signed certificates

**Trust Internal CA on your laptop** (for accessing internal HTTPS services without browser warnings):

```bash
# Export the CA certificate from the cluster
kubectl get secret internal-ca-secret -n cert-manager \
  -o jsonpath='{.data.ca\.crt}' | base64 -d > internal-ca.crt

# macOS: Add to system keychain and trust
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain internal-ca.crt

# Linux: Add to trusted certificates
sudo cp internal-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Windows: Import via certmgr.msc
# Double-click internal-ca.crt → Install Certificate → Local Machine → 
# Place in "Trusted Root Certification Authorities"
```

⚠️ **Note:** After adding the CA certificate, restart your browser to apply the changes.

**Verify CA is working:**

```bash
# Check if internal-ca certificate exists
kubectl get certificate internal-ca -n cert-manager

# Check if ClusterIssuer is ready
kubectl get clusterissuer internal-ca-issuer
```

## 🔧 Management

### View Application Status

```bash
kubectl get applications -n argocd
kubectl describe application <app-name> -n argocd
```

### Update Component

```bash
# Check for latest Helm chart version
helm repo update
helm search repo <chart-name> --versions | head -n 5

# Example: Check traefik latest version
helm search repo traefik/traefik --versions | head -n 5

# Edit Helm values
vim manifests/traefik/values.yaml

# Commit and push - ArgoCD auto-syncs
git add manifests/traefik/values.yaml
git commit -m "Update Traefik to 2 replicas"
git push

# Watch sync
kubectl get application traefik -n argocd -w
```

### Update Secrets

```bash
# 1. Edit unsealed secret
vim manifests/cert-manager/cloudflare-token-unsealed.yaml

# 2. Re-seal (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/cert-manager/cloudflare-token-unsealed.yaml \
  > manifests/cert-manager/cloudflare-token-sealed.yaml

# 3. Commit and push
git add manifests/cert-manager/cloudflare-token-sealed.yaml
git commit -m "Rotate Cloudflare token"
git push
```

**Alternative: Seal directly from cluster** (if you don't have the certificate):

```bash
# Re-seal (requires cluster connection)
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/cert-manager/cloudflare-token-unsealed.yaml \
  > manifests/cert-manager/cloudflare-token-sealed.yaml
```

### Force Sync Application

```bash
# Via kubectl
kubectl patch application <app-name> -n argocd --type merge \
  -p '{"operation":{"initiatedBy":{"username":"manual"}}}'

# Via ArgoCD CLI
argocd app sync <app-name>
```

### Hard Refresh Application

Sometimes ArgoCD needs a complete reset (e.g., stuck state, CRD issues):

```bash
# Delete and re-create the ArgoCD Application (doesn't delete K8s resources)
kubectl delete application <app-name> -n argocd && sleep 2 && \
  kubectl apply -f apps/<app-name>.yaml

# Example: Hard refresh Longhorn
kubectl delete application longhorn -n argocd && sleep 2 && \
  kubectl apply -f apps/longhorn.yaml
```

**Note:** This only resets the ArgoCD Application object, not the actual Kubernetes resources. Useful for clearing stuck sync states or comparison errors.

## 🐛 Troubleshooting

### MetalLB Not Assigning IPs

**Check:**

```bash
kubectl logs -n metallb-system -l app.kubernetes.io/component=speaker
```

**Should NOT show:**

```text
"error":"assigned IP not allowed by config"
```

**Fix:** Ensure L2Advertisement exists in `manifests/metallb/metallb-ip-pool.yaml`

### Certificates Not Ready

**Check status:**

```bash
kubectl describe certificate <name> -n <namespace>
kubectl get challenge -A
```

**Common issues:**

1. Cloudflare secret not sealed correctly
2. DNS-01 challenge takes 2-5 minutes (normal)
3. Cert-Manager webhook TLS error (delete webhook pod to restart)

**Fix webhook:**

```bash
kubectl delete pod -n cert-manager -l app.kubernetes.io/name=webhook
```

### ArgoCD App OutOfSync

**Check:**

```bash
kubectl describe application <app-name> -n argocd
kubectl logs -n argocd deployment/argocd-application-controller
```

**Force refresh:**

```bash
argocd app sync <app-name> --force
```

### Grafana Widget Not Showing on Homepage

**Check:**

```bash
# 1. Verify Homepage has the environment variables
kubectl get deployment homepage -n homepage -o yaml | grep -E "GRAFANA_(USERNAME|PASSWORD)"

# 2. Check if secret exists and has correct fields
kubectl get secret homepage-grafana -n homepage -o yaml

# 3. Check Homepage logs
kubectl logs -n homepage deployment/homepage

# 4. Verify credentials are set correctly
kubectl get secret homepage-grafana -n homepage -o yaml
```

**Fix if credentials are invalid:**

Re-create the sealed secret as described in Step 7.6.

### Unseal a Sealed Secret (for debugging)

If you need to view the decrypted content of a sealed secret:

```bash
# Get the sealed secret from the cluster
kubectl get sealedsecret <sealed-secret-name> -n <namespace> -o yaml > sealed.yaml

# The sealed secret will be automatically decrypted by the controller and stored as a regular Secret
# View the decrypted secret
kubectl get secret <secret-name> -n <namespace> -o yaml

# Decode a specific field (e.g., password)
kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.password}' | base64 -d

# Example: View Grafana admin password
kubectl get secret -n monitoring grafana-admin-credentials \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo
```

⚠️ **Note:** You cannot "unseal" the encrypted data in the SealedSecret YAML file without access to the cluster's private key. The Sealed Secrets controller automatically decrypts SealedSecrets into regular Secrets when applied to the cluster.

## 📚 Components

| Component | Version | Purpose |
|-----------|---------|---------|
| Reloader | 2.2.7 | Reloader |
| Kube Prometheus Stack | 80.11.0 | Kube Prometheus Stack |
| Sealed Secrets | 2.18.0 | Sealed Secrets |
| Kured | 5.10.0 | Kured |
| Metallb | 0.15.3 | Metallb |
| Longhorn | 1.10.1 | Longhorn |
| Portainer | 2.33.6 | Portainer |
| Cert Manager | v1.19.2 | Cert Manager |
| Traefik | 38.0.1 | Traefik |
| Newt | 1.1.0 | Newt |
| K3s | v1.33.5 | Lightweight Kubernetes |
| Kube-VIP | v1.0.1 | Control plane HA |

## 📖 Documentation

- [Cert Manager](https://charts.jetstack.io)
- [K3s](https://docs.k3s.io/)
- [Kube Prometheus Stack](https://prometheus-community.github.io/helm-charts)
- [Kured](https://kubereboot.github.io/charts)
- [Longhorn](https://charts.longhorn.io)
- [Metallb](https://metallb.github.io/metallb)
- [Newt](https://charts.fossorial.io)
- [Portainer](https://portainer.github.io/k8s)
- [Reloader](https://stakater.github.io/stakater-charts)
- [Sealed Secrets](https://bitnami-labs.github.io/sealed-secrets)
- [Traefik](https://traefik.github.io/charts)

## 📝 License

MIT

---

> 🤖 **This README is auto-generated** using `docs-generator/generate_readme.py`  
> To regenerate manually: `make docs`  
> Auto-generation on commit: Enabled via `.githooks/pre-commit` (run `.githooks/install.sh` after clone)
