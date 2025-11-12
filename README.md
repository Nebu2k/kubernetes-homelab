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

| Wave | Component | Purpose |
|------|-----------|---------|
| 0 | Sealed Secrets | Decrypt secrets |
| 1 | MetalLB, Reloader | LoadBalancer IPs + Auto-reload on config changes |
| 2 | Cert-Manager | TLS certificates |
| 3 | NGINX Ingress | HTTP(S) routing |
| 4 | Longhorn | Persistent storage |
| 5 | Portainer | Management UI |
| 6 | ntfy | Notification service |
| 7 | kube-prometheus-stack | Prometheus, Grafana, Alertmanager monitoring |
| 8 | Uptime Kuma | Uptime monitoring & status page |
| 10 | MetalLB Config, Cert-Manager Config | IPAddressPool, ClusterIssuers |
| 11 | NGINX Ingress Config | Custom headers |
| 12 | ArgoCD Config, Portainer Config | Management UI ingresses |
| 13 | Longhorn Config | Backup jobs, S3 config |
| 14 | ntfy Config | ntfy ingress |
| 15 | kube-prometheus-stack Config | Grafana, Prometheus, Alertmanager ingresses |
| 16 | Uptime Kuma Config, Private Services | Uptime Kuma ingress, External service ingresses |
| 20 | Demo App | Sample application |

## 📁 Repository Structure

```text
homelab/
├── bootstrap/
│   └── root-app.yaml              # App-of-Apps (deploys everything)
├── apps/
│   ├── kustomization.yaml         # List of all apps
│   ├── sealed-secrets.yaml        # Wave 0
│   ├── reloader.yaml              # Wave 1
│   ├── metallb.yaml               # Wave 1
│   ├── metallb-config.yaml        # Wave 10
│   ├── cert-manager.yaml          # Wave 2
│   ├── cert-manager-config.yaml   # Wave 10
│   ├── nginx-ingress.yaml         # Wave 3
│   ├── nginx-ingress-config.yaml  # Wave 11
│   ├── longhorn.yaml              # Wave 4
│   ├── longhorn-config.yaml       # Wave 13
│   ├── portainer.yaml             # Wave 5
│   ├── portainer-config.yaml      # Wave 12
│   ├── ntfy.yaml                  # Wave 6
│   ├── ntfy-config.yaml           # Wave 14
│   ├── uptime-kuma.yaml           # Wave 8
│   ├── uptime-kuma-config.yaml    # Wave 16
│   ├── kube-prometheus-stack.yaml       # Wave 7
│   ├── kube-prometheus-stack-config.yaml # Wave 15
│   ├── argocd-config.yaml         # Wave 12
│   ├── private-services.yaml      # Wave 16
│   └── demo-app.yaml              # Wave 20
├── base/
│   ├── reloader/values.yaml       # Auto-reload config
│   ├── metallb/values.yaml        # Generic Helm values
│   ├── cert-manager/values.yaml
│   ├── nginx-ingress/values.yaml
│   ├── longhorn/values.yaml
│   ├── portainer/values.yaml
│   ├── uptime-kuma/values.yaml    # Uptime monitoring
│   ├── kube-prometheus-stack/values.yaml  # Prometheus, Grafana, Alertmanager
│   └── ntfy/                      # Notification service
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── pvc.yaml
│       └── kustomization.yaml
└── overlays/production/
    ├── metallb/
    │   └── metallb-ip-pool.yaml   # IPAddressPool + L2Advertisement
    ├── cert-manager/
    │   ├── cluster-issuer.yaml    # Let's Encrypt issuers
    │   └── cloudflare-token-*.yaml
    ├── nginx-ingress/
    │   └── custom-headers.yaml    # Security headers ConfigMap
    ├── argocd/
    │   └── ingress.yaml           # ArgoCD HTTPS ingress
    ├── portainer/
    │   └── ingress.yaml           # Portainer HTTPS ingress
    ├── longhorn/
    │   └── s3-secret-*.yaml       # S3 backup credentials
    ├── ntfy/
    │   ├── configmap.yaml         # ntfy server config
    │   ├── ingress.yaml           # ntfy HTTPS ingress
    │   └── kustomization.yaml
    ├── kube-prometheus-stack/
    │   ├── grafana-admin-sealed.yaml    # Grafana admin credentials
    │   ├── ingress-grafana.yaml         # Grafana HTTPS ingress
    │   ├── ingress-prometheus.yaml      # Prometheus HTTPS ingress
    │   ├── ingress-alertmanager.yaml    # Alertmanager HTTPS ingress
    │   └── kustomization.yaml
    ├── uptime-kuma/
    │   ├── ingress.yaml           # Uptime Kuma HTTPS ingress
    │   └── kustomization.yaml
    └── private-services/
        ├── teslalogger-ingress.yaml  # TeslaLogger external service
        └── dreambox-ingress.yaml     # Dreambox external service
```

