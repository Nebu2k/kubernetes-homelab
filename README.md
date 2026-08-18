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
| 0 | sealed-secrets |
| 1 | metallb, reloader |
| 2 | etcd-backup, metrics-server, rpi5-net-tuning |
| 3 | traefik |
| 4 | cert-manager, longhorn |
| 5 | csi-driver-smb, teslamate |
| 6 | kube-prometheus-stack |
| 7 | blocky, home-assistant, unifi-poller |
| 8 | gatus, ripe-atlas |
| 9 | homepage, mealie, paperless-ngx |
| 11 | backup-monitor, proxmox-exporter, rpi5-fan, security-insights |
| 12 | argocd-config |
| 14 | readsb |
| 15 | fr24, piaware |
| 16 | external-services |

## 📁 Repository Structure

```text
kubernetes-homelab/
├── bootstrap/root-app.yaml    # App-of-Apps, the only thing applied by hand
├── apps/                      # 29 ArgoCD Applications, one per component (waves above)
├── manifests/                 # what those Applications point at
│   ├── argocd/
│   ├── backup-monitor/
│   ├── blocky/
│   ├── cert-manager/
│   ├── csi-driver-smb/
│   ├── etcd-backup/
│   ├── external-services/
│   ├── fr24/
│   ├── gatus/
│   ├── home-assistant/
│   ├── homepage/
│   ├── kube-prometheus-stack/
│   ├── longhorn/
│   ├── mealie/
│   ├── metallb/
│   ├── metrics-server/
│   ├── paperless-ngx/
│   ├── piaware/
│   ├── proxmox-exporter/
│   ├── readsb/
│   ├── reloader/
│   ├── ripe-atlas/
│   ├── rpi5-fan/
│   ├── rpi5-net-tuning/
│   ├── security-insights/
│   ├── teslamate/
│   ├── traefik/
│   └── unifi-poller/
├── talos/                     # machine configs (talhelper), see talos/README.md
├── docs-generator/            # renders this README from templates/README.md.j2
└── reseal-all-secrets.sh      # reseals every *-unsealed.yaml under manifests/
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

### Step 3: Fork & configure the repository (**on your laptop**)

```bash
# Fork https://github.com/Nebu2k/kubernetes-homelab
git clone https://github.com/YOUR_USERNAME/kubernetes-homelab
cd kubernetes-homelab
```

> ⚠️ The repository is pre-configured for `elmstreet79.de` and `192.168.2.0/24`.
> For your own environment adjust the MetalLB pool in
> `manifests/metallb/metallb-ip-pool.yaml` and the domain in
> `manifests/traefik/values.yaml` plus the ingress annotations.

**Prepare the secrets.** Every component that needs credentials ships a
`*-unsealed.yaml.example` template whose header comment explains what belongs in
it. Copy them all, then fill in the ones you actually need:

```bash
for f in manifests/*/*-unsealed.yaml.example; do cp -n "$f" "${f%.example}"; done
```

- **backup-monitor**: s3-backup-monitor-credentials
- **cert-manager**: cloudflare-api-token
- **etcd-backup**: s3-credentials
- **fr24**: fr24-secret
- **home-assistant**: s3-archive-credentials, wol-ssh-key
- **kube-prometheus-stack**: alertmanager-notifications, aws-credentials, grafana-admin, home-assistant-token
- **longhorn**: nas-cifs-secret
- **mealie**: mealie-backup-token, mealie-secrets, s3-mealie-backup-credentials
- **paperless-ngx**: paperless-secrets, s3-backup-credentials, smb-credentials
- **piaware**: piaware-secret
- **proxmox-exporter**: pve-api-credentials
- **readsb**: feeder-uuid-secret, readsb-secret
- **security-insights**: cloudflare-insights-token
- **teslamate**: s3-backup-credentials, teslamate-secret
- **unifi-poller**: unifi-config

Sealing happens after the cluster runs (Step 5), so leave them unsealed for now.

⚠️ `*-unsealed.yaml` files are gitignored, and they are the only reseal source
you will ever have: a SealedSecret cannot be decrypted back. Keep them.

```bash
git add -A && git commit -m "Configure for my environment" && git push
```

### Step 4: Bootstrap GitOps (**on your laptop**)

```bash
kubectl apply -f bootstrap/root-app.yaml
kubectl get applications -n argocd -w   # ~5-10 minutes
```

Sealed Secrets installs first (Wave 0), the rest follows in wave order. Apps
whose secrets are still missing stay "Progressing" until the next step.

### Step 5: Seal the secrets (**on your laptop**, after Step 4)

```bash
kubectl wait --for=condition=available --timeout=300s \
  deployment/sealed-secrets-controller -n kube-system

./reseal-all-secrets.sh
```

The script walks every `*-unsealed.yaml` under `manifests/` and seals it against
the running controller. It is the same command for the initial seal and for
every later rotation, so there is no list of per-secret commands to keep in sync.

```bash
git add manifests/*/*-sealed.yaml
git commit -m "🔐 Add sealed secrets" && git push
```

ℹ️ **Why no offline certificate?** `kubeseal` can also seal against a public
certificate fetched with `kubeseal --fetch-cert`, which works without cluster
access. This repo deliberately does not keep one: the controller rotates its
sealing key every 30 days, a checked-out certificate silently goes stale, and
sealing against a months-old key still succeeds without any error. Always seal
against the live controller.

### Step 6: Homepage widgets (**on your laptop**, after the services are up)

The Homepage widget secrets are the exception to Step 5: they hold tokens that
only exist once the services they talk to are running (Grafana admin password,
ArgoCD token, Proxmox and UniFi API tokens, Plex token).

```bash
vim manifests/homepage/argocd-token-secret-unsealed.yaml
vim manifests/homepage/grafana-credentials-unsealed.yaml
vim manifests/homepage/plex-token-unsealed.yaml
vim manifests/homepage/proxmox-secret-unsealed.yaml
vim manifests/homepage/unifi-token-unsealed.yaml

