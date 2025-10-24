# Homelab K3s Setup Guide

Complete guide for setting up a highly available K3s cluster with all necessary components.

## ⚙️ Before You Start

**Important**: This setup contains template values that must be customized for your environment.

### Required Customizations

#### 1. Network Configuration

- **VIP Address**: Replace `192.168.2.249` in Kube-VIP DaemonSet with your desired virtual IP
- **IP Pool**: Adjust `192.168.2.250-192.168.2.254` in `k8s-setup/metallb/ip-pool.yaml` for MetalLB

#### 2. Domain Configuration

The following files contain `example.com` placeholders that must be replaced with your actual domain:

- `k8s-setup/argocd/ingress.yaml` - Set `argocd.yourdomain.com`
- `k8s-setup/argocd/values.yaml` - Set domain and URL
- `k8s-setup/portainer/ingress.yaml` - Set `portainer.yourdomain.com`

#### 3. Certificate Manager

- `k8s-setup/cert-manager/cluster-issuer.yaml` - Replace `certs@example.com` with your email

#### 4. Cloudflare Credentials

For DNS-01 challenges and DNS record creation, you'll need:

- **Zone ID**: Found in Cloudflare Dashboard → Your Domain → Overview (right sidebar)
- **API Token**: Created in Cloudflare Dashboard → My Profile → API Tokens
  - Required permission: Zone.DNS (Edit)

**Why is this needed?**
Cert-manager uses the DNS-01 challenge to prove domain ownership to Let's Encrypt. It automatically creates temporary TXT records in your Cloudflare DNS to validate certificates. This allows wildcard certificates and works even if your services aren't publicly accessible yet.

Create the Cloudflare API token secret before installing cert-manager:

```bash
kubectl create namespace cert-manager
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=<your-cloudflare-api-token> \
  -n cert-manager
```

#### 5. Longhorn S3 Backups (Optional)

If you want to use Longhorn backups to S3-compatible storage:

- `k8s-setup/longhorn/secret.yaml` - Replace with your S3/MinIO credentials
- Supported: AWS S3, MinIO, Backblaze B2, or any S3-compatible storage

---

## 🏗️ Initial K3s Cluster Setup

### First Control Plane Node

```bash
# Install K3s with latest version and HA support
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -s - server \
  --cluster-init \
  --tls-san <your-vip-ip> \
  --tls-san <node-hostname> \
  --tls-san <node-ip> \
  --disable traefik \
  --write-kubeconfig-mode 644

# Get the node token for additional nodes
sudo cat /var/lib/rancher/k3s/server/node-token
```

### Additional Control Plane Nodes

```bash
# Stop existing agent if upgrading from worker
sudo systemctl stop k3s-agent
sudo systemctl disable k3s-agent

# Join as control plane
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -s - server \
  --server https://<first-control-plane-ip>:6443 \
  --token <node-token-from-first-node> \
  --tls-san <your-vip-ip> \
  --tls-san <node-hostname> \
  --tls-san <node-ip> \
  --disable traefik \
  --write-kubeconfig-mode 644
```

### Worker Nodes

```bash
# Join as worker
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest K3S_URL=https://<control-plane-ip>:6443 K3S_TOKEN=<node-token> sh -
```

### Kube-VIP Setup (Load Balancer for Control Plane)

```bash
# Apply RBAC
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml

# Create Kube-VIP DaemonSet (adjust VIP address as needed)
cat << EOF | kubectl apply -f -
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
      containers:
      - args:
        - manager
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
        - name: vip_ddns
          value: "false"
        - name: svc_enable
          value: "true"
        - name: vip_leaderelection
          value: "true"
        - name: vip_leaseduration
          value: "5"
        - name: vip_renewdeadline
          value: "3" 
        - name: vip_retryperiod
          value: "1"
        - name: address
          value: "192.168.2.249"  # Change to your VIP
        image: ghcr.io/kube-vip/kube-vip:v0.6.4
        imagePullPolicy: Always
        name: kube-vip
        resources: {}
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
            - NET_RAW
      serviceAccountName: kube-vip
      tolerations:
      - effect: NoSchedule
        operator: Exists
      - effect: NoExecute
        operator: Exists
EOF
```

