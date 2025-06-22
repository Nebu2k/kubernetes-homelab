# Version Information

This setup uses the following versions (as of June 2025):

## MetalLB
- **Version**: v0.15.2
- **Helm Chart**: metallb/metallb
- **Repository**: https://metallb.github.io/metallb

## NGINX Ingress Controller
- **Version**: v1.12.3 (controller)
- **Helm Chart**: ingress-nginx/ingress-nginx
- **Repository**: https://kubernetes.github.io/ingress-nginx

## ArgoCD

- **Version**: v3.0.6
- **Helm Chart**: argo/argo-cd
- **Repository**: <https://argoproj.github.io/argo-helm>

## Cert-Manager

- **Version**: v1.18.1
- **Helm Chart**: jetstack/cert-manager
- **Repository**: <https://charts.jetstack.io>

## Portainer

- **Version**: v2.22.0
- **Helm Chart**: portainer/portainer
- **Repository**: <https://portainer.github.io/k8s/>

## Longhorn

- **Version**: v1.9.0 (with hotfix v1.9.0-hotfix-1 for manager)
- **Helm Chart**: longhorn/longhorn
- **Repository**: <https://charts.longhorn.io>
- **Note**: Uses hotfix for longhorn-manager to address stability issues

## PiHole

- **Version**: v2025.1.0
- **Helm Chart**: mojo2600/pihole
- **Repository**: <https://mojo2600.github.io/pihole-kubernetes/>

## How to Check for Updates

### MetalLB
```bash
helm repo update
helm search repo metallb/metallb --versions | head -5
```

### NGINX Ingress
```bash
helm repo update
helm search repo ingress-nginx/ingress-nginx --versions | head -5
```

### ArgoCD
```bash
helm repo update
helm search repo argo/argo-cd --versions | head -5
```

### Cert-Manager
```bash
helm repo update
helm search repo jetstack/cert-manager --versions | head -5
```

### Portainer
```bash
helm repo update
helm search repo portainer/portainer --versions | head -5
```

### Longhorn
```bash
helm repo update
helm search repo longhorn/longhorn --versions | head -5
```

### PiHole
```bash
helm repo update
helm search repo mojo2600/pihole --versions | head -5
```

## Upgrading Components

### MetalLB
```bash
helm upgrade metallb metallb/metallb \
  --namespace metallb-system \
  --values k8s-setup/metallb/values.yaml
```

### NGINX Ingress
```bash
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --values k8s-setup/nginx-ingress/values.yaml
```

### ArgoCD
```bash
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  --values k8s-setup/argocd/values.yaml
```

### Cert-Manager
```bash
# Update CRDs first
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.1/cert-manager.crds.yaml

# Then upgrade
helm upgrade cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --values k8s-setup/cert-manager/values.yaml
```

### Portainer
```bash
helm upgrade portainer portainer/portainer \
  --namespace portainer \
  --values k8s-setup/portainer/values.yaml
```

### Longhorn
```bash
# Note: Longhorn upgrades require careful planning
# See: https://longhorn.io/docs/v1.9.0/deploy/upgrade/
helm upgrade longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --values k8s-setup/longhorn/values.yaml
```

### PiHole
```bash
helm upgrade pihole mojo2600/pihole \
  --namespace pihole \
  --values k8s-setup/pihole/values.yaml
```
