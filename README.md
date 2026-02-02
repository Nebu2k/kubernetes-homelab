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
| 2 | Pangolin Sync |
| 3 | Traefik |
| 4 | Longhorn |
| 5 | Landing Page, Portainer, Teslamate, Nfs Storage |
| 6 | Kube Prometheus Stack |
| 7 | Unifi Poller, Home Assistant |
| 8 | Uptime Kuma, Newt |
| 9 | N8n, Paperless Ngx, Homepage |
| 10 | Beszel |
| 11 | Proxmox Exporter |
| 12 | Argocd Config |
| 15 | Fr24 |
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
│   ├── pangolin-sync.yaml             # Wave 2
│   ├── traefik.yaml                   # Wave 3
│   ├── longhorn.yaml                  # Wave 4
│   ├── landing-page.yaml              # Wave 5
│   ├── nfs-storage.yaml               # Wave 5
│   ├── portainer.yaml                 # Wave 5
│   ├── teslamate.yaml                 # Wave 5
│   ├── kube-prometheus-stack.yaml     # Wave 6
│   ├── home-assistant.yaml            # Wave 7
│   ├── unifi-poller.yaml              # Wave 7
│   ├── newt.yaml                      # Wave 8
│   ├── uptime-kuma.yaml               # Wave 8
│   ├── homepage.yaml                  # Wave 9
│   ├── n8n.yaml                       # Wave 9
│   ├── paperless-ngx.yaml             # Wave 9
│   ├── beszel.yaml                    # Wave 10
│   ├── proxmox-exporter.yaml          # Wave 11
│   ├── argocd-config.yaml             # Wave 12
│   ├── fr24.yaml                      # Wave 15
│   └── private-services.yaml          # Wave 16
└── manifests/
    ├── argocd/
    │   ├── argocd-cm-patch.yaml
    │   ├── argocd-rbac-cm-patch.yaml
    │   ├── argocd-server-patch.yaml
    │   ├── ingress.yaml
    │   └── kustomization.yaml
    ├── beszel/
    │   ├── agent-daemonset.yaml
    │   ├── deployment.yaml
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   ├── pvc.yaml
    │   ├── secret-sealed.yaml
    │   ├── secret-unsealed.yaml.example
    │   └── service.yaml
    ├── coredns/
    │   ├── coredns-custom.yaml
    │   └── kustomization.yaml
    ├── fr24/
    │   ├── deployment.yaml
    │   ├── fr24-secret-sealed.yaml
    │   ├── fr24-secret-unsealed.yaml.example
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   └── service.yaml
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
    │   ├── adguard-credentials-unsealed.yaml.example
    │   ├── argocd-token-secret-sealed.yaml
    │   ├── argocd-token-secret-unsealed.yaml.example
    │   ├── beszel-secret-sealed.yaml
    │   ├── beszel-secret-unsealed.yaml.example
    │   ├── clusterrole.yaml
    │   ├── clusterrolebinding.yaml
    │   ├── configmap.yaml
    │   ├── deployment.yaml
    │   ├── grafana-credentials-sealed.yaml
    │   ├── grafana-credentials-unsealed.yaml.example
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   ├── nextcloud-token-sealed.yaml
    │   ├── nextcloud-token-unsealed.yaml.example
    │   ├── plex-token-sealed.yaml
    │   ├── plex-token-unsealed.yaml.example
    │   ├── portainer-token-sealed.yaml
    │   ├── portainer-token-unsealed.yaml.example
    │   ├── proxmox-secret-sealed.yaml
    │   ├── proxmox-secret-unsealed.yaml.example
    │   ├── service.yaml
    │   ├── serviceaccount.yaml
    │   ├── unifi-token-sealed.yaml
    │   └── unifi-token-unsealed.yaml.example
    ├── kube-prometheus-stack/
    │   ├── alertmanager-ingress.yaml
    │   ├── aws-credentials-sealed.yaml
    │   ├── aws-credentials-unsealed.yaml.example
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
    │   ├── minio-secret-sealed.yaml
    │   ├── minio-secret-unsealed.yaml.example
    │   ├── node-config.yaml
    │   ├── recurring-backup-jobs.yaml
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
    │   ├── postgresql-secret-unsealed.yaml.example
    │   ├── postgresql-service.yaml
    │   ├── postgresql-statefulset.yaml
    │   ├── pvc.yaml
    │   └── service.yaml
    ├── newt/
    │   ├── kustomization.yaml
    │   ├── newt-auth-sealed.yaml
    │   ├── newt-auth-unsealed.yaml.example
    │   └── values.yaml
    ├── nfs-subdir-external-provisioner/
    │   └── values.yaml
    ├── pangolin-sync/
    │   ├── kustomization.yaml
    │   ├── pangolin-api-credentials-sealed.yaml
    │   ├── pangolin-api-credentials-unsealed.yaml.example
    │   ├── pangolin-sync-job.yaml
    │   ├── pangolin-sync-rbac.yaml
    │   └── values.yaml
    ├── paperless-ngx/
    │   ├── backup-cronjob.yaml
    │   ├── db-pvc.yaml
    │   ├── deployment.yaml
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   ├── paperless-secrets-sealed.yaml
    │   ├── paperless-secrets-unsealed.yaml.example
    │   ├── postgresql.yaml
    │   ├── pvc.yaml
    │   ├── redis.yaml
    │   ├── s3-backup-credentials-sealed.yaml
    │   ├── s3-backup-credentials-unsealed.yaml.example
    │   ├── service.yaml
    │   ├── smb-credentials-sealed.yaml
    │   └── smb-credentials-unsealed.yaml.example
    ├── portainer/
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   ├── servers-transport.yaml
    │   └── values.yaml
    ├── private-services/
    │   ├── adguard-macmini-service.yaml
    │   ├── adguard-pve-service.yaml
    │   ├── adguardhome-sync-config.yaml
    │   ├── adguardhome-sync-credentials-sealed.yaml
    │   ├── adguardhome-sync-deployment.yaml
    │   ├── adguardhome-sync-service.yaml
    │   ├── dreambox-service.yaml
    │   ├── glances-macmini-service.yaml
    │   ├── kustomization.yaml
    │   ├── minio-api-service.yaml
    │   ├── minio-service.yaml
    │   ├── nextcloud-service.yaml
    │   ├── plex-service.yaml
    │   ├── proxmox-service.yaml
    │   ├── unifi-nas-service.yaml
    │   ├── unifi-service.yaml
    │   └── vscode-service.yaml
    ├── proxmox-exporter/
    │   ├── deployment.yaml
    │   ├── kustomization.yaml
    │   ├── pve-api-credentials-sealed.yaml
    │   ├── pve-api-credentials-unsealed.yaml.example
    │   ├── service.yaml
    │   └── servicemonitor.yaml
    ├── reloader/
    │   └── values.yaml
    ├── teslamate/
    │   ├── database-deployment.yaml
    │   ├── database-pdb.yaml
    │   ├── database-pvc.yaml
    │   ├── database-service.yaml
    │   ├── grafana-deployment.yaml
    │   ├── grafana-ingress.yaml
    │   ├── grafana-pvc.yaml
    │   ├── grafana-service.yaml
    │   ├── kustomization.yaml
    │   ├── mosquitto-deployment.yaml
    │   ├── mosquitto-pvc.yaml
    │   ├── mosquitto-service.yaml
    │   ├── namespace.yaml
    │   ├── teslamate-deployment.yaml
    │   ├── teslamate-ingress.yaml
    │   ├── teslamate-secret-sealed.yaml
    │   ├── teslamate-secret-unsealed.yaml.example
    │   └── teslamate-service.yaml
    ├── traefik/
    │   ├── dashboard-service.yaml
    │   ├── kustomization.yaml
    │   └── values.yaml
    ├── unifi-poller/
    │   ├── deployment.yaml
    │   ├── kustomization.yaml
    │   ├── service.yaml
    │   ├── servicemonitor.yaml
    │   ├── unifi-config-sealed.yaml
    │   └── unifi-config-unsealed.yaml.example
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
- Domain (any DNS provider)
- Pangolin API credentials (for SSL/TLS certificates)
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

