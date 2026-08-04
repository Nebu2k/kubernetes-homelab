---
name: homelab
description: Referenzwissen zum elmstreet79.de Kubernetes-Homelab von Sebastian. Nutzen, wenn es um das Homelab geht: welche Dienste extern/intern erreichbar sind, DNS- und TLS-Architektur, GitOps-Deployment-Flow, wie man einen Dienst hinzufügt oder öffentlich macht, das external-services-Muster, Secrets/SealedSecrets, Terraform-Stacks und Netzwerk-Eckdaten. Für den Betrieb (Longhorn und Backups, Renovate- und k3s-Updates, ArgoCD-Eigenheiten, CI, Monitoring, Diagnose-Fallen) zusätzlich references/betrieb.md lesen.
---

# Homelab elmstreet79.de

K3s-HA-Cluster, GitOps über ArgoCD (App-of-Apps). Domain: `elmstreet79.de`.
Repos: `kubernetes-homelab/` (Cluster/GitOps) und `homelab-terraform/` (IaC).
ArgoCD trackt den `main`-Branch von github.com/Nebu2k/kubernetes-homelab.

**Diese Datei hält die Architektur.** Wer etwas betreibt, aktualisiert oder
debuggt, liest zusätzlich `references/betrieb.md`: Longhorn und Backups, Renovate,
k3s- und OS-Updates, ArgoCD-Eigenheiten, node-lokale Konfiguration, CI und
generierte Doku, Monitoring, Terraform-Betriebsregeln, wiederkehrende
Diagnose-Fallen.

Was geplant ist, steht in `ROADMAP.md` (lokal, gitignored). Was sich wann geändert
hat, im `CHANGELOG.md` und in der git-History. Nichts davon hier doppelt pflegen.

## Grundprinzip Exposure

**Ein Dienst ist genau dann öffentlich, wenn er einen Cloudflare-Record hat.**
Kein Record = automatisch nur intern (LAN + UniFi-WireGuard-VPN). Es gibt KEIN
Wildcard-A-Record bei Cloudflare. Alles läuft über EINEN Reverse-Proxy (Traefik)
und EINEN Router-Portforward.

- **Traefik** (MetalLB LoadBalancer `192.168.2.250`) ist der einzige Eingang,
  routet Cluster- UND externe Hosts per SNI/Host-Header.
- **Öffentlich:** UniFi-Portforward nur **80+443 → 192.168.2.250** + Cloudflare-
  **CNAME → `nebu2k.ipv64.net`** (UniFi-DynDNS). Plex hat zusätzlich einen
  direkten **32400**-Portforward (native Apps, eigenes Protokoll).
- **Intern/VPN:** Split-Horizon-DNS, Wildcard-Rewrite `*.elmstreet79.de →
  192.168.2.250` (siehe DNS-Abschnitt).
- **Backends sehen die echte Client-IP** (`externalTrafficPolicy: Local`). Eine
  IP-basierte Regel greift also wirklich, auch gegen externe Nutzer. Vorher
  SNAT-tete kube-proxy alles auf `10.42.6.1` und jede solche Regel war still
  wirkungslos. Traefik läuft ohne `forwardedHeaders.trustedIPs` und überschreibt
  eingehende `X-Forwarded-*`-Header, der Wert ist nicht spoofbar. **`Local` hängt
  an drei weiteren Traefik-Einstellungen, die nicht einzeln angefasst werden
  dürfen: siehe `references/betrieb.md`.**

## Service-Inventar

### Öffentlich erreichbar (Internet)

Cloudflare-CNAME → `nebu2k.ipv64.net`, verwaltet in
`homelab-terraform/terraform/cloudflare/` (Variable `public_hosts`).

