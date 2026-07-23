# Pangolin-Ablösung: Direct-Exposure via Traefik

Status: **in Umsetzung** (Branch `feature/pangolin-ablosung`, gestartet Juli 2026)

Ziel: externen Zugriff weg von Pangolin (VPS + Newt-Tunnel + SSO) migrieren, hin zu
direkter Exposure über Traefik mit sauberem, deklarativem DNS. Kein doppeltes
Einloggen mehr, keine zwei Sync-Jobs, keine VPS-Abhängigkeit.

## Leitplanken (aus ROADMAP)

- **Kein neues WireGuard im Cluster.** Das bestehende UniFi-WireGuard-VPN bleibt und
  trägt den internen Zugriff. wg-easy & Co. sind nicht gewünscht.
- Extern erreichbare Dienste laufen über **einen einzigen Router-Portforward**,
  interner Zugriff über das bestehende VPN.
- Frischer Branch, nicht der alte `feature/direct-exposure-wireguard`.

## Zielarchitektur

**Ein Eingang: Traefik** (MetalLB `192.168.2.250`, existiert bereits). Alles läuft
darüber, Cluster-Dienste *und* externe Hosts (unifi, pve, dreambox …). Traefik
routet per SNI/Host-Header.

### TLS: cert-manager + Let's Encrypt (DNS-01 über Cloudflare)

- Ein Wildcard-Zertifikat `*.elmstreet79.de` (+ Apex) als Traefik-Default über
  einen `TLSStore` namens `default`.
- DNS-01 heißt: **kein öffentlicher A-Record nötig**, also bekommen auch VPN-only-
  Dienste echte gültige Zertifikate.
- Ersetzt die interne CA (`internal-ca.crt`) **und** die Pangolin-Edge-TLS.
- Mit Wildcard-Default brauchen einzelne Ingresses **keine** `cert-manager.io`-
  Annotation mehr: ein Cert für alles.
- Prior art: `manifests/cert-manager/cluster-issuer.yaml` aus
  `feature/direct-exposure-wireguard`, nur `internal-ca-issuer` → `letsencrypt-prod`.

### Öffentlich = genau ein Cloudflare-Record

- UniFi forwardet **nur 80 + 443 → 192.168.2.250**. Ein einziger Portforward für
  alles, Traefik trennt per Host.
- Ein Dienst ist genau dann öffentlich, wenn er einen Cloudflare-Record auf die
  DynDNS-IP hat. Kein Record → von außen nicht auflösbar → automatisch intern-only.
- **Kein Wildcard-A-Record bei Cloudflare** (sonst wäre alles offen). Nur explizite
  Records pro Public-Host.

### Sync-Script weg, ohne Ersatz-Job

- Public-Hosts als **CNAME → `nebu2k.ipv64.net`** (UniFi-DynDNS), verwaltet per
  Terraform in `homelab-terraform`.
- IP-Wechsel zieht ipv64.net automatisch nach, die Cloudflare-Records bleiben
  statisch. Terraform verwaltet nie IPs, nur ein paar CNAMEs.
- Das ist der Ersatz für `cloudflare-sync`: deklarativ, git-versioniert, kein Job
  im Cluster.
- Offen: kann ipv64.net auch AAAA/v6? Wenn nein, Public erstmal v4-only.

### Intern / VPN: Split-Horizon-DNS, resolver-agnostisch

- **Eine einzige Wildcard-Rewrite `*.elmstreet79.de → 192.168.2.250`** im internen
  Resolver. Kein per-Host-Sync, daher **kein AdGuard-Sync mehr nötig**.
- Funktioniert heute in AdGuard (ein Rewrite-Eintrag) und später in Blocky
  (`customDNS`) identisch → passt zur geplanten Blocky-Ablösung.
- Im LAN und über das VPN lösen damit *alle* Hosts direkt auf Traefik auf. Löst
  nebenbei Hairpin-NAT für die Public-Dienste. Die Außenwelt sieht nur die CNAMEs.

### Externe Hosts (nicht im Cluster)

unifi, pve, dreambox, plex, minio, nas, adguard, vscode, glances:

- Weg mit dem `pangolin.io`-Endpoints-Hack, rein mit dem k8s-nativen Muster
  (prior art commit `0896cb8`): `Service` + manuelle `Endpoints` (externe IP) +
  `IngressRoute` mit `serversTransport: insecure-transport` (Backend hat eigenes
  self-signed Cert).
- Traefik terminiert mit Wildcard-Cert und proxied per https zum Host. Gleiche
  Ingress-Objekte wie Cluster-Dienste, kein Sonderweg.

## Auth

Vorerst **kein Cluster-SSO**:

- Public-Dienste nutzen App-eigenes Login (nextcloud, homeassistant etc. bringen
  das mit).
- Alles Sensible ist VPN-only, dort ist das VPN der Zugangsschutz.
- **Kein Keycloak** (JVM + DB + Realm-Pflege = genau die Reibung, die weg soll).
- Falls später ein Login-Layer *vor login-lose* Public-Dienste gewünscht ist:
  Pocket ID oder Authentik als Traefik-ForwardAuth, additiv nachrüstbar ohne die
  Migration zu blockieren. Entscheidung kann warten.

## Public-Set

Öffentlich (Cloudflare-CNAME + über Portforward erreichbar):
`www, dreambox, homeassistant, plex, teslamate, paperless`.

- `nextcloud` existiert nicht mehr, das tote external-service-Manifest wurde
  entfernt.
- `n8n` bleibt **VPN-only** (aktuell ungenutzt, kein externer Bedarf). Bleibt
  deployed, siehe ROADMAP (Use-Case finden).

Alles andere (unifi, pve, argocd, grafana, portainer, n8n, longhorn, uptime,
beszel, fr24, minio, nas, adguard*, vscode, glances, prometheus, alertmanager,
traefik, homepage, teslamate-settings) wird **VPN-only**.

## Migrationsreihenfolge (parallel zu Pangolin, Cutover per DNS, kein Downtime)

### Phase 0: Prep
- [x] Frischer Branch `feature/pangolin-ablosung`.
- [ ] Cloudflare-API-Token als SealedSecret in Namespace `cert-manager`
  (Scope `Zone:DNS:Edit` + `Zone:Read`). Bestehendes Token aus `cloudflare-sync`
  hat DNS:Edit und kann wiederverwendet werden.

### Phase 1: cert-manager + Wildcard-Cert
- [ ] `manifests/cert-manager/` (rekonstruiert), `ClusterIssuer letsencrypt-prod`.
- [ ] Wildcard-`Certificate` im Namespace `traefik`, `TLSStore default` → Secret.
- [ ] `apps/cert-manager.yaml` + in `apps/kustomization.yaml`.
- [ ] Verifizieren: Cert issued (DNS-01), Traefik serviert das Wildcard.

### Phase 2: Traefik zum Voll-Ingress
- [ ] Externe Hosts auf Service+Endpoints+IngressRoute (`insecure-transport`).
- [ ] Cluster-Ingresses: `pangolin.io`-Annotationen raus, `ingressClassName: traefik`
  + `tls`-Hosts (nutzen den Wildcard-Default).
- [ ] Läuft parallel neben Pangolin.

### Phase 3: DNS umstellen
- [ ] Interner Resolver: Wildcard-Rewrite `*.elmstreet79.de → 192.168.2.250`.
- [ ] Terraform-Cloudflare: CNAMEs für Public-Set → `nebu2k.ipv64.net`, DNS-only.
- [ ] UniFi Portforward 80 + 443 → 192.168.2.250.

### Phase 4: Cutover + Cleanup
- [ ] Extern testen (Handy ohne WLAN) + intern/VPN testen.
- [ ] Entfernen: `manifests/newt/`, `manifests/pangolin-sync/`,
  `manifests/cloudflare-sync/`, deren `apps/*.yaml`, CI-Workflows,
  alle `pangolin.io/*`-Annotationen, `internal-ca.crt`.
- [ ] Nach Bewährung: Pangolin-VPS in Terraform destroyen
  (`homelab-terraform/terraform/hetzner/server-pangolin.tf`).