2. **Pangolin API Credentials** (required):

   ```bash
   # Create from example
   cp manifests/pangolin-sync/pangolin-api-credentials-unsealed.yaml.example \
      manifests/pangolin-sync/pangolin-api-credentials-unsealed.yaml
   
   # Add your Pangolin API credentials
   vim manifests/pangolin-sync/pangolin-api-credentials-unsealed.yaml
   # Update: API_KEY, ORG_ID, SITE_ID, DOMAIN_ID, DOMAIN_SUFFIX
   
   # Note: Sealing happens AFTER cluster bootstrap (Step 7+)
   # For now, keep it unsealed locally (gitignored)
   ```

3. **Longhorn S3 Backup** (optional):

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

4. **Traefik Dashboard Domain** (required if using different domain):

   The Traefik dashboard is configured in the Helm values file:

   ```bash
   vim manifests/traefik/values.yaml
   # Update line 45: matchRule: Host(`traefik.your-domain.com`)
   # Update annotations with your domain
   ```

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
- MetalLB, Pangolin, Traefik, etc. follow in order
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

# Seal Pangolin API credentials
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/pangolin-sync/pangolin-api-credentials-unsealed.yaml \
  > manifests/pangolin-sync/pangolin-api-credentials-sealed.yaml

# If using Longhorn S3 backup:
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/longhorn/minio-secret-unsealed.yaml \
  > manifests/longhorn/minio-secret-sealed.yaml