## 🚀 Fresh Installation

### Prerequisites

- 2+ nodes (Raspberry Pi or other)
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

**4. Verify Longhorn detects storage:**
```bash
# From your laptop
kubectl get nodes
kubectl get pods -n longhorn-system -o wide | grep k3s-worker-1

# Check Longhorn UI (http://<node-ip>:30080)
# Node → k3s-worker-1 → should show full disk capacity
```

⚠️ **Note:** Longhorn automatically detects `/var/lib/longhorn` - no additional configuration needed!

### Step 5: Install ArgoCD via Helm (**on your laptop**)

⚠️ **ArgoCD is NOT managed via GitOps** (prevents self-management conflicts)

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install with your domain (or use argocd.elmstreet79.de if keeping defaults)
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
- NGINX Ingress terminates TLS
- Prevents redirect loops

**Note:** If you changed the domain in Step 6, update the Helm values accordingly.

### Step 6: Fork & Configure Repository (**on your laptop**)

```bash
# Fork https://github.com/Nebu2k/kubernetes-homelab
git clone https://github.com/YOUR_USERNAME/kubernetes-homelab
cd kubernetes-homelab
```

**⚙️ Configure for your environment:**

The repository is pre-configured for `elmstreet79.de`. If using your own domain, update:

1. **MetalLB IP Pool** (adjust to your network):

   ```bash
   vim overlays/production/metallb/metallb-ip-pool.yaml
   # Change: 192.168.2.250-192.168.2.254
   ```

2. **Cert-Manager Email**:

   ```bash
   vim overlays/production/cert-manager/cluster-issuer.yaml
   # Change: certs@elmstreet79.de
   ```

3. **Cloudflare API Token** (required):

   ```bash
   # Create from example
   cp overlays/production/cert-manager/cloudflare-token-unsealed.yaml.example \
      overlays/production/cert-manager/cloudflare-token-unsealed.yaml
   
   # Add your Cloudflare API token
   vim overlays/production/cert-manager/cloudflare-token-unsealed.yaml
   # Change: api-token: "your-cloudflare-api-token-here"
   
   # Note: Sealing happens AFTER cluster bootstrap (Step 7+)
   # For now, keep it unsealed locally (gitignored)
   ```

4. **ArgoCD Ingress Domain**:

   ```bash
   vim overlays/production/argocd/ingress.yaml
   # Change: argocd.elmstreet79.de
   ```

5. **Portainer Ingress Domain**:

   ```bash
   vim overlays/production/portainer/ingress.yaml
   # Change: portainer.elmstreet79.de
   ```

6. **Longhorn S3 Backup** (optional):

   ```bash
   # Create from example
   cp overlays/production/longhorn/s3-secret-unsealed.yaml.example \
      overlays/production/longhorn/s3-secret-unsealed.yaml
   
   # Update MinIO/S3 credentials
   vim overlays/production/longhorn/s3-secret-unsealed.yaml
   # Change: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ENDPOINTS
   
   # Note: Sealing happens AFTER cluster bootstrap (Step 7+)
   # For now, keep it unsealed locally (gitignored)
   ```

   ⚠️ **Note:** `*-unsealed.yaml` files are gitignored for security. Only `.example` templates are committed.

