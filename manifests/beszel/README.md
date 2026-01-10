# Beszel Kubernetes Deployment

This directory contains Kubernetes manifests for deploying Beszel monitoring system in your cluster.

## What is Beszel?

Beszel is a lightweight, open-source server monitoring platform built in Go with PocketBase. It provides:
- System metrics monitoring (CPU, memory, disk, network)
- GPU monitoring support (NVIDIA, AMD, Intel)
- Historical data with trend analysis
- Alert functions with customizable thresholds
- S3-compatible backup support

## Architecture

- **Hub**: Central web application running on port 8090
- **Agent**: Lightweight collectors running on each node (port 45876)
- **Storage**: 20Gi persistent volume for metrics data
- **Ingress**: https://beszel-k8s.elmstreet79.de

## Files

- `namespace.yaml` - Creates the beszel namespace
- `pvc.yaml` - 20Gi persistent volume claim for data storage
- `secret.yaml` - S3 backup credentials (template)
- `deployment.yaml` - Beszel hub deployment
- `service.yaml` - ClusterIP service on port 8090
- `ingress.yaml` - Traefik ingress with TLS via cert-manager
- `agent-daemonset.yaml` - Agent pods running on each node
- `kustomization.yaml` - Kustomize configuration

## Deployment Steps

### 1. Configure S3 Backup Credentials

Edit [secret.yaml](secret.yaml) and replace the placeholder values with your actual S3-compatible storage credentials:

```yaml
S3_ENDPOINT: "https://your-s3-endpoint.example.com"
S3_BUCKET: "beszel-backups"
S3_ACCESS_KEY: "your-access-key-id"
S3_SECRET_KEY: "your-secret-access-key"
S3_REGION: "us-east-1"
```

**For production**: Use sealed-secrets or external-secrets instead of committing credentials to Git.

### 2. Deploy the Hub

```bash
# From the beszel directory
kubectl apply -k .
```

This will create:
- Namespace
- PVC for persistent storage
- Secret with S3 credentials
- Deployment with the hub
- Service
- Ingress with TLS

### 3. Verify Hub Deployment

```bash
# Check all resources
kubectl get all -n beszel

# Check pod status
kubectl get pods -n beszel

# Check PVC is bound
kubectl get pvc -n beszel

# Check ingress
kubectl get ingress -n beszel

# View logs
kubectl logs -n beszel -l app=beszel-hub
```

### 4. Access the Web UI

Navigate to: https://beszel-k8s.elmstreet79.de

Complete the initial setup:
1. Create admin account
2. Configure settings
3. Set up alert preferences

### 5. Get SSH Public Key for Agents

In the Beszel web UI:
1. Go to **Settings** → **Systems** → **Add System**
2. Copy the SSH public key displayed
3. This key will be used to authenticate agents

### 6. Configure and Deploy Agents

Edit [agent-daemonset.yaml](agent-daemonset.yaml) and replace the placeholder with your SSH public key:

```yaml
- name: KEY
  value: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIYourActualKeyHere"
```

Then uncomment the agent-daemonset in [kustomization.yaml](kustomization.yaml):

```yaml
resources:
  # ... other resources ...
  - agent-daemonset.yaml  # Uncomment this line
```

Apply the updated configuration:

```bash
kubectl apply -k .
```

### 7. Verify Agent Deployment

```bash
# Check DaemonSet status
kubectl get ds -n beszel

# Check agent pods (should be one per node)
kubectl get pods -n beszel -l app=beszel-agent

# View agent logs
kubectl logs -n beszel -l app=beszel-agent
```

### 8. Register Systems in Hub

In the Beszel web UI:
1. Go to **Systems** → **Add System**
2. Enter system details:
   - **Name**: Node name (e.g., "k8s-node-1")
   - **Host**: Physical node IP address (NOT cluster internal IP)
   - **Port**: 45876
3. Save the system

The agent should connect automatically using the SSH key.

### 9. Configure Backup

The S3 backup is already configured via environment variables. To verify:

1. In the Beszel web UI, go to **Settings** → **Backup**
2. Verify S3 configuration is detected
3. Test a manual backup
4. Verify backup appears in your S3 bucket
5. Test restore functionality

## Important Notes

### Agent Configuration

- **hostNetwork: true** - Required for accurate physical network metrics
- **No Docker socket** - Container monitoring is disabled
- **Tolerations** - Agents will run on control-plane nodes
- **Port 45876** - Must be accessible from hub to agents

### When Registering Systems

- Use **physical node IP addresses** (e.g., 192.168.1.10)
- Do NOT use cluster internal IPs (e.g., 10.42.x.x)
- Use port **45876**

### Storage

- **PVC Size**: 20Gi (adjust in pvc.yaml if needed)
- **Storage Class**: Uses cluster default (uncomment and specify if needed)
- **Access Mode**: ReadWriteOnce

### Security

- S3 credentials are stored in Kubernetes Secret
- Consider using sealed-secrets or external-secrets for production
- TLS certificate automatically issued by cert-manager
- Agent authentication via SSH keys

### Scaling

- Hub runs as single replica (RWO volume limitation)
- Agents run as DaemonSet (one per node)
- Monitor resource usage and adjust limits if needed

## Troubleshooting

### Hub won't start

```bash
# Check pod status
kubectl describe pod -n beszel -l app=beszel-hub

# Check logs
kubectl logs -n beszel -l app=beszel-hub

# Check PVC binding
kubectl get pvc -n beszel
```

### Can't access web UI

```bash
# Check ingress
kubectl get ingress -n beszel

# Check certificate
kubectl get certificate -n beszel

# Check service
kubectl get svc -n beszel
```

### Agents not connecting

```bash
# Check DaemonSet
kubectl get ds -n beszel

# Check agent logs
kubectl logs -n beszel -l app=beszel-agent

# Verify SSH key is correctly set
kubectl get ds beszel-agent -n beszel -o yaml | grep -A 2 "name: KEY"
```

### S3 backup failing

```bash
# Check secret
kubectl get secret beszel-s3-credentials -n beszel -o yaml

# Check deployment env vars
kubectl get deployment beszel-hub -n beszel -o yaml | grep -A 20 "env:"

# Check hub logs for S3 errors
kubectl logs -n beszel -l app=beszel-hub | grep -i s3
```

## Maintenance

### Update Beszel

```bash
# Update to latest version
kubectl rollout restart deployment beszel-hub -n beszel
kubectl rollout restart daemonset beszel-agent -n beszel

# Check rollout status
kubectl rollout status deployment beszel-hub -n beszel
kubectl rollout status daemonset beszel-agent -n beszel
```

### Backup and Restore

Backups are automatic via S3. To manually trigger:
1. Web UI → Settings → Backup → Manual Backup

To restore:
1. Web UI → Settings → Backup → Restore from Backup

### Monitor Resource Usage

```bash
# Check resource consumption
kubectl top pods -n beszel

# Check PVC usage
kubectl exec -n beszel <hub-pod-name> -- df -h /beszel_data
```

## Resources

- **Official Repo**: https://github.com/henrygd/beszel
- **Documentation**: https://github.com/henrygd/beszel/blob/main/readme.md
- **Docker Hub**: https://hub.docker.com/r/henrygd/beszel

## Support

For issues specific to this Kubernetes deployment, check the manifests in this directory.

For Beszel-specific issues, refer to the official GitHub repository.