## 📦 Application Stack Installation

### Prerequisites

```bash
# Verify cluster access
kubectl cluster-info
kubectl get nodes

# Add Helm repositories
helm repo add metallb https://metallb.github.io/metallb
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add longhorn https://charts.longhorn.io
helm repo add portainer https://portainer.github.io/k8s
helm repo update
```

## 1. MetalLB (Load Balancer)

```bash
# Install MetalLB
helm upgrade --install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace \
  --values k8s-setup/metallb/values.yaml \
  --wait

# Apply IP pool configuration
kubectl apply -f k8s-setup/metallb/ip-pool.yaml

# Verify
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system
```

## 2. NGINX Ingress Controller

```bash
# Create namespace
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

# Apply custom headers
kubectl apply -f k8s-setup/nginx-ingress/custom-headers.yaml

# Install NGINX Ingress
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --values k8s-setup/nginx-ingress/values.yaml \
  --wait

# Verify
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

## 3. Cert-Manager (TLS Certificates)

```bash
# Install cert-manager with CRDs
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --values k8s-setup/cert-manager/values.yaml \
  --wait

# Apply ClusterIssuer (requires Cloudflare API token in Secret)
kubectl apply -f k8s-setup/cert-manager/cluster-issuer.yaml

# Verify
kubectl get pods -n cert-manager
kubectl get clusterissuer
```

## 4. Longhorn (Distributed Storage)

Longhorn provides distributed block storage with high availability, automatic backups, and snapshots.

### Node Requirements

Install required packages on **all nodes**:

```bash
# On each node
sudo apt update
sudo apt install -y open-iscsi nfs-common
sudo systemctl enable --now iscsid
```

### Installation

```bash
# Create namespace
kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f -

# Create S3 backup secret (optional, only if using S3 backups)
# Adjust credentials in k8s-setup/longhorn/secret.yaml first!
kubectl apply -f k8s-setup/longhorn/secret.yaml

# Install Longhorn
helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --values k8s-setup/longhorn/values.yaml \
  --wait

# Apply storage classes
kubectl apply -f k8s-setup/longhorn/storage-classes.yaml

# Optional: NodePort for UI access (http://<node-ip>:30080)
kubectl apply -f k8s-setup/longhorn/nodeport.yaml

# Verify
kubectl get pods -n longhorn-system
kubectl get storageclass
```

### Available Storage Classes

| Name | Replicas | Default | Use Case |
|------|----------|---------|----------|
| `longhorn` | 3 | ✅ | Production workloads |
| `longhorn-fast` | 1 | ❌ | Cache/temporary data |
| `longhorn-ha` | 3 | ❌ | Mission-critical data |

### Automatic Backups (Optional)

Configure recurring backup jobs for automatic volume backups:

```bash
# Apply recurring backup jobs
kubectl apply -f k8s-setup/longhorn/recurring-backup-job.yaml

# Verify backup jobs
kubectl get recurringjobs -n longhorn-system
```

**Enable backups for all volumes:**

```bash
# Daily backups
kubectl get volumes.longhorn.io -n longhorn-system -o name | while read vol; do
  kubectl label $vol -n longhorn-system recurring-job.longhorn.io/backup-daily=enabled --overwrite
done

# Weekly backups
kubectl get volumes.longhorn.io -n longhorn-system -o name | while read vol; do
  kubectl label $vol -n longhorn-system recurring-job.longhorn.io/backup-weekly=enabled --overwrite
done

# Snapshot cleanup
kubectl get volumes.longhorn.io -n longhorn-system -o name | while read vol; do
  kubectl label $vol -n longhorn-system recurring-job.longhorn.io/snapshot-cleanup-daily=enabled --overwrite