7. **Create DNS Records** (required for HTTPS):

   All domains need CNAME records pointing to your DynDNS/external IP. Use the helper script:

   ```bash
   # Set your Cloudflare credentials
   ZONE_ID="your-zone-id"
   API_TOKEN="your-api-token"
   TARGET="your-dyndns-hostname.dyndns.org"  # or external IP
   
   # Create DNS records for all services
   ./scripts/create-dns-record.sh argo elmstreet79.de $TARGET $ZONE_ID $API_TOKEN
   ./scripts/create-dns-record.sh portainer elmstreet79.de $TARGET $ZONE_ID $API_TOKEN
   ./scripts/create-dns-record.sh grafana elmstreet79.de $TARGET $ZONE_ID $API_TOKEN
   ./scripts/create-dns-record.sh ntfy elmstreet79.de $TARGET $ZONE_ID $API_TOKEN
   ./scripts/create-dns-record.sh uptime elmstreet79.de $TARGET $ZONE_ID $API_TOKEN
   ./scripts/create-dns-record.sh teslalogger elmstreet79.de $TARGET $ZONE_ID $API_TOKEN
   ./scripts/create-dns-record.sh dreambox elmstreet79.de $TARGET $ZONE_ID $API_TOKEN
   ```

   **Get Cloudflare credentials:**
   - Zone ID: Cloudflare Dashboard → Your Domain → Overview (right sidebar)
   - API Token: Dashboard → My Profile → API Tokens → Create Token (Zone.DNS Edit permission)

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
- MetalLB, Cert-Manager, NGINX, etc. follow in order
- Some apps will stay "Progressing" until secrets are sealed (next step)

### Step 7.5: Seal Secrets (**on your laptop** - AFTER Step 7)

⚠️ **Wait until Sealed Secrets Controller is ready:**

```bash
# Check if controller is running
kubectl wait --for=condition=available --timeout=300s \
  deployment/sealed-secrets-controller -n kube-system

# Now seal your secrets
kubeseal --format=yaml --controller-namespace=kube-system \
  < overlays/production/cert-manager/cloudflare-token-unsealed.yaml \
  > overlays/production/cert-manager/cloudflare-token-sealed.yaml

# Seal Grafana admin secret:
kubeseal --format=yaml --controller-namespace=sealed-secrets \
  < overlays/production/kube-prometheus-stack/grafana-admin-unsealed.yaml \
  > overlays/production/kube-prometheus-stack/grafana-admin-sealed.yaml

# If using Longhorn S3 backup:
kubeseal --format=yaml --controller-namespace=kube-system \
  < overlays/production/longhorn/s3-secret-unsealed.yaml \
  > overlays/production/longhorn/s3-secret-sealed.yaml

# Enable sealed secrets in kustomization (automated)
# macOS (BSD sed): uncomment the sealed secret entries
sed -i '' 's/^  # - cloudflare-token-sealed.yaml/  - cloudflare-token-sealed.yaml/' \
  overlays/production/cert-manager/kustomization.yaml

sed -i '' 's/^  # - grafana-admin-sealed.yaml/  - grafana-admin-sealed.yaml/' \
  overlays/production/kube-prometheus-stack/kustomization.yaml

# If using Longhorn S3 backup, also enable:
sed -i '' 's/^  # - s3-secret-sealed.yaml/  - s3-secret-sealed.yaml/' \
  overlays/production/longhorn/kustomization.yaml

# Commit and push
git add overlays/production/*/kustomization.yaml
git add overlays/production/*/*-sealed.yaml
git commit -m "🔐 Add sealed secrets"
git push

# ArgoCD will auto-sync and apply the secrets
kubectl get applications -n argocd -w
```

### Step 8: Verify Deployment (**on your laptop**)

```bash
# All apps should be Synced + Healthy
kubectl get applications -n argocd

# MetalLB assigned LoadBalancer IP
kubectl get svc -n ingress-nginx
# EXTERNAL-IP should show 192.168.2.250-254 range

# Certificates issued (takes 2-5 min for DNS-01)
kubectl get certificate -A
# All should show READY=True

# Ingresses configured
kubectl get ingress -A
```

