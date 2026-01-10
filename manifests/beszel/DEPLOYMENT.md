# Beszel Deployment Guide

## Pre-Deployment Checklist

Before pushing to Git and letting ArgoCD deploy:

### 1. Configure S3 Backup Credentials

Edit [secret.yaml](secret.yaml) with your actual S3-compatible storage credentials:

```yaml
stringData:
  S3_ENDPOINT: "https://your-actual-s3-endpoint.com"
  S3_BUCKET: "beszel-backups"
  S3_ACCESS_KEY: "your-actual-access-key"
  S3_SECRET_KEY: "your-actual-secret-key"
  S3_REGION: "us-east-1"
```

**Important**: For production, consider using sealed-secrets or external-secrets instead of committing credentials directly.

### 2. Review Storage Size

Check [pvc.yaml](pvc.yaml) - default is 20Gi. Adjust if needed:

```yaml
resources:
  requests:
    storage: 20Gi  # Adjust based on your needs
```

### 3. Verify Ingress Hostname

Confirm [ingress.yaml](ingress.yaml) has the correct hostname:

```yaml
- host: beszel-k8s.elmstreet79.de
```

## Deployment via ArgoCD

### ArgoCD Application Created

The ArgoCD application has been created at:
- **File**: [homelab/apps/beszel.yaml](../../apps/beszel.yaml)
- **Sync Wave**: 10 (deploys after monitoring stack)
- **Auto-Sync**: Enabled with prune and self-heal

### Deploy Steps

1. **Update S3 credentials** in secret.yaml (see above)

2. **Commit and push** to your repository:
   ```bash
   cd homelab
   git add manifests/beszel/ apps/beszel.yaml apps/kustomization.yaml
   git commit -m "Add Beszel monitoring system"
   git push
   ```

3. **ArgoCD will automatically sync** the application

4. **Monitor deployment**:
   ```bash
   # Watch ArgoCD app
   kubectl get applications -n argocd beszel -w

   # Check resources
   kubectl get all -n beszel

   # Watch pod startup
   kubectl get pods -n beszel -w
   ```

## Post-Deployment Configuration

### 1. Access Web UI

Navigate to: https://beszel-k8s.elmstreet79.de

### 2. Initial Setup

1. Create admin account
2. Set password
3. Configure preferences

### 3. Get SSH Public Key for Agents

In the Beszel web UI:
1. Go to **Settings** → **Systems** → **Add System**
2. Copy the SSH public key displayed
3. You'll need this for agent configuration

### 4. Configure Agent DaemonSet

**Edit** [agent-daemonset.yaml](agent-daemonset.yaml):

```yaml
- name: KEY
  value: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIYourActualKeyFromHub"
```

**Uncomment** in [kustomization.yaml](kustomization.yaml):

```yaml
resources:
  - namespace.yaml
  - pvc.yaml
  - secret.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
  - agent-daemonset.yaml  # Uncomment this line
```

**Commit and push**:

```bash
git add manifests/beszel/agent-daemonset.yaml manifests/beszel/kustomization.yaml
git commit -m "Enable Beszel agents with SSH key"
git push
```

ArgoCD will automatically deploy the agents.

### 5. Register Nodes in Hub

For each Kubernetes node:

1. In Beszel web UI: **Systems** → **Add System**
2. Enter details:
   - **Name**: Node name (e.g., "k8s-master-1", "k8s-worker-1")
   - **Host**: **Physical node IP address** (e.g., 192.168.1.10)
     - ⚠️ Use physical IP, NOT cluster internal IP
   - **Port**: 45876
3. Click **Save**

The agent should connect immediately.

### 6. Verify Agent Connection

```bash
# Check agent pods
kubectl get pods -n beszel -l app=beszel-agent

# Check agent logs
kubectl logs -n beszel -l app=beszel-agent

# Should show successful connection to hub
```

### 7. Configure and Test Backup

In the Beszel web UI:

1. Go to **Settings** → **Backup**
2. Verify S3 configuration is detected
3. Click **Manual Backup**
4. Verify backup appears in your S3 bucket
5. Test **Restore from Backup** functionality

## Verification Checklist

- [ ] Hub pod is running: `kubectl get pods -n beszel`
- [ ] PVC is bound: `kubectl get pvc -n beszel`
- [ ] Ingress has IP: `kubectl get ingress -n beszel`
- [ ] Certificate issued: `kubectl get certificate -n beszel`
- [ ] Web UI accessible at https://beszel-k8s.elmstreet79.de
- [ ] Agent pods running on all nodes: `kubectl get ds -n beszel`
- [ ] All nodes registered and showing metrics in UI
- [ ] S3 backup tested and working
- [ ] Restore from backup tested

## Troubleshooting

### Hub Not Starting

```bash
# Check pod events
kubectl describe pod -n beszel -l app=beszel-hub

# Check logs
kubectl logs -n beszel -l app=beszel-hub

# Check PVC
kubectl get pvc -n beszel
kubectl describe pvc beszel-data -n beszel
```

### Can't Access Web UI

```bash
# Check ingress
kubectl get ingress -n beszel
kubectl describe ingress beszel-hub -n beszel

# Check certificate
kubectl get certificate -n beszel
kubectl describe certificate beszel-hub-tls -n beszel

# Check service
kubectl get svc -n beszel
```

### Agents Not Connecting

```bash
# Check DaemonSet
kubectl get ds -n beszel
kubectl describe ds beszel-agent -n beszel

# Check agent pods
kubectl get pods -n beszel -l app=beszel-agent

# Check agent logs
kubectl logs -n beszel -l app=beszel-agent

# Verify SSH key is set correctly
kubectl get ds beszel-agent -n beszel -o yaml | grep -A 2 "name: KEY"
```

Common issues:
- Wrong SSH key (must match hub's public key)
- Wrong node IP address (use physical IP, not cluster IP)
- Firewall blocking port 45876
- Agent pod not running due to resource constraints

### S3 Backup Not Working

```bash
# Check secret exists
kubectl get secret beszel-s3-credentials -n beszel

# Verify secret values (base64 encoded)
kubectl get secret beszel-s3-credentials -n beszel -o yaml

# Check deployment has env vars
kubectl get deployment beszel-hub -n beszel -o yaml | grep -A 20 "env:"

# Check hub logs for S3 errors
kubectl logs -n beszel -l app=beszel-hub | grep -i s3
```

## Monitoring

### Resource Usage

```bash
# Pod resource consumption
kubectl top pods -n beszel

# PVC usage
kubectl exec -n beszel deployment/beszel-hub -- df -h /beszel_data
```

### Update Beszel

ArgoCD will automatically update when you change the image tag or when using `:latest`.

To force restart:

```bash
# Restart hub
kubectl rollout restart deployment beszel-hub -n beszel

# Restart agents
kubectl rollout restart daemonset beszel-agent -n beszel
```

## Cleanup (if needed)

To remove Beszel:

```bash
# Delete ArgoCD app (this will remove all resources)
kubectl delete application beszel -n argocd

# Or manually:
kubectl delete -k manifests/beszel/
```

## Support

- **Beszel GitHub**: https://github.com/henrygd/beszel
- **Beszel Issues**: https://github.com/henrygd/beszel/issues
- **Documentation**: See [README.md](README.md) for detailed info

## Notes

- This deployment is separate from your existing Pi5 Beszel at beszel.elmstreet79.de
- Agent DaemonSet initially disabled until SSH key is configured
- Agents use hostNetwork for accurate metrics
- No Docker container monitoring (no socket mount)
- S3 credentials stored in Kubernetes Secret (consider sealed-secrets for production)
