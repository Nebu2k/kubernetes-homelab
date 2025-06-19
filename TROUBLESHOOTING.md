# Troubleshooting Guide

## Uninstall Script Issues

### Script Fails with Cluster Access Error
```bash
# Check if kubectl is working
kubectl cluster-info

# Check if kubeconfig is properly configured
kubectl config current-context

# Verify cluster connectivity
kubectl get nodes
```

### Components Not Fully Removed
```bash
# Check for stuck namespaces
kubectl get namespaces --field-selector=status.phase=Terminating

# Force remove namespace finalizers (if needed)
kubectl patch namespace <namespace-name> -p '{"metadata":{"finalizers":[]}}' --type=merge

# Check for remaining CRDs
kubectl get crd | grep -E "(metallb|ingress|argo|cert-manager)"

# Force remove CRDs (if needed)
kubectl delete crd <crd-name> --force --grace-period=0
```

### Helm Releases Stuck
```bash
# Check helm releases
helm list --all-namespaces

# Force uninstall stuck releases
helm uninstall <release-name> -n <namespace> --no-hooks

# Clean up stuck secrets
kubectl delete secret -n <namespace> -l owner=helm
```

### Webhook Configuration Issues
```bash
# List all webhook configurations
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# Force remove problematic webhooks
kubectl delete validatingwebhookconfigurations <webhook-name>
kubectl delete mutatingwebhookconfigurations <webhook-name>
```

### Manual Recovery Steps
If the uninstall script fails, you can manually remove components:

```bash
# 1. Remove all namespaces forcefully
kubectl delete namespace metallb-system cert-manager argocd ingress-nginx --force --grace-period=0

# 2. Remove all related CRDs
kubectl get crd -o name | grep -E "(metallb|cert-manager|argoproj)" | xargs kubectl delete

# 3. Remove cluster-wide resources
kubectl delete clusterrole,clusterrolebinding -l "app.kubernetes.io/name in (metallb,cert-manager,argocd,ingress-nginx)"

# 4. Remove webhook configurations
kubectl delete validatingwebhookconfigurations,mutatingwebhookconfigurations --all

# 5. Clean up any remaining finalizers
kubectl get all,pv,pvc --all-namespaces | grep -E "(metallb|cert-manager|argocd|ingress-nginx)"
```

## Common Issues and Solutions

### MetalLB Issues

#### MetalLB Controller Not Starting
```bash
# Check controller logs
kubectl logs -n metallb-system -l app.kubernetes.io/component=controller

# Check if kube-proxy is in IPVS mode (requires strictARP)
kubectl get configmap kube-proxy -n kube-system -o yaml | grep mode
```

#### IP Address Not Assigned
```bash
# Check IP address pools
kubectl get ipaddresspools -n metallb-system

# Check L2 advertisements
kubectl get l2advertisements -n metallb-system

# Check service events
kubectl describe svc ingress-nginx-controller -n ingress-nginx
```

#### Speaker Pods CrashLooping
```bash
# Check speaker logs
kubectl logs -n metallb-system -l app.kubernetes.io/component=speaker

# Check node network configuration
ip addr show
```

### NGINX Ingress Issues

#### Controller Not Starting
```bash
# Check controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Check webhook configuration
kubectl get validatingwebhookconfigurations | grep ingress-nginx
kubectl get mutatingwebhookconfigurations | grep ingress-nginx
```

#### LoadBalancer IP Not Assigned
```bash
# Check MetalLB is working first
kubectl get svc ingress-nginx-controller -n ingress-nginx
kubectl describe svc ingress-nginx-controller -n ingress-nginx

# Check MetalLB logs
kubectl logs -n metallb-system -l app.kubernetes.io/component=speaker
```

#### SSL/TLS Issues
```bash
# Check ingress configuration
kubectl describe ingress -A

# Check certificate status
kubectl get certificates -A
kubectl describe certificate <cert-name> -n <namespace>
```

### ArgoCD Issues

#### ArgoCD Server Not Accessible
```bash
# Check server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Check ingress
kubectl describe ingress argocd-server-ingress -n argocd

# Check service
kubectl get svc -n argocd
```

#### Applications Not Syncing
```bash
# Check application status
kubectl get applications -n argocd

# Check repo-server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server

# Check application controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Cert-Manager Issues

#### Certificates Not Issuing
```bash
# Check certificate status
kubectl get certificates -A
kubectl describe certificate <cert-name> -n <namespace>

# Check certificate requests
kubectl get certificaterequests -A
kubectl describe certificaterequest <cert-request-name> -n <namespace>

# Check challenges (for ACME)
kubectl get challenges -A
kubectl describe challenge <challenge-name> -n <namespace>
```

#### Let's Encrypt Rate Limits
```bash
# Use staging issuer for testing
# Edit your ingress to use "letsencrypt-staging" instead of "letsencrypt-prod"

# Check cert-manager logs
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager
```

## Network Troubleshooting

### DNS Resolution
```bash
# Test DNS resolution from a pod
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup google.com

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### Connectivity Testing
```bash
# Test connectivity to ingress
curl -v http://192.168.2.254
curl -v https://192.168.2.254

# Test from within cluster
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash
```

### Check Network Policies
```bash
# List network policies
kubectl get networkpolicies -A

# Check if network plugin supports network policies
kubectl get nodes -o wide
```

## Resource Issues

### Resource Constraints
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Check pod resources
kubectl top pods -A
kubectl get pods -A -o wide
```

### Storage Issues
```bash
# Check persistent volumes
kubectl get pv
kubectl get pvc -A

# Check storage classes
kubectl get storageclass
```

## Useful Commands

### General Debugging
```bash
# Get all resources in all namespaces
kubectl get all -A

# Check events
kubectl get events -A --sort-by=.metadata.creationTimestamp

# Check cluster info
kubectl cluster-info
kubectl cluster-info dump
```

### Helm Debugging
```bash
# List all releases
helm list -A

# Check release status
helm status <release-name> -n <namespace>

# Get release values
helm get values <release-name> -n <namespace>

# Check release history
helm history <release-name> -n <namespace>
```

## Recovery Procedures

### Restart All Components
```bash
# Restart MetalLB
kubectl rollout restart deployment/controller -n metallb-system
kubectl rollout restart daemonset/speaker -n metallb-system

# Restart NGINX Ingress
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx

# Restart ArgoCD
kubectl rollout restart deployment -n argocd

# Restart Cert-Manager
kubectl rollout restart deployment -n cert-manager
```

### Reset MetalLB IP Assignment
```bash
# Delete and recreate IP pool
kubectl delete ipaddresspool homelab-pool -n metallb-system
kubectl apply -f k8s-setup/metallb/ip-pool.yaml
```

### Reset Certificates
```bash
# Delete certificate to trigger reissue
kubectl delete certificate <cert-name> -n <namespace>

# Force certificate renewal
kubectl annotate certificate <cert-name> -n <namespace> cert-manager.io/issue-temporary-certificate="true"
```