| Host | Ziel | Notiz |
|------|------|-------|
| `www.elmstreet79.de` | landing-page (Cluster) | + Apex-Redirect `elmstreet79.de` → www (301) |
| `homeassistant.elmstreet79.de` | home-assistant (Cluster) | |
| `teslamate.elmstreet79.de` | teslamate (Cluster) | |
| `plex.elmstreet79.de` | plex (external-service) | zusätzlich 32400-Portforward für native Apps |
| `dreambox.elmstreet79.de` | dreambox (external-service, https self-signed) | |

Alles andere ist **intern-only**.

### Intern-only Cluster-Dienste

`argocd`, `grafana`, `prometheus`, `alertmanager`, `longhorn`, `portainer`,
`uptime`, `beszel`, `fr24`, `home` (Homepage-Dashboard, NICHT homeassistant),
`teslamate-settings`, `adguardhome-sync-web`, `traefik` (Dashboard).
Sonderfälle:

- `n8n`: bleibt deployed, aber **VPN-only + ungenutzt** (Roadmap: Use-Case finden).
- `paperless`: bewusst **VPN-only** (sensible persönliche Dokumente).

### Intern-only externe Hosts (NICHT im Cluster)

Laufen über das external-services-Muster (siehe unten):
`unifi`, `nas` (UniFi-NAS), `pve` (Proxmox), `vscode`, `glances-macmini`,
`adguard-macmini`, `adguard` (AdGuard-LXC auf pve).

`minio` und `minio-api` sind seit 2026-08-01 raus (Routen, Services, Endpoints,
Homepage-Kachel), seit die Longhorn-Backups per CIFS aufs UniFi-NAS gehen.

## DNS-Architektur (Split-Horizon, zwei Stellen)

Der Wildcard-Rewrite muss an ZWEI Stellen existieren, weil LAN-Clients und
Cluster-Pods unterschiedliche Resolver nutzen:

1. **AdGuard** (Haus-Resolver, LAN + VPN): ein DNS-Rewrite
   `*.elmstreet79.de → 192.168.2.250` auf **beiden** Instanzen (LXC `.16` auf pve
   + macmini `.4`). Wichtig: exakte per-Host-Rewrites schlagen in AdGuard den
   Wildcard, also dürfen keine spezifischen `*.elmstreet79.de`-Einträge daneben
   stehen.
2. **CoreDNS** (Cluster-interne Pods): gespiegelt in
   `manifests/coredns/coredns-custom.yaml` via `template`-Plugin. **FALLE:** der
   Match MUSS einlabelig sein: `^[^.]+\.elmstreet79\.de\.$`. Ein gieriges
   `.+\.elmstreet79\.de\.$` fängt wegen Pod-Search-Domain (`search elmstreet79.de`
   + `ndots:5`) JEDEN externen Host als `<host>.elmstreet79.de` ab und leitet ihn
   auf Traefik, also clusterweit kaputte externe Auflösung (z.B. github.com →
   falsches Cert, ArgoCD kann nicht klonen).

Öffentliche Auflösung: die CNAMEs zeigen auf `nebu2k.ipv64.net`. Intern lösen
dieselben Hosts direkt auf Traefik auf (löst Hairpin-NAT).

DNS-only bei Cloudflare (graue Wolke), KEIN Proxying: Traefik terminiert TLS,
Plex darf ohnehin nicht proxied werden.

## TLS

**cert-manager + Let's Encrypt DNS-01 über Cloudflare.** EIN Wildcard-Cert
`*.elmstreet79.de` + Apex `elmstreet79.de`, als Traefik-Default über `TLSStore`
`default`. Auto-Renew. Weil DNS-01: auch rein interne Hosts bekommen gültige
öffentliche Certs (kein Public-A-Record nötig). Einzelne Ingresses brauchen KEINE
`cert-manager.io`-Annotation und keinen eigenen `tls`-Block, sie nutzen das
Wildcard-Default.

Relevante Dateien: `manifests/cert-manager/` (ClusterIssuer `letsencrypt-prod`,
`wildcard-certificate.yaml`, `tls-store.yaml`, Cloudflare-Token als SealedSecret).

## GitOps-Deployment-Flow