./reseal-all-secrets.sh

git add manifests/homepage/*-sealed.yaml
git commit -m "Add Homepage widget credentials" && git push
```

⚠️ If you rebuild the cluster, these credentials change and have to be resealed.

### Step 7: Verify

```bash
kubectl get applications -n argocd        # all Synced + Healthy
kubectl get svc -n traefik                # EXTERNAL-IP 192.168.2.250
kubectl get ingress -A
```

### Step 8: Access the UIs

ℹ️ **Exposure model**: Traefik (MetalLB LoadBalancer `192.168.2.250`) is the single ingress for cluster and external hosts, routing by SNI/Host. TLS is one wildcard cert `*.elmstreet79.de` from cert-manager (Let's Encrypt DNS-01 via Cloudflare), served as the Traefik default.

- **Public**: host has a Cloudflare CNAME → `nebu2k.ipv64.net`, managed in Terraform. One router port-forward (80+443 → `192.168.2.250`) covers all public hosts.
- **Internal/VPN-only**: no Cloudflare record. Reached via split-horizon DNS (wildcard rewrite `*.elmstreet79.de → 192.168.2.250`) over LAN/WireGuard.

| Service | URL | Notes |
|---------|-----|-------|
| ArgoCD | `https://argocd.elmstreet79.de` | user `admin`, initial password below |
| Homepage | `https://home.elmstreet79.de` | dashboard, ingress auto-discovery, service widgets |
| Gatus | `https://status.elmstreet79.de` | blackbox checks from `manifests/gatus/configmap.yaml` |
| Longhorn | `https://longhorn.elmstreet79.de` | storage, backups |
| Grafana | `https://grafana.elmstreet79.de` | dashboards for everything below |

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

⚠️ Change it (User Info → Update Password), then
`kubectl -n argocd delete secret argocd-initial-admin-secret`.

Gatus does **not** alert by itself: it exports Prometheus metrics, the rules live
in the `gatus` group of `manifests/kube-prometheus-stack/prometheus-rules.yaml`.

**Which services are public:** a service is public exactly when it has a
Cloudflare record, there is no wildcard A-record. Today that is `www`,
`homeassistant`, `teslamate`, `plex` and `dreambox`; the apex 301-redirects to
`www`, and Plex additionally has a direct `32400` port-forward for native apps.
Everything else (ArgoCD, Grafana, Prometheus, Alertmanager, Longhorn, Gatus,
Homepage, Paperless, plus external hosts like `unifi`, `pve`, `nas`) is
internal. To publish a service, add its host to `public_hosts` in
`homelab-terraform/cloudflare/` and `terraform apply`. Nothing else, the single
port-forward covers all.

## 🔧 Management

### Update a component

Chart and image versions are updated by Renovate, which opens a PR per component;
merging it is the normal path. For a manual change edit the values file, commit,
and ArgoCD picks it up:

```bash
vim manifests/traefik/values.yaml
git commit -am "Traefik: 2 replicas" && git push
kubectl get application traefik -n argocd -w
```

### Rotate a secret

```bash
vim manifests/cert-manager/cloudflare-api-token-unsealed.yaml
./reseal-all-secrets.sh
git commit -am "Rotate Cloudflare API token" && git push
```

Reloader restarts the workloads whose Secret or ConfigMap changed, so no manual
rollout is needed.

### Sync and refresh

```bash
kubectl get applications -n argocd
kubectl describe application <app> -n argocd

argocd app sync <app>

# Stuck diff or a CRD ArgoCD refuses to re-read: force a hard refresh,
# this re-renders the manifests instead of using the cached ones
kubectl annotate application <app> -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite
```

## 🐛 Troubleshooting

### MetalLB assigns no IP

```bash
kubectl logs -n metallb-system -l app.kubernetes.io/component=speaker --tail=-1
```

`"error":"assigned IP not allowed by config"` means the L2Advertisement or the
pool in `manifests/metallb/metallb-ip-pool.yaml` does not cover the requested
address.

### A widget or workload rejects its credentials

The sealed secret decrypts into a normal Secret, so read the value the workload
actually sees and compare it against the source:

```bash
kubectl get secret <name> -n <namespace> \
  -o jsonpath='{.data.<key>}' | base64 -d && echo
```

If it is wrong, fix the `*-unsealed.yaml` and reseal (see above). If the Secret
does not exist at all, the SealedSecret was sealed against a different cluster
or an expired key, the controller logs say which.

## 📚 Components

| Component | Version |
|-----------|---------|
| Blocky | v0.34.0 |
| Cert Manager | v1.21.1 |
| csi-driver-smb | 1.20.3 |
| FR24 | latest-build-858 |
| Gatus | v5.36.0 |
| Home Assistant | 2026.8.2 |
| Homepage | v2.0.0 |
| kube-prometheus-stack | 88.3.0 |
| Longhorn | 1.12.1 |
| Mealie | v3.23.1 |
| MetalLB | 0.16.1 |
| Metrics Server | 3.13.1 |
| paperless-ngx | 3.0.5 |
| PiAware | latest-build-666 |
| Proxmox Exporter | 1.0.8 |
| readsb | latest-build-845 |
| Reloader | 2.2.16 |
| RIPE Atlas | 5120 |
| Sealed Secrets | 2.19.1 |
| TeslaMate | 4.1.1 |
| Traefik | 41.2.0 |
| UniFi Poller | v3.4.1 |
| Talos Linux | v1.13.8 |
| Kubernetes | v1.36.3 |
| ArgoCD | v3.5.0 (via Terraform) |

## 📖 Documentation

- [Blocky](https://0xerr0r.github.io/blocky/latest/)
- [Cert Manager](https://charts.jetstack.io)
- [csi-driver-smb](https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts)
- [Gatus](https://github.com/TwiN/gatus)
- [Home Assistant](https://www.home-assistant.io/docs/)
- [Homepage](https://gethomepage.dev/latest/)
- [kube-prometheus-stack](https://prometheus-community.github.io/helm-charts)
- [Longhorn](https://charts.longhorn.io)
- [MetalLB](https://metallb.github.io/metallb)
- [Metrics Server](https://kubernetes-sigs.github.io/metrics-server/)
- [Proxmox Exporter](https://github.com/prometheus-pve/prometheus-pve-exporter)
- [Reloader](https://stakater.github.io/stakater-charts)
- [Sealed Secrets](https://bitnami.github.io/sealed-secrets/)
- [talhelper](https://budimanjojo.github.io/talhelper/)
- [Talos Linux](https://www.talos.dev/latest/)
- [TeslaMate](https://docs.teslamate.org/)
- [Traefik](https://traefik.github.io/charts)
- [UniFi Poller](https://unpoller.com/)

## 📝 License

MIT

---

> 🤖 **This README is auto-generated** from `docs-generator/templates/README.md.j2`.
> Regenerate with `make docs`. Editing it directly is pointless:
> `.github/workflows/docs.yml` overwrites it on every push to main.