```

**Option B: Seal directly from cluster** (requires cluster access):

```bash
# Seal Pangolin API credentials
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/pangolin-sync/pangolin-api-credentials-unsealed.yaml \
  > manifests/pangolin-sync/pangolin-api-credentials-sealed.yaml

# If using Longhorn S3 backup:
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/longhorn/minio-secret-unsealed.yaml \
  > manifests/longhorn/minio-secret-sealed.yaml
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


# 3. Beszel Secret
cp manifests/homepage/beszel-secret-unsealed.yaml.example \
   manifests/homepage/beszel-secret-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/beszel-secret-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/beszel-secret-unsealed.yaml \
  > manifests/homepage/beszel-secret-sealed.yaml


# 4. Grafana Credentials
cp manifests/homepage/grafana-credentials-unsealed.yaml.example \
   manifests/homepage/grafana-credentials-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/grafana-credentials-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/grafana-credentials-unsealed.yaml \
  > manifests/homepage/grafana-credentials-sealed.yaml


# 5. Nextcloud Token
cp manifests/homepage/nextcloud-token-unsealed.yaml.example \
   manifests/homepage/nextcloud-token-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/nextcloud-token-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/nextcloud-token-unsealed.yaml \
  > manifests/homepage/nextcloud-token-sealed.yaml


# 6. Plex Token
cp manifests/homepage/plex-token-unsealed.yaml.example \
   manifests/homepage/plex-token-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/plex-token-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/plex-token-unsealed.yaml \
  > manifests/homepage/plex-token-sealed.yaml


# 7. Portainer Token
cp manifests/homepage/portainer-token-unsealed.yaml.example \
   manifests/homepage/portainer-token-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/portainer-token-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/portainer-token-unsealed.yaml \
  > manifests/homepage/portainer-token-sealed.yaml


# 8. Proxmox Secret
cp manifests/homepage/proxmox-secret-unsealed.yaml.example \
   manifests/homepage/proxmox-secret-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/proxmox-secret-unsealed.yaml

# Seal the secret (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/homepage/proxmox-secret-unsealed.yaml \
  > manifests/homepage/proxmox-secret-sealed.yaml


# 9. Unifi Token
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

# Ingresses configured
kubectl get ingress -A
```

### Step 9: Access UIs (**from your laptop browser**)

⚠️ **All Services**: Services annotated with `pangolin.io/expose: "true"` are automatically registered in Pangolin for external HTTPS access with SSL certificates!

- **With Authentication**: Services with `pangolin.io/auth: "true"` require Pangolin authentication
- **Without Authentication**: Services without auth annotation are directly accessible from the internet

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
URL: https://longhorn.elmstreet79.de
(via Pangolin)
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

**Service Access Architecture:**

All services are accessible via Pangolin's secure network infrastructure:

**Pangolin-Exposed Services:**

- **Filter Logic**: Ingresses/Services WITH `pangolin.io/expose: "true"` annotation
- **Access**: Publicly accessible from the internet with automatic SSL/TLS certificates
- **Authentication**:
  - `pangolin.io/auth: "true"` → Requires Pangolin authentication (secure, private access)
  - `pangolin.io/auth: "false"` or no auth annotation → Directly accessible without authentication

**Pangolin Sync Automation:**

- **PostSync Hook**: Runs automatically after every ArgoCD sync
- **CronJob**: Fallback every 5 minutes
- **Pangolin API**: Registers resources in Pangolin network for secure external access
- **Auto-Cleanup**: Removes orphaned resources when Ingresses/Services are deleted
- **SSL/TLS**: Pangolin provides automatic SSL certificates for all exposed services

**All Pangolin-Exposed Services:**

```text
# Services with Pangolin authentication required (pangolin.io/auth: "true"):
Adguard Macmini: https://adguard-macmini.elmstreet79.de
Adguard Pve: https://adguard.elmstreet79.de
Adguardhome Sync: https://adguardhome-sync-web.elmstreet79.de
AlertManager: https://alertmanager.elmstreet79.de
ArgoCD: https://argocd.elmstreet79.de
Beszel Hub: https://beszel.elmstreet79.de
FlightRadar24: https://fr24.elmstreet79.de
Glances Macmini: https://glances-macmini.elmstreet79.de
Grafana: https://grafana.elmstreet79.de
Homepage: https://home.elmstreet79.de
Longhorn: https://longhorn.elmstreet79.de
Minio: https://minio.elmstreet79.de
Minio Api: https://minio-api.elmstreet79.de
Paperless-ngx: https://paperless.elmstreet79.de
Prometheus: https://prometheus.elmstreet79.de
Proxmox: https://pve.elmstreet79.de
TeslaMate Settings: https://teslamate-settings.elmstreet79.de
Traefik Dashboard: https://traefik.elmstreet79.de
Unifi: https://unifi.elmstreet79.de
Unifi Nas: https://nas.elmstreet79.de
Uptime Kuma: https://uptime.elmstreet79.de
Vscode: https://vscode.elmstreet79.de
n8n: https://n8n.elmstreet79.de