```
1. Manuell: K3s + Kube-VIP (HA Control Plane)
2. Manuell: ArgoCD via Helm
3. GitOps: bootstrap/root-app.yaml (App-of-Apps "homelab")
4. GitOps: apps/*.yaml (ArgoCD Applications) -> manifests/<dienst>/
```

- ArgoCD managt alles AUSSER sich selbst. `apps/kustomization.yaml` listet alle
  Application-Manifeste. Reihenfolge über `argocd.argoproj.io/sync-wave`
  (0 = Sealed-Secrets/CoreDNS, 1 = Reloader/Kured/MetalLB/system-upgrade-controller,
  3 = Traefik, 4 = cert-manager, 5 = csi-driver-smb, höhere Waves = Apps).
- **Änderungen fließen NUR über git → main → ArgoCD.** Nie dauerhaft imperativ
  `kubectl edit`/`apply` (selfHeal revertiert). Ausnahme: wenn GitOps selbst hängt
  (z.B. repo-server kommt nicht an git), direkt applyen und SOFORT committen.
- ArgoCD-Sync manuell antriggern: `kubectl -n argocd annotate application <name>
  argocd.argoproj.io/refresh=hard --overwrite` (root-App heißt `homelab`).
- **`selfHeal` ignoriert die Sync-Waves.** Ein Umbau, bei dem eine App eine andere
  voraussetzt, gehört in mehrere Commits nacheinander. Das und die übrigen
  ArgoCD-Eigenheiten stehen in `references/betrieb.md`.

## Einen neuen Dienst hinzufügen

1. `manifests/<dienst>/` anlegen: deployment, service, ingress (oder IngressRoute)
   + `kustomization.yaml`. Ingress: `ingressClassName: traefik`, Host
   `<dienst>.elmstreet79.de`, KEIN eigener tls-Block (Wildcard-Default greift).
2. `apps/<dienst>.yaml` (ArgoCD Application, passende sync-wave) + Eintrag in
   `apps/kustomization.yaml`.
3. Conventional Commit (`feat(...)`) → push nach `main` → ArgoCD deployt.
4. **Intern-only:** fertig, greift automatisch über den Wildcard-Rewrite.
5. **Öffentlich machen:** Host zu `public_hosts` in
   `homelab-terraform/terraform/cloudflare/variables.tf` hinzufügen, dann
   `terraform apply`. Sonst nichts nötig (ein Portforward deckt alle).

Alle RWO-Workloads bekommen `strategy: Recreate`, sonst blockiert der alte Pod
das Volume. Alles ist Single-Replica; ein Node-Wechsel ist ein Detach/Attach-Zyklus.
Liveness/Readiness-Probes gehören dazu, auch bei TCP-only-Diensten.

## external-services-Muster (Hosts außerhalb des Clusters)

Für unifi, pve, dreambox, plex, nas, adguard, vscode, glances usw. in
`manifests/external-services/`:

- `Service` (ClusterIP, ohne Selector) + manuelle `Endpoints` mit der externen IP.
- `IngressRoute` (Traefik-CRD) mit `entryPoints: [websecure]`, `Host(...)`-Match,
  `tls: {}`. Definiert in `external-ingressroutes.yaml`.
- Bei self-signed-HTTPS-Backends: `scheme: https` + `serversTransport:
  insecure-transport` (ServersTransport mit `insecureSkipVerify: true`, liegt IM
  external-services-Namespace, weil Traefik `allowCrossNamespace: false` hat).
- HTTP-Backends: `scheme: http`, kein serversTransport. Schemes sind NICHT
  einheitlich, pro Backend prüfen (dreambox/unifi/nas/pve = https, Rest = http).

## Secrets

**SealedSecrets** (Bitnami). Public-Cert `sealed-secrets-pub-cert.pem` im
Repo-Root, `reseal-all-secrets.sh` zum Neu-Versiegeln. `*-unsealed.yaml` sind
gitignored (aktive Reseal-Quellen, NICHT löschen, SealedSecrets sind nicht
rückentschlüsselbar). Der private Sealing-Key im Cluster (`sealed-secrets-keys`,
kube-system) ist kritisch, nie löschen.

