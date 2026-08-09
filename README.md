# Kubernetes Homelab - GitOps with ArgoCD

Talos Linux cluster managed via GitOps using the ArgoCD App-of-Apps pattern.

## 🎯 Architecture

**Key Principle**: ArgoCD manages everything EXCEPT itself (prevents self-management conflicts).

### Deployment Flow

```text
1. Manual: Talos machine configs (talhelper) → HA control plane, VIP built in
2. Manual: ArgoCD via Terraform (homelab-terraform/argocd-talos) → GitOps engine
3. GitOps: bootstrap/root-app.yaml → App-of-Apps
4. GitOps: Everything else deployed automatically with Sync-Waves
```

### Sync-Wave Order

| Wave | Component |
|------|-----------|
| 0 | Sealed Secrets |
| 1 | Metallb, Reloader |
| 2 | Etcd Backup, Kube Router, Metrics Server, Rpi5 Net Tuning |
| 3 | Traefik |
| 4 | Cert Manager, Longhorn |
| 5 | Csi Driver Smb, Landing Page, Teslamate |
| 6 | Kube Prometheus Stack |
| 7 | Blocky, Home Assistant, Unifi Poller |
| 8 | Gatus, Ripe Atlas |
| 9 | Homepage, Mealie, Paperless Ngx |
| 11 | Backup Monitor, Proxmox Exporter, Rpi5 Fan |
| 12 | Argocd Config |
| 14 | Readsb |
| 15 | Fr24 |
| 16 | External Services |

## 📁 Repository Structure

