# Kubernetes Homelab - GitOps with ArgoCD

Production-ready K3s cluster managed via GitOps using ArgoCD App-of-Apps pattern.

## 🎯 Architecture

**Key Principle**: ArgoCD manages everything EXCEPT itself (prevents self-management conflicts).

### Deployment Flow

```
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

## 📁 Repository Structure

```
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
    ├── portainer/
    │   └── ingress.yaml           # Portainer HTTPS ingress
    └── longhorn/
        └── s3-secret-*.yaml       # S3 backup credentials
```

## 🚀 Fresh Installation

### Prerequisites

- 2+ nodes (Raspberry Pi or other)
- Domain with Cloudflare DNS
- Cloudflare API Token (Zone.DNS Edit permission)
- S3-compatible storage for Longhorn backups (optional)

### Step 1: Install K3s Cluster

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

### Step 2: Install Kube-VIP (Control Plane HA)

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