done
```

**Or configure via Longhorn UI:**

1. Open Longhorn UI at `http://<node-ip>:30080`
2. Go to **Volume** → Select a volume → **⋮** → **Recurring Jobs Schedule**
3. Enable desired backup jobs

**Backup Schedule:**

- `backup-daily`: Daily at 2:00 AM, keeps 7 backups (1 week)
- `backup-weekly`: Sundays at 3:00 AM, keeps 4 backups (1 month)
- `snapshot-cleanup-daily`: Daily at 4:00 AM, cleans old snapshots

## 5. ArgoCD (GitOps)

```bash
# Install ArgoCD
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values k8s-setup/argocd/values.yaml \
  --wait

# Create DNS record (requires Cloudflare credentials)
# Get Zone ID: Cloudflare Dashboard > Your Domain > Overview (right sidebar)
# Get API Token: Cloudflare Dashboard > My Profile > API Tokens
# Adjust subdomain, domain, and target to match your setup
./scripts/create-dns-record.sh argocd example.com myserver.dyndns.org <your-zone-id> <your-api-token>

# Apply Ingress (adjust domain in ingress.yaml first!)
kubectl apply -f k8s-setup/argocd/ingress.yaml

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Verify
kubectl get pods -n argocd
kubectl get ingress -n argocd
```

## 6. Portainer (Container Management UI)

```bash
# Install Portainer
helm upgrade --install portainer portainer/portainer \
  --namespace portainer \
  --create-namespace \
  --values k8s-setup/portainer/values.yaml \
  --wait

# Create DNS record (requires Cloudflare credentials)
# Adjust subdomain, domain, and target to match your setup
./scripts/create-dns-record.sh portainer example.com myserver.dyndns.org <your-zone-id> <your-api-token>

# Apply Ingress (adjust domain in ingress.yaml first!)
kubectl apply -f k8s-setup/portainer/ingress.yaml

# Verify
kubectl get pods -n portainer
kubectl get ingress -n portainer
```

## 7. Demo App (Optional)

The demo app is a simple Node.js application that demonstrates multi-architecture Docker builds (AMD64 + ARM64) and GitOps deployment with ArgoCD.

```bash
# 1. Create DNS record for demo app (adjust subdomain, domain, and target)
./scripts/create-dns-record.sh demo example.com myserver.dyndns.org <your-zone-id> <your-api-token>

# 2. Update the ingress domain in the demo app repository
# Edit argocd-demo-app/k8s/ingress.yaml and set your domain

# 3. Apply demo app via ArgoCD
kubectl apply -f demo-app/argocd.yaml

# 4. Verify deployment
kubectl get application -n argocd demo-app
kubectl get pods -n demo-app
kubectl get ingress -n demo-app

# 5. Access the app at https://demo.example.com (or your configured domain)
```

**Note**: The demo app repository (argocd-demo-app) uses GitHub Actions to build multi-arch images and ArgoCD will automatically sync changes from the repository.

## Quick Status Check

```bash
# All pods
kubectl get pods --all-namespaces

# All ingresses
kubectl get ingress --all-namespaces

# All services with LoadBalancer
kubectl get svc --all-namespaces -o wide | grep LoadBalancer

# Nodes
kubectl get nodes -o wide
```

## Uninstall (if needed)

```bash
# Remove in reverse order
helm uninstall portainer -n portainer
helm uninstall argocd -n argocd
helm uninstall longhorn -n longhorn-system
helm uninstall cert-manager -n cert-manager
helm uninstall ingress-nginx -n ingress-nginx
helm uninstall metallb -n metallb-system

# Remove namespaces
kubectl delete namespace portainer argocd longhorn-system cert-manager ingress-nginx metallb-system demo-app
```

## Troubleshooting

```bash
# Check pod logs
kubectl logs -n <namespace> <pod-name>

# Describe pod
kubectl describe pod -n <namespace> <pod-name>

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Restart deployment
kubectl rollout restart deployment/<deployment-name> -n <namespace>
```