```text
homelab/
├── bootstrap/
│   └── root-app.yaml              # App-of-Apps (deploys everything)
├── apps/
│   ├── kustomization.yaml         # List of all apps
│   ├── sealed-secrets.yaml            # Wave 0
│   ├── metallb.yaml                   # Wave 1
│   ├── reloader.yaml                  # Wave 1
│   ├── etcd-backup.yaml               # Wave 2
│   ├── kube-router.yaml               # Wave 2
│   ├── metrics-server.yaml            # Wave 2
│   ├── rpi5-net-tuning.yaml           # Wave 2
│   ├── traefik.yaml                   # Wave 3
│   ├── cert-manager.yaml              # Wave 4
│   ├── longhorn.yaml                  # Wave 4
│   ├── csi-driver-smb.yaml            # Wave 5
│   ├── landing-page.yaml              # Wave 5
│   ├── teslamate.yaml                 # Wave 5
│   ├── kube-prometheus-stack.yaml     # Wave 6
│   ├── blocky.yaml                    # Wave 7
│   ├── home-assistant.yaml            # Wave 7
│   ├── unifi-poller.yaml              # Wave 7
│   ├── gatus.yaml                     # Wave 8
│   ├── ripe-atlas.yaml                # Wave 8
│   ├── homepage.yaml                  # Wave 9
│   ├── mealie.yaml                    # Wave 9
│   ├── paperless-ngx.yaml             # Wave 9
│   ├── backup-monitor.yaml            # Wave 11
│   ├── proxmox-exporter.yaml          # Wave 11
│   ├── rpi5-fan.yaml                  # Wave 11
│   ├── argocd-config.yaml             # Wave 12
│   ├── readsb.yaml                    # Wave 14
│   ├── fr24.yaml                      # Wave 15
│   └── external-services.yaml         # Wave 16
├── manifests/
│   ├── argocd/
│   │   ├── argocd-cm-patch.yaml
│   │   ├── argocd-rbac-cm-patch.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   ├── backup-monitor/
│   │   ├── freshness-cronjob.yaml
│   │   ├── kustomization.yaml
│   │   ├── s3-backup-monitor-credentials-sealed.yaml
│   │   └── s3-backup-monitor-credentials-unsealed.yaml.example
│   ├── blocky/
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── poddisruptionbudget.yaml
│   │   ├── service.yaml
│   │   └── servicemonitor.yaml
│   ├── cert-manager/
│   │   ├── cloudflare-api-token-sealed.yaml
│   │   ├── cloudflare-api-token-unsealed.yaml.example
│   │   ├── cluster-issuer.yaml
│   │   ├── kustomization.yaml
│   │   ├── tls-store.yaml
│   │   ├── values.yaml
│   │   └── wildcard-certificate.yaml
│   ├── csi-driver-smb/
│   │   └── values.yaml
│   ├── etcd-backup/
│   │   ├── cronjob.yaml
│   │   ├── kustomization.yaml
│   │   ├── s3-credentials-sealed.yaml
│   │   ├── s3-credentials-unsealed.yaml.example
│   │   └── talos-service-account.yaml
│   ├── external-services/
│   │   ├── adguard-macmini-service.yaml
│   │   ├── adguard-pve-service.yaml
│   │   ├── adguardhome-sync-config.yaml
│   │   ├── adguardhome-sync-credentials-sealed.yaml
│   │   ├── adguardhome-sync-deployment.yaml
│   │   ├── adguardhome-sync-service.yaml
│   │   ├── adguardhome-sync-web-ingress.yaml
│   │   ├── dreambox-service.yaml
│   │   ├── external-ingressroutes.yaml
│   │   ├── glances-macmini-service.yaml
│   │   ├── kustomization.yaml
│   │   ├── plex-service.yaml
│   │   ├── proxmox-service.yaml
│   │   ├── unifi-nas-service.yaml
│   │   ├── unifi-service.yaml
│   │   └── vscode-service.yaml
│   ├── fr24/
│   │   ├── deployment.yaml
│   │   ├── fr24-secret-sealed.yaml
│   │   ├── fr24-secret-unsealed.yaml.example
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   └── service.yaml
│   ├── gatus/
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── dns-v6-relay.yaml
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── pvc.yaml
│   │   ├── service.yaml
│   │   └── servicemonitor.yaml
│   ├── home-assistant/
│   │   ├── backup-archive-cronjob.yaml
│   │   ├── configmap-configuration.yaml
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   ├── matter-pvc.yaml
│   │   ├── namespace.yaml
│   │   ├── pv.yaml
│   │   ├── pvc.yaml
│   │   ├── s3-archive-credentials-sealed.yaml
│   │   ├── s3-archive-credentials-unsealed.yaml.example
│   │   └── service.yaml
│   ├── homepage/
│   │   ├── adguard-credentials-sealed.yaml
│   │   ├── adguard-credentials-unsealed.yaml.example
│   │   ├── argocd-token-secret-sealed.yaml
│   │   ├── argocd-token-secret-unsealed.yaml.example
│   │   ├── clusterrole.yaml
│   │   ├── clusterrolebinding.yaml
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── grafana-credentials-sealed.yaml
│   │   ├── grafana-credentials-unsealed.yaml.example
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── plex-token-sealed.yaml
│   │   ├── plex-token-unsealed.yaml.example
│   │   ├── proxmox-secret-sealed.yaml
│   │   ├── proxmox-secret-unsealed.yaml.example
│   │   ├── service.yaml
│   │   ├── serviceaccount.yaml
│   │   ├── unifi-token-sealed.yaml
│   │   └── unifi-token-unsealed.yaml.example
│   ├── kube-prometheus-stack/
│   │   ├── alertmanager-ingress.yaml
│   │   ├── aws-credentials-sealed.yaml
│   │   ├── aws-credentials-unsealed.yaml.example
│   │   ├── blocky-lxc-scrapeconfig.yaml
│   │   ├── etcd-scrapeconfig.yaml
│   │   ├── grafana-admin-sealed.yaml
│   │   ├── grafana-admin-unsealed.yaml.example
│   │   ├── grafana-ingress.yaml
│   │   ├── home-assistant-scrapeconfig.yaml
│   │   ├── home-assistant-token-sealed.yaml
│   │   ├── home-assistant-token-unsealed.yaml.example
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── node-exporter-external-scrapeconfig.yaml
│   │   ├── prometheus-ingress.yaml
│   │   ├── prometheus-rules.yaml
│   │   └── values.yaml
│   ├── kube-router/
│   │   ├── daemonset.yaml
│   │   ├── kustomization.yaml
│   │   ├── rbac.yaml
│   │   ├── service.yaml
│   │   └── servicemonitor.yaml
│   ├── landing-page/
│   │   ├── apex-redirect.yaml
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   └── service.yaml
│   ├── longhorn/
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   ├── nas-cifs-secret-sealed.yaml
│   │   ├── nas-cifs-secret-unsealed.yaml.example
│   │   ├── node-config.yaml
│   │   ├── recurring-backup-jobs.yaml
│   │   ├── servicemonitor.yaml
│   │   └── values.yaml
│   ├── mealie/
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   ├── mealie-secrets-sealed.yaml
│   │   ├── mealie-secrets-unsealed.yaml.example
│   │   ├── namespace.yaml
│   │   ├── networkpolicy.yaml
│   │   ├── postgresql.yaml
│   │   ├── pv.yaml
│   │   ├── pvc.yaml
│   │   └── service.yaml
│   ├── metallb/
│   │   ├── kustomization.yaml
│   │   ├── metallb-ip-pool.yaml
│   │   └── values.yaml
│   ├── metrics-server/
│   │   └── values.yaml
│   ├── paperless-ngx/
│   │   ├── backup-cronjob.yaml
│   │   ├── db-pvc.yaml
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── networkpolicy.yaml
│   │   ├── paperless-secrets-sealed.yaml
│   │   ├── paperless-secrets-unsealed.yaml.example
│   │   ├── postgresql.yaml
│   │   ├── pv.yaml
│   │   ├── pvc.yaml
│   │   ├── redis.yaml
│   │   ├── s3-backup-credentials-sealed.yaml
│   │   ├── s3-backup-credentials-unsealed.yaml.example
│   │   ├── service.yaml
│   │   ├── smb-consume-pv.yaml
│   │   ├── smb-credentials-sealed.yaml
│   │   └── smb-credentials-unsealed.yaml.example
│   ├── proxmox-exporter/
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml
│   │   ├── pve-api-credentials-sealed.yaml
│   │   ├── pve-api-credentials-unsealed.yaml.example
│   │   ├── service.yaml
│   │   └── servicemonitor.yaml
│   ├── readsb/
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── readsb-secret-sealed.yaml
│   │   ├── readsb-secret-unsealed.yaml.example
│   │   └── service.yaml
│   ├── reloader/
│   │   └── values.yaml
│   ├── ripe-atlas/
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── pv.yaml
│   │   └── pvc.yaml
│   ├── rpi5-fan/
│   │   ├── daemonset.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── service.yaml
│   │   └── servicemonitor.yaml
│   ├── rpi5-net-tuning/
│   │   ├── daemonset.yaml
│   │   ├── kustomization.yaml
│   │   └── namespace.yaml
│   ├── teslamate/
│   │   ├── backup-cronjob.yaml
│   │   ├── database-deployment.yaml
│   │   ├── database-pdb.yaml
│   │   ├── database-pvc.yaml
│   │   ├── database-service.yaml
│   │   ├── grafana-deployment.yaml
│   │   ├── grafana-ingress.yaml
│   │   ├── grafana-pvc.yaml
│   │   ├── grafana-service.yaml
│   │   ├── kustomization.yaml
│   │   ├── mosquitto-deployment.yaml
│   │   ├── mosquitto-pvc.yaml
│   │   ├── mosquitto-service.yaml
│   │   ├── namespace.yaml
│   │   ├── networkpolicy.yaml
│   │   ├── postgres-exporter-deployment.yaml
│   │   ├── postgres-exporter-service.yaml
│   │   ├── postgres-exporter-servicemonitor.yaml
│   │   ├── pv.yaml
│   │   ├── s3-backup-credentials-sealed.yaml
│   │   ├── s3-backup-credentials-unsealed.yaml.example
│   │   ├── teslamate-deployment.yaml
│   │   ├── teslamate-ingress.yaml
│   │   ├── teslamate-secret-sealed.yaml
│   │   ├── teslamate-secret-unsealed.yaml.example
│   │   └── teslamate-service.yaml
│   ├── traefik/
│   │   └── values.yaml
│   └── unifi-poller/
│       ├── deployment.yaml
│       ├── kustomization.yaml
│       ├── service.yaml
│       ├── servicemonitor.yaml
│       ├── unifi-config-sealed.yaml
│       └── unifi-config-unsealed.yaml.example
└── talos/
    ├── README.md                  # Bedienung, Restore-Rezept, Fallen
    ├── talconfig.yaml             # Quelle der machine configs (talhelper)
    └── talsecret.sops.yaml        # Secrets-Bundle, SOPS-verschluesselt
```

