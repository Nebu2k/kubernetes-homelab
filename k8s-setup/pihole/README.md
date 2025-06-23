# PiHole wit## Configuration

### DNS Configuration

- **DNS Port**: 5353 (for testing, avoids conflicts with existing Docker PiHole)
- **Unbound Port**: 5335 (internal communication)
- **Web Interface Port**: 8080
- **LoadBalancer IP**: 192.168.2.250

### Access

- **DNS Server**: 192.168.2.250:5353
- **Web Interface**: <http://192.168.2.250/admin>up

This directory contains the configuration for PiHole with Unbound DNS resolver.

## Features

- **PiHole**: Network-wide ad blocking
- **Unbound**: Recursive DNS resolver for enhanced privacy and security
- **LoadBalancer Access**: Clean IP-based access via MetalLB
- **Standard DNS Port**: Uses port 53 for DNS (production-ready)
- **Persistent Storage**: Uses Longhorn for data persistence

## Configuration

### DNS Configuration

- **DNS Port**: 53 (standard DNS port)
- **Unbound Port**: 5335 (internal communication)
- **Web Interface Port**: 8080
- **LoadBalancer IP**: 192.168.2.250

### Access

- **DNS Server**: 192.168.2.250:53
- **Web Interface**: http://192.168.2.250/admin

## Installation

```bash
# Install PiHole with Unbound
./install.sh

# Force reinstall if needed
FORCE_INSTALL=true ./install.sh
```

## Usage

### Access Web Interface

1. Access web interface at: <http://192.168.2.250/admin>

2. Get admin password:

   ```bash
   kubectl get secret pihole-admin-password -n pihole -o jsonpath="{.data.password}" | base64 -d
   ```

### Test DNS Resolution

```bash
# Test normal DNS resolution
nslookup google.com 192.168.2.250 -port=5353

# Test ad blocking (should return blocked/NXDOMAIN)
nslookup doubleclick.net 192.168.2.250 -port=5353

# Test with dig
dig @192.168.2.250 -p 5353 google.com
```

### Configure Clients

Point your devices/router to use the PiHole DNS server:

- **DNS Server**: `192.168.2.250:5353` (for testing)

## Production Deployment

To switch from testing (port 5353) to production (port 53):

### Step 1: Stop existing Docker PiHole

```bash
# Stop your existing Docker PiHole on the worker node
docker stop pihole  # or whatever your container name is
```

### Step 2: Update Kubernetes configuration

1. Edit `values.yaml`:

   ```yaml
   pihole:
     dnsmasq:
       port: 53  # Change from 5353 to 53
   
   service:
     dns:
       port: 53  # Change from 5353 to 53
       targetPort: 53
   ```

2. Edit `loadbalancer.yaml`:

   ```yaml
   # Update both TCP and UDP services
   - port: 53        # Change from 5353 to 53
     targetPort: 53  # Change from 5353 to 53
   ```

### Step 3: Apply changes

```bash
# Upgrade Helm release
helm upgrade pihole pihole/pihole \
  --namespace pihole \
  --values values.yaml

# Update LoadBalancer services
kubectl apply -f loadbalancer.yaml
```

### Step 4: Update router configuration

Change your router's DNS settings to: `192.168.2.250` (without port specification)

## Unbound Configuration

The Unbound resolver is configured with:
- **DNSSEC Validation**: Enabled
- **Privacy Features**: Query name minimization, aggressive NSEC
- **Performance Tuning**: Optimized cache sizes and threading
- **Security**: Hardened configuration with anti-spoofing measures

### Custom Unbound Configuration

To modify Unbound settings, edit the `unbound.config` section in `values.yaml`.

## Monitoring

Check PiHole and Unbound status:

```bash
# Check pods
kubectl get pods -n pihole

# Check services
kubectl get svc -n pihole

# View logs
kubectl logs -n pihole deployment/pihole -f

# Check Unbound logs (if separate container)
kubectl logs -n pihole deployment/pihole -c unbound -f
```

## Troubleshooting

### Common Issues

1. **DNS Resolution Fails**:
   ```bash
   # Check if PiHole pod is running
   kubectl get pods -n pihole
   
   # Check service endpoints
   kubectl get endpoints -n pihole
   ```

2. **Web Interface Not Accessible**:
   ```bash
   # Check NodePort service
   kubectl get svc pihole-web -n pihole
   
   # Port forward for local testing
   kubectl port-forward -n pihole svc/pihole-web 8080:8080
   ```

3. **Unbound Not Working**:
   ```bash
   # Check logs for Unbound errors
   kubectl logs -n pihole deployment/pihole -c unbound
   ```

### Reset Admin Password

```bash
# Generate new password
NEW_PASSWORD=$(openssl rand -base64 16)

# Update secret
kubectl patch secret pihole-admin-password -n pihole \
  --type='json' \
  -p='[{"op": "replace", "path": "/data/password", "value":"'$(echo -n $NEW_PASSWORD | base64)'"}]'

# Restart PiHole to pick up new password
kubectl rollout restart deployment/pihole -n pihole

echo "New admin password: $NEW_PASSWORD"
```

## Files

- `install.sh`: Installation script
- `values.yaml`: Helm chart values with PiHole and Unbound configuration
- `loadbalancer.yaml`: LoadBalancer services for DNS and web access
- `README.md`: This documentation file
