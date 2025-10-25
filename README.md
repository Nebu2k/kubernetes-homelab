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
| 1 | MetalLB | LoadBalancer IPs |
| 2 | Cert-Manager | TLS certificates |
| 3 | NGINX Ingress | HTTP(S) routing |
| 4 | Longhorn | Persistent storage |
| 5 | Portainer | Management UI |
| 10+ | Configs | Component-specific configs (ClusterIssuers, Ingresses, etc.) |
| 15 | Private Services | External service ingresses (TeslaLogger, Dreambox) |
| 20 | Demo App | Sample application |

## 📁 Repository Structure

```text
homelab/
├── bootstrap/
│   └── root-app.yaml              # App-of-Apps (deploys everything)
├── apps/
│   ├── kustomization.yaml         # List of all apps
│   ├── sealed-secrets.yaml        # Wave 0
│   ├── metallb.yaml               # Wave 1
│   ├── metallb-config.yaml        # Wave 10
│   ├── cert-manager.yaml          # Wave 2
│   ├── cert-manager-config.yaml   # Wave 10
│   ├── nginx-ingress.yaml         # Wave 3
│   ├── nginx-ingress-config.yaml  # Wave 11
│   ├── longhorn.yaml              # Wave 4
│   ├── longhorn-config.yaml       # Wave 13
│   ├── portainer.yaml             # Wave 5
│   └── portainer-config.yaml      # Wave 12
├── base/
│   ├── metallb/values.yaml        # Generic Helm values
│   ├── cert-manager/values.yaml
│   ├── nginx-ingress/values.yaml
│   ├── longhorn/values.yaml
│   └── portainer/values.yaml
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
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -s - server \
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
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -s - server \
  --server https://192.168.2.249:6443 \
  --token <token-from-step-1> \
  --tls-san 192.168.2.249 \
  --tls-san raspi5 \
  --tls-san 192.168.2.9 \
  --disable traefik \
  --write-kubeconfig-mode 644
```

### Step 5: Install ArgoCD via Helm (**on your laptop**)

⚠️ **ArgoCD is NOT managed via GitOps** (prevents self-management conflicts)

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install with your domain (or use argo.elmstreet79.de if keeping defaults)
helm install argocd argo/argo-cd \
  --version 8.1.2 \
  --namespace argocd \
  --create-namespace \
  --set global.domain=argo.elmstreet79.de \
  --set configs.cm.url=https://argo.elmstreet79.de \
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
   # Change: argo.elmstreet79.de
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

# Wait for the root App to be created by the apply
until kubectl get application homelab -n argocd >/dev/null 2>&1; do
  echo "waiting for 'homelab' ArgoCD Application to be created..."
  sleep 2
done

# Now watch ArgoCD deploy everything (~5-10 minutes)
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

# If using Longhorn S3 backup:
kubeseal --format=yaml --controller-namespace=kube-system \
  < overlays/production/longhorn/s3-secret-unsealed.yaml \
  > overlays/production/longhorn/s3-secret-sealed.yaml

# Enable sealed secrets in kustomization
vim overlays/production/cert-manager/kustomization.yaml
# Uncomment: - cloudflare-token-sealed.yaml

vim overlays/production/longhorn/kustomization.yaml
# Uncomment: - s3-secret-sealed.yaml (if using S3)

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
URL: https://argo.elmstreet79.de
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
| K3s | v1.34.1 | Lightweight Kubernetes |
| Kube-VIP | v1.0.1 | Control plane HA |
| ArgoCD | v3.0.6 | GitOps CD |
| Sealed Secrets | v0.27.2 | Encrypted secrets |
| MetalLB | v0.15.2 | LoadBalancer |
| NGINX Ingress | v1.13.3 | Ingress controller |
| Cert-Manager | v1.16.2 | TLS certificates |
| Longhorn | v1.10.0 | Distributed storage |
| Portainer | v2.35.0 | Management UI |

## 📖 Documentation

- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [K3s Documentation](https://docs.k3s.io/)
- [MetalLB](https://metallb.universe.tf/)
- [Cert-Manager](https://cert-manager.io/)
- [Longhorn](https://longhorn.io/)

## 📝 License

MIT