## 🚀 Fresh Installation

### Prerequisites

- 3+ nodes running [Talos Linux](https://www.talos.dev/) (no SSH, no package manager, everything in the machine config)
- Domain on Cloudflare (DNS-01 challenge + public records)
- Cloudflare API token (for cert-manager DNS-01 wildcard TLS certificates)
- CIFS or S3 target for Longhorn backups
- `talosctl`, `talhelper`, `kubectl`, `kustomize`, `kubeseal`, `sops`, `age`

### Step 1: Build the cluster (**Talos**)

The machine configs are generated from a single `talos/talconfig.yaml` by
[talhelper](https://github.com/budimanjojo/talhelper); the generated files and
the secrets bundle are never edited by hand.

```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
cd talos && talhelper genconfig

talosctl apply-config --insecure --nodes <dhcp-ip> \
  --file clusterconfig/homelab-talos-cp-1.yaml
talosctl bootstrap --nodes <node-ip>   # exactly once for the whole cluster
talosctl kubeconfig --nodes <node-ip>
```

ℹ️ **Everything worth knowing about this cluster lives in
[`talos/README.md`](talos/README.md)**: node roles and the image factory
schematic, how to restore a Longhorn volume from the NAS backup, and the traps
that cost time (PodSecurity `baseline` rejects more than you expect, MetalLB
needs `speaker.ignoreExcludeLB` on an all-control-plane cluster, only one volume
restore at a time). It is not repeated here so the two cannot drift apart.

### Step 2: Install ArgoCD (**on your laptop, via Terraform**)

ArgoCD manages everything except itself, so it is the one component that does
not come from this repo. It is a `helm_release` in its own Terraform stack with
its own state key, `homelab-terraform/argocd-talos/`:

```bash
cd homelab-terraform/argocd-talos
terraform init && terraform apply
```

Terraform always sends the full value set and knows no `--reuse-values`, which
is what makes a chart major upgrade predictable.

### Step 3: Fork & Configure Repository (**on your laptop**)

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

2. **Cloudflare API Token** (required, for cert-manager DNS-01):

   ```bash
   # Create from example
   cp manifests/cert-manager/cloudflare-api-token-unsealed.yaml.example \
      manifests/cert-manager/cloudflare-api-token-unsealed.yaml

   # Add your Cloudflare API token (Zone:DNS:Edit on your zone)
   vim manifests/cert-manager/cloudflare-api-token-unsealed.yaml

   # Note: Sealing happens AFTER cluster bootstrap (Step 4.5)
   # For now, keep it unsealed locally (gitignored)
   ```

3. **All other secrets** (each optional, depending on which apps you keep):

   Every component that needs credentials ships a `.example` template. Copy the
   ones you need, fill them in, and leave them unsealed for now. Each file's
   header comment explains what belongs in it.

   ```bash
   cp manifests/backup-monitor/s3-backup-monitor-credentials-unsealed.yaml.example \
      manifests/backup-monitor/s3-backup-monitor-credentials-unsealed.yaml
   cp manifests/etcd-backup/s3-credentials-unsealed.yaml.example \
      manifests/etcd-backup/s3-credentials-unsealed.yaml
   cp manifests/fr24/fr24-secret-unsealed.yaml.example \
      manifests/fr24/fr24-secret-unsealed.yaml
   cp manifests/home-assistant/s3-archive-credentials-unsealed.yaml.example \
      manifests/home-assistant/s3-archive-credentials-unsealed.yaml
   cp manifests/kube-prometheus-stack/aws-credentials-unsealed.yaml.example \
      manifests/kube-prometheus-stack/aws-credentials-unsealed.yaml
   cp manifests/kube-prometheus-stack/grafana-admin-unsealed.yaml.example \
      manifests/kube-prometheus-stack/grafana-admin-unsealed.yaml
   cp manifests/kube-prometheus-stack/home-assistant-token-unsealed.yaml.example \
      manifests/kube-prometheus-stack/home-assistant-token-unsealed.yaml
   cp manifests/longhorn/nas-cifs-secret-unsealed.yaml.example \
      manifests/longhorn/nas-cifs-secret-unsealed.yaml
   cp manifests/mealie/mealie-secrets-unsealed.yaml.example \
      manifests/mealie/mealie-secrets-unsealed.yaml
   cp manifests/paperless-ngx/paperless-secrets-unsealed.yaml.example \
      manifests/paperless-ngx/paperless-secrets-unsealed.yaml
   cp manifests/paperless-ngx/s3-backup-credentials-unsealed.yaml.example \
      manifests/paperless-ngx/s3-backup-credentials-unsealed.yaml
   cp manifests/paperless-ngx/smb-credentials-unsealed.yaml.example \
      manifests/paperless-ngx/smb-credentials-unsealed.yaml
   cp manifests/proxmox-exporter/pve-api-credentials-unsealed.yaml.example \
      manifests/proxmox-exporter/pve-api-credentials-unsealed.yaml
   cp manifests/readsb/readsb-secret-unsealed.yaml.example \
      manifests/readsb/readsb-secret-unsealed.yaml
   cp manifests/teslamate/s3-backup-credentials-unsealed.yaml.example \
      manifests/teslamate/s3-backup-credentials-unsealed.yaml
   cp manifests/teslamate/teslamate-secret-unsealed.yaml.example \
      manifests/teslamate/teslamate-secret-unsealed.yaml
   cp manifests/unifi-poller/unifi-config-unsealed.yaml.example \
      manifests/unifi-poller/unifi-config-unsealed.yaml

   # Then edit each copy and replace the placeholder values.
   # Sealing happens AFTER cluster bootstrap (Step 4.5).
   ```

   ⚠️ **Note:** `*-unsealed.yaml` files are gitignored for security. Only `.example` templates are committed. They are also the only reseal source you will ever have, since SealedSecrets cannot be decrypted back.

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

### Step 4: Bootstrap GitOps (**on your laptop**)

```bash
# Deploy App-of-Apps
kubectl apply -f bootstrap/root-app.yaml

# Watch ArgoCD deploy everything (~5-10 minutes)
kubectl get applications -n argocd -w
```

**What happens:**

- Sealed Secrets Controller installs first (Sync-Wave 0)
- MetalLB, Traefik, cert-manager, etc. follow in order
- Some apps will stay "Progressing" until secrets are sealed (next step)

### Step 4.5: Seal Secrets (**on your laptop** - AFTER Step 4)

⚠️ **Wait until Sealed Secrets Controller is ready:**

```bash
# Check if controller is running
kubectl wait --for=condition=available --timeout=300s \
  deployment/sealed-secrets-controller -n kube-system
```

**Seal every secret you created in Step 3** (requires cluster access):

```bash
# 1. backup-monitor: s3 backup monitor credentials
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/backup-monitor/s3-backup-monitor-credentials-unsealed.yaml \
  > manifests/backup-monitor/s3-backup-monitor-credentials-sealed.yaml

# 2. cert-manager: cloudflare api token
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/cert-manager/cloudflare-api-token-unsealed.yaml \
  > manifests/cert-manager/cloudflare-api-token-sealed.yaml

# 3. etcd-backup: s3 credentials
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/etcd-backup/s3-credentials-unsealed.yaml \
  > manifests/etcd-backup/s3-credentials-sealed.yaml

# 4. fr24: fr24 secret
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/fr24/fr24-secret-unsealed.yaml \
  > manifests/fr24/fr24-secret-sealed.yaml

# 5. home-assistant: s3 archive credentials
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/home-assistant/s3-archive-credentials-unsealed.yaml \
  > manifests/home-assistant/s3-archive-credentials-sealed.yaml

# 6. kube-prometheus-stack: aws credentials
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/kube-prometheus-stack/aws-credentials-unsealed.yaml \
  > manifests/kube-prometheus-stack/aws-credentials-sealed.yaml

# 7. kube-prometheus-stack: grafana admin
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/kube-prometheus-stack/grafana-admin-unsealed.yaml \
  > manifests/kube-prometheus-stack/grafana-admin-sealed.yaml

# 8. kube-prometheus-stack: home assistant token
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/kube-prometheus-stack/home-assistant-token-unsealed.yaml \
  > manifests/kube-prometheus-stack/home-assistant-token-sealed.yaml

# 9. longhorn: nas cifs secret
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/longhorn/nas-cifs-secret-unsealed.yaml \
  > manifests/longhorn/nas-cifs-secret-sealed.yaml

# 10. mealie: mealie secrets
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/mealie/mealie-secrets-unsealed.yaml \
  > manifests/mealie/mealie-secrets-sealed.yaml

# 11. paperless-ngx: paperless secrets
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/paperless-ngx/paperless-secrets-unsealed.yaml \
  > manifests/paperless-ngx/paperless-secrets-sealed.yaml

# 12. paperless-ngx: s3 backup credentials
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/paperless-ngx/s3-backup-credentials-unsealed.yaml \
  > manifests/paperless-ngx/s3-backup-credentials-sealed.yaml

# 13. paperless-ngx: smb credentials
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/paperless-ngx/smb-credentials-unsealed.yaml \
  > manifests/paperless-ngx/smb-credentials-sealed.yaml

# 14. proxmox-exporter: pve api credentials
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/proxmox-exporter/pve-api-credentials-unsealed.yaml \
  > manifests/proxmox-exporter/pve-api-credentials-sealed.yaml

# 15. readsb: readsb secret
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/readsb/readsb-secret-unsealed.yaml \
  > manifests/readsb/readsb-secret-sealed.yaml

# 16. teslamate: s3 backup credentials
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/teslamate/s3-backup-credentials-unsealed.yaml \
  > manifests/teslamate/s3-backup-credentials-sealed.yaml

# 17. teslamate: teslamate secret
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/teslamate/teslamate-secret-unsealed.yaml \
  > manifests/teslamate/teslamate-secret-sealed.yaml

# 18. unifi-poller: unifi config
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/unifi-poller/unifi-config-unsealed.yaml \
  > manifests/unifi-poller/unifi-config-sealed.yaml

```

Or reseal all of them at once with `./reseal-all-secrets.sh`, which walks every
`*-unsealed.yaml` under `manifests/` and does exactly the above.

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

ℹ️ **Why no offline certificate?** `kubeseal` can also seal against a public certificate file fetched with `kubeseal --fetch-cert`, which works without cluster access. This repo deliberately does not keep one: the controller rotates its sealing key every 30 days, a checked-out certificate silently goes stale, and sealing against a months-old key still succeeds without any error. Always seal against the live controller.

### Step 4.6: Configure Homepage Widgets (**on your laptop** - AFTER Grafana is ready)

**Create sealed secrets for Homepage widgets:**

⚠️ **Important:** For each widget secret, copy the example file, edit with your credentials, then seal it.

```bash

# 1. Adguard Credentials
cp manifests/homepage/adguard-credentials-unsealed.yaml.example \
   manifests/homepage/adguard-credentials-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/adguard-credentials-unsealed.yaml

# Seal the secret
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/homepage/adguard-credentials-unsealed.yaml \
  > manifests/homepage/adguard-credentials-sealed.yaml


# 2. Argocd Token Secret
cp manifests/homepage/argocd-token-secret-unsealed.yaml.example \
   manifests/homepage/argocd-token-secret-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/argocd-token-secret-unsealed.yaml

# Seal the secret
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/homepage/argocd-token-secret-unsealed.yaml \
  > manifests/homepage/argocd-token-secret-sealed.yaml


# 3. Grafana Credentials
cp manifests/homepage/grafana-credentials-unsealed.yaml.example \
   manifests/homepage/grafana-credentials-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/grafana-credentials-unsealed.yaml

# Seal the secret
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/homepage/grafana-credentials-unsealed.yaml \
  > manifests/homepage/grafana-credentials-sealed.yaml


# 4. Plex Token
cp manifests/homepage/plex-token-unsealed.yaml.example \
   manifests/homepage/plex-token-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/plex-token-unsealed.yaml

# Seal the secret
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/homepage/plex-token-unsealed.yaml \
  > manifests/homepage/plex-token-sealed.yaml


# 5. Proxmox Secret
cp manifests/homepage/proxmox-secret-unsealed.yaml.example \
   manifests/homepage/proxmox-secret-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/proxmox-secret-unsealed.yaml

# Seal the secret
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/homepage/proxmox-secret-unsealed.yaml \
  > manifests/homepage/proxmox-secret-sealed.yaml


# 6. Unifi Token
cp manifests/homepage/unifi-token-unsealed.yaml.example \
   manifests/homepage/unifi-token-unsealed.yaml

# Edit the file and replace placeholder values with your actual credentials
vim manifests/homepage/unifi-token-unsealed.yaml

# Seal the secret
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/homepage/unifi-token-unsealed.yaml \
  > manifests/homepage/unifi-token-sealed.yaml


# Commit and push
git add manifests/homepage/*-sealed.yaml
git commit -m "Add Homepage widget credentials"
git push
```

⚠️ **Note:** If you rebuild the cluster, passwords may change (e.g., Grafana admin password), so you'll need to recreate the affected sealed secrets.

### Step 5: Verify Deployment (**on your laptop**)

```bash
# All apps should be Synced + Healthy
kubectl get applications -n argocd

# MetalLB assigned LoadBalancer IP
kubectl get svc -n traefik
# EXTERNAL-IP should show 192.168.2.250

# Ingresses configured
kubectl get ingress -A
```

### Step 6: Access UIs (**from your laptop browser**)

ℹ️ **Exposure model**: Traefik (MetalLB LoadBalancer `192.168.2.250`) is the single ingress for cluster and external hosts, routing by SNI/Host. TLS is one wildcard cert `*.elmstreet79.de` from cert-manager (Let's Encrypt DNS-01 via Cloudflare), served as the Traefik default.

- **Public**: host has a Cloudflare CNAME → `nebu2k.ipv64.net`, managed in Terraform. One router port-forward (80+443 → `192.168.2.250`) covers all public hosts.
- **Internal/VPN-only**: no Cloudflare record. Reached via split-horizon DNS (wildcard rewrite `*.elmstreet79.de → 192.168.2.250`) over LAN/WireGuard.

**ArgoCD:**

```text
URL: https://argocd.elmstreet79.de
User: admin
```

The initial password is generated by ArgoCD:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

⚠️ **Change password immediately!**

1. User Info → Update Password
2. Then delete initial secret:

```bash
kubectl -n argocd delete secret argocd-initial-admin-secret
```

**Longhorn:**

```text
URL: https://longhorn.elmstreet79.de
(internal-only)
```

**Homepage (Homelab Dashboard):**

```text
URL: https://home.elmstreet79.de
```

🏠 **Features:** Unified dashboard with links to all services, real-time Kubernetes cluster metrics, auto-discovery of ingresses, dark theme, widgets for Proxmox/ArgoCD/Grafana

**Gatus (Status Page / Uptime Monitoring):**

```text
URL: https://status.elmstreet79.de
```

📈 **Features:** Blackbox checks (HTTP/TCP/DNS) grouped by failure domain, certificate and domain expiration, uptime history in SQLite. Every check is declared in `manifests/gatus/configmap.yaml`, there is no UI-side state. Alerting does **not** run through Gatus itself: it exports Prometheus metrics and the rules live in the `gatus` group of `manifests/kube-prometheus-stack/prometheus-rules.yaml`.

**Service Access Architecture:**

Everything goes through Traefik (single reverse proxy) with the wildcard TLS default cert. A service is **public exactly when it has a Cloudflare record**. There is no wildcard A-record.

- **Public** (Cloudflare CNAME → `nebu2k.ipv64.net`, managed in the `homelab-terraform` Cloudflare stack): `www`, `homeassistant`, `teslamate`, `plex`, `dreambox`. Apex `elmstreet79.de` 301-redirects to `www`. Plex additionally has a direct `32400` port-forward for native apps.
- **Internal/VPN-only** (no Cloudflare record): everything else, e.g. `argocd`, `grafana`, `prometheus`, `alertmanager`, `longhorn`, `status`, `home`, `paperless`, plus the external hosts (`unifi`, `pve`, `nas`, `vscode`, `adguard`, …).

To make a service public: add its host to `public_hosts` in `homelab-terraform/cloudflare/` and `terraform apply`. Nothing else needed, the single port-forward covers all.

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
# 1. Edit unsealed secret (example: Cloudflare API token)
vim manifests/cert-manager/cloudflare-api-token-unsealed.yaml

# 2. Re-seal against the live controller
kubeseal --format=yaml --controller-namespace=kube-system \
  < manifests/cert-manager/cloudflare-api-token-unsealed.yaml \
  > manifests/cert-manager/cloudflare-api-token-sealed.yaml

# 3. Commit and push
git add manifests/cert-manager/cloudflare-api-token-sealed.yaml
git commit -m "Rotate Cloudflare API token"
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

Re-create the sealed secret as described in Step 4.6.

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
| Blocky | v0.34.0 | Blocky |
| Cert Manager | v1.21.1 | Cert Manager |
| Csi Driver Smb | 1.20.3 | Csi Driver Smb |
| Fr24 | latest-build-858 | Fr24 |
| Gatus | v5.36.0 | Gatus |
| Home Assistant | 2026.7.4 | Home Assistant |
| Homepage | v1.13.2 | Homepage |
| Kube Prometheus Stack | 88.0.1 | Kube Prometheus Stack |
| Landing Page | 1.31.3-alpine | Landing Page |
| Longhorn | 1.12.0 | Longhorn |
| Mealie | v3.22.0 | Mealie |
| Metallb | 0.16.1 | Metallb |
| Metrics Server | 3.13.1 | Metrics Server |
| Paperless Ngx | 3.0.5 | Paperless Ngx |
| Proxmox Exporter | 1.0.8 | Proxmox Exporter |
| Readsb | latest-build-845 | Readsb |
| Reloader | 2.2.14 | Reloader |
| Ripe Atlas | 5120 | Ripe Atlas |
| Sealed Secrets | 2.19.1 | Sealed Secrets |
| Teslamate | 4.0.1 | Teslamate |
| Traefik | 41.1.0 | Traefik |
| Unifi Poller | v3.3.4 | Unifi Poller |
| Talos Linux | v1.13.8 | Immutable node OS, no SSH, no package manager |
| Kubernetes | v1.36.3 | Shipped and managed by Talos |
| ArgoCD | v3.5.0 | Continuous Delivery (installed via Terraform) |

## 📖 Documentation

- [Blocky](https://0xerr0r.github.io/blocky/latest/)
- [Cert Manager](https://charts.jetstack.io)
- [Csi Driver Smb](https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts)
- [Gatus](https://github.com/TwiN/gatus)
- [Home Assistant](https://www.home-assistant.io/docs/)
- [Homepage](https://gethomepage.dev/latest/)
- [Kube Prometheus Stack](https://prometheus-community.github.io/helm-charts)
- [Landing Page](https://github.com/nginx/nginx)
- [Longhorn](https://charts.longhorn.io)
- [Metallb](https://metallb.github.io/metallb)
- [Metrics Server](https://kubernetes-sigs.github.io/metrics-server/)
- [Proxmox Exporter](https://github.com/prometheus-pve/prometheus-pve-exporter)
- [Reloader](https://stakater.github.io/stakater-charts)
- [Sealed Secrets](https://bitnami.github.io/sealed-secrets/)
- [talhelper](https://budimanjojo.github.io/talhelper/)
- [Talos Linux](https://www.talos.dev/latest/)
- [Teslamate](https://docs.teslamate.org/)
- [Traefik](https://traefik.github.io/charts)
- [Unifi Poller](https://unpoller.com/)

## 📝 License

MIT

---

> 🤖 **This README is auto-generated** using `docs-generator/generate_readme.py`  
> To regenerate manually: `make docs`  
> Auto-generation on commit: Enabled via `.githooks/pre-commit` (run `.githooks/install.sh` after clone)