## Releases

**semantic-release / Conventional Commits.** `feat`/`fix`/`perf` triggern einen
Release, der Release-Bot committet auf `main` (`chore(release): ... [skip ci]`).
Deshalb bei push oft vorher `git pull --rebase origin main` nötig.
Commit-Footer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

Die `README.md` wird generiert (`make docs`), **nie von Hand editieren**. Details
zu CI und Doku-Generierung in `references/betrieb.md`.

## Terraform (homelab-terraform/)

Getrennte Stacks, je eigener S3-State (AWS, Bucket
`homelab-elmstreet79-terraform-state`):

- `terraform/cloudflare/`: öffentliche DNS-Records (5 Public-CNAMEs + Apex →
  `nebu2k.ipv64.net`).
- `terraform/proxmox/`: Proxmox-VMs (bpg/proxmox), wiederverwendbares `vm-module`,
  cloud-init.

Mehr Stacks gibt es nicht, `terraform.tfvars` ist gitignored (CF-Token + Zone-ID).
Betriebsregeln (VMs abbauen, `vm_on_boot`, Provider-Fallen) in
`references/betrieb.md`.

## Netzwerk / Nodes (Eckdaten)

- Traefik LB `192.168.2.250`, MetalLB-Pool `.250-.253` (**IPv4-only**), kube-vip
  Control-Plane-VIP `192.168.2.249`.
- Öffentliche IP über UniFi-DynDNS `nebu2k.ipv64.net`.
- **VPN:** UniFi-WireGuard (bestehend), trägt den internen Zugriff. KEIN
  WireGuard im Cluster gewünscht.
- **IPv6: Public-v6 ist bewusst deaktiviert**, end-to-end. Grund: der ISP-GUA-
  Präfix `2a00:1e:7c41:fb00::` rotiert, eine statische AAAA bräche dabei, und es
  gibt kein v6-DynDNS für den Host-Teil. Abgeschaltet direkt bei ipv64.net
  (UniFi hat keinen v4-only-Toggle), damit liefert `nebu2k.ipv64.net` nur A und
  die CNAMEs erben das. Intern deshalb ULA `fd2e:9a71:c3b5::/64`. Reaktivierung
  nur sinnvoll, wenn der Präfix stabil wird.
- k3s: 3 etcd-Member (`k3s-cp-1` + `raspi4` + `raspi5`), Worker `k3s-worker-1` +
  `prodesk`. Die Raspis sind ARM (Debian, unterschiedliche Majors: raspi4 trixie,
  raspi5 bookworm), alles multi-arch prüfen.
- **Die k3s-Unit-Dateien liegen NUR auf den Nodes**, nicht im Repo (inkl.
  `--disable traefik` und `--disable servicelb`). Ebenso die Node-DNS-Konfiguration.
  Beim Anfassen oder Neubau: `references/betrieb.md`.

## Historie in einem Absatz

Das Homelab lief früher hinter **Pangolin** (Hetzner-VPS + Newt-Tunnel + SSO).
Die Migration auf Direkt-Exposure via Traefik ist seit 2026-07-24 vollständig
abgeschlossen, inklusive Teardown: keine `pangolin.io/*`-Annotationen, keine
`newt`/`pangolin-sync`/`cloudflare-sync`-Manifeste, kein `terraform/hetzner/`-Stack
mehr. Ebenfalls abgelöst und nicht wieder einführen: `check-versions.py` (jetzt
Renovate), der privilegierte `paperless-smb-sync`-Sidecar (jetzt csi-driver-smb),
MinIO als Longhorn-Backup-Ziel (jetzt CIFS aufs NAS), k3s' ServiceLB (MetalLB).
Details stehen im `CHANGELOG.md` und in der git-History.