### Step 9: Access UIs (**from your laptop browser**)

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
URL: http://<node-ip>:30080
(Internal only, no ingress for security)
```

**Monitoring Stack:**

```text
Grafana:      https://grafana.elmstreet79.de
Prometheus:   http://<node-ip>:9090 (Internal only - port-forward or use Grafana)
Alertmanager: http://<node-ip>:9093 (Internal only - port-forward or use Grafana)
Credentials:  admin / <from sealed-secret>
```

📊 **Pre-installed dashboards:** Kubernetes cluster metrics, node metrics, pod resources, persistent volumes

🔒 **Security note:** Prometheus and Alertmanager are not exposed publicly (no ingress). Access via:

- Grafana datasource (recommended)
- Port-forward: `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090`

**ntfy (Notifications):**

```text
URL: https://ntfy.elmstreet79.de
```

📱 **Mobile apps:** [iOS](https://apps.apple.com/app/ntfy/id1625396347) | [Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy)

**Uptime Kuma (Uptime Monitoring):**

```text
URL: https://uptime.elmstreet79.de
```

⚠️ **First visit:** Create admin account on initial access. Then add monitors for your services.

**Private Services:**

```text
TeslaLogger: https://teslalogger.elmstreet79.de (→ 192.168.2.9:3000)
Dreambox: https://dreambox.elmstreet79.de (→ 192.168.2.11:80)
(External services routed via NGINX Ingress with TLS)
```

## 🔧 Management

### View Application Status

```bash
kubectl get applications -n argocd
kubectl describe application <app-name> -n argocd
```

### Update Component

```bash
# Edit Helm values
vim base/nginx-ingress/values.yaml

# Commit and push - ArgoCD auto-syncs
git add base/nginx-ingress/values.yaml
git commit -m "Update NGINX to 2 replicas"
git push

# Watch sync
kubectl get application nginx-ingress -n argocd -w
```

### Update Secrets

```bash
# 1. Edit unsealed secret
vim overlays/production/cert-manager/cloudflare-token-unsealed.yaml

# 2. Re-seal
kubeseal --format=yaml --controller-namespace=kube-system \
  < overlays/production/cert-manager/cloudflare-token-unsealed.yaml \
  > overlays/production/cert-manager/cloudflare-token-sealed.yaml

# 3. Commit and push
git add overlays/production/cert-manager/cloudflare-token-sealed.yaml
git commit -m "Rotate Cloudflare token"
git push
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

**Fix:** Ensure L2Advertisement exists in `overlays/production/metallb/metallb-ip-pool.yaml`

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

## 📚 Components

| Component | Version | Purpose |
|-----------|---------|---------|
| K3s | v1.33.5 | Lightweight Kubernetes |
| Kube-VIP | v1.0.1 | Control plane HA |
| ArgoCD | v3.1.9 | GitOps CD |
| Sealed Secrets | v0.32.2 | Encrypted secrets |
| Reloader | v1.4.10 | Auto-reload on ConfigMap/Secret changes |
| MetalLB | v0.15.2 | LoadBalancer |
| NGINX Ingress | v1.14.0 | Ingress controller |
| Cert-Manager | v1.19.1 | TLS certificates |
| Longhorn | v1.10.0 | Distributed storage |
| Portainer | ce-2.33.3 | Management UI |
| ntfy | v2.14.0 | Notification service |
| Uptime Kuma | v1.23.16 | Uptime monitoring & status page |
| kube-prometheus-stack | v0.86.1 | Prometheus, Grafana, Alertmanager monitoring |

## 📖 Documentation

- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [Stakater Reloader](https://github.com/stakater/Reloader)
- [K3s Documentation](https://docs.k3s.io/)
- [MetalLB](https://metallb.universe.tf/)
- [Cert-Manager](https://cert-manager.io/)
- [Longhorn](https://longhorn.io/)
- [ntfy](https://ntfy.sh/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

## 📝 License

MIT