# Services publicly accessible without authentication (pangolin.io/auth: "false"):
Dreambox: https://dreambox.elmstreet79.de
Home Assistant: https://homeassistant.elmstreet79.de
Landing Page: https://www.elmstreet79.de
Nextcloud Aio: https://nextcloud.elmstreet79.de
Plex: https://plex.elmstreet79.de
TeslaMate Grafana: https://teslamate.elmstreet79.de

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
vim manifests/pangolin-sync/pangolin-api-credentials-unsealed.yaml

# 2. Re-seal (using offline certificate)
kubeseal --cert sealed-secrets-pub-cert.pem --format=yaml \
  < manifests/pangolin-sync/pangolin-api-credentials-unsealed.yaml \
  > manifests/pangolin-sync/pangolin-api-credentials-sealed.yaml

# 3. Commit and push
git add manifests/pangolin-sync/pangolin-api-credentials-sealed.yaml
git commit -m "Rotate Pangolin API credentials"
git push
```

**Alternative: Seal directly from cluster** (if you don't have the certificate):

```bash
# Re-seal (requires cluster connection)
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/pangolin-sync/pangolin-api-credentials-unsealed.yaml \
  > manifests/pangolin-sync/pangolin-api-credentials-sealed.yaml
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
| Kube Prometheus Stack | 80.13.2 | Kube Prometheus Stack |
| Sealed Secrets | 2.18.0 | Sealed Secrets |
| Proxmox Exporter | 1.0.8 | Proxmox Exporter |
| N8n | 2.4.4 | N8n |
| Landing Page | 1.29.4-alpine | Landing Page |
| Kured | 5.10.0 | Kured |
| Metallb | 0.15.3 | Metallb |
| Longhorn | 1.10.1 | Longhorn |
| Unifi Poller | v2.21.0 | Unifi Poller |
| Portainer | 2.33.6 | Portainer |
| Paperless Ngx | latest | Paperless Ngx |
| Uptime Kuma | 2.0.2 | Uptime Kuma |
| Traefik | 38.0.2 | Traefik |
| Fr24 | latest-build-825 | Fr24 |
| Newt | 1.1.0 | Newt |
| Teslamate | 2.2.0 | Teslamate |
| Home Assistant | 2026.1.2 | Home Assistant |
| Nfs Subdir External Provisioner | 4.0.18 | Nfs Storage |
| Homepage | v1.8.0 | Homepage |
| Beszel | 0.18.2 | Beszel |
| K3s | v1.33.5 | Lightweight Kubernetes |
| Kube-VIP | v1.0.1 | Control plane HA |
| ArgoCD | v3.2.3 | Continuous Delivery |

## 📖 Documentation

- [Home Assistant](https://www.home-assistant.io/docs/)
- [Homepage](https://gethomepage.dev/latest/)
- [K3s](https://docs.k3s.io/)
- [Kube Prometheus Stack](https://prometheus-community.github.io/helm-charts)
- [Kured](https://kubereboot.github.io/charts)
- [Landing Page](https://github.com/nginx/nginx)
- [Longhorn](https://charts.longhorn.io)
- [Metallb](https://metallb.github.io/metallb)
- [n8n](https://docs.n8n.io/)
- [Newt](https://charts.fossorial.io)
- [NFS Subdir External Provisioner](https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner)
- [Portainer](https://portainer.github.io/k8s)
- [Proxmox Exporter](https://github.com/prometheus-pve/prometheus-pve-exporter)
- [Reloader](https://stakater.github.io/stakater-charts)
- [Sealed Secrets](https://bitnami-labs.github.io/sealed-secrets)
- [Teslamate](https://docs.teslamate.org/)
- [Traefik](https://traefik.github.io/charts)
- [Unifi Poller](https://unpoller.com/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma/wiki)

## 📝 License

MIT

---

> 🤖 **This README is auto-generated** using `docs-generator/generate_readme.py`  
> To regenerate manually: `make docs`  
> Auto-generation on commit: Enabled via `.githooks/pre-commit` (run `.githooks/install.sh` after clone)
