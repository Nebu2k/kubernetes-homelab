# Talos-Cluster (Neubau)

Machine configs fuer das neue Talos-Cluster. Es entsteht **parallel** zum
laufenden k3s-Cluster: eine Talos-Node kann einem k3s-Cluster nicht beitreten,
Talos bringt sein eigenes Kubernetes mit. Der Umbau ist deshalb kein Node-Tausch,
sondern zweites Cluster aufbauen, Workloads migrieren, altes abbauen.

## Was hier liegt

| Datei                 | Inhalt                                              |
| --------------------- | --------------------------------------------------- |
| `talconfig.yaml`      | Quelle der Wahrheit fuer alle machine configs       |
| `talsecret.sops.yaml` | etcd- und Kubernetes-CAs, SOPS/age-verschluesselt   |
| `.sops.yaml`          | age-Recipient fuer die Verschluesselung             |
| `clusterconfig/`      | generiert, gitignored, enthaelt die CAs im Klartext |

**Der private age-Key steht in `~/.config/sops/age/keys.txt` und nirgends
sonst.** Ohne ihn ist `talsecret.sops.yaml` unlesbar und das Cluster muss neu
gebaut werden. Gehoert in den Passwortmanager, nicht nur auf den Mac.

## Aufbau

Drei Control-Plane-VMs auf pve, gebaut aus
`homelab-terraform/proxmox/vm-talos.tf`. Drei statt zwei, weil
`talosctl upgrade` die Node rebootet: mit einem einzelnen etcd-Member haengt
jedes Upgrade am verlorenen Quorum.

| Node         | IP            | VM-ID | Rolle                                 |
| ------------ | ------------- | ----- | ------------------------------------- |
| `talos-cp-1` | 192.168.2.20  | 110   | Control-Plane, schedulet Workloads    |
| `talos-cp-2` | 192.168.2.21  | 111   | Control-Plane, schedulet Workloads    |
| `talos-cp-3` | 192.168.2.22  | 112   | Control-Plane, schedulet Workloads    |
| VIP          | 192.168.2.248 |       | Kubernetes-Endpoint, von Talos selbst |

Die VMs sind temporaer. Spaeter ersetzen prodesk und raspi5 zwei davon, eine
bleibt Control-Plane, eine wird Worker, eine wird geloescht.

**Adressen:** Nodes aus dem Cluster-Block `.20-.29`, VIP `.248`. Die `.249`
gehoert dem k3s-Cluster und kann in der Parallelphase nicht doppelt belegt
werden; MetalLB bekommt im neuen Cluster `.240-.247`, disjunkt zum alten Pool
`.250-.253`, sonst gibt es ARP-Konflikte im selben L2-Segment.

**Pod- und Service-CIDR sind bewusst dieselben wie unter k3s** (`10.42.0.0/16`
und `10.43.0.0/16`, nicht die Talos-Defaults). Beide Cluster sind getrennte
L3-Domaenen, die Ueberschneidung ist folgenlos, und die migrierten Manifeste
stimmen ohne Aenderung: `home-assistant/configmap-configuration.yaml` traegt
`10.42.0.0/16` als trusted_proxy, `gatus/configmap.yaml` prueft CoreDNS unter
`10.43.0.10`.

## Image

Image Factory, zwei Schematics. Beide tragen `siderolabs/iscsi-tools` und
`siderolabs/util-linux-tools` fuer Longhorn, der `qemu-guest-agent` ist der
einzige Unterschied:

- **VMs auf pve**, zusaetzlich mit `siderolabs/qemu-guest-agent`:
  `88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b`
- **prodesk (Blech)**, ohne weitere Extensions:
  `613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245`

Die getrennte Blech-Schematic gibt es seit dem 2026-08-09. Vorher lief prodesk
auf der VM-Schematic: der Guest-Agent findet auf Blech keinen virtio-Port,
bleibt dauerhaft in `Waiting` und steht damit in jedem `talosctl services` und
`talosctl health` im Weg. Funktional folgenlos, aber Rauschen, das man bei jeder
Diagnose erst wegdenken muss.

Die VM-ID steht an zwei Stellen (hier in `talconfig.yaml` und in
`homelab-terraform/proxmox/vm-talos.tf`) und muss zusammenpassen. Laufen sie
auseinander, faellt die Node beim naechsten Upgrade auf ein Image ohne
Extensions zurueck und Longhorn verliert seine Volumes. Fuer prodesk gilt
dasselbe zwischen `talconfig.yaml` und der ISO, von der er installiert wurde.

Die VMs booten vom `nocloud`-Disk-Image, Upgrades laufen ueber
`nocloud-installer`. Ein `metal`-Installer wuerde die Plattform umstellen.
prodesk umgekehrt: `metal-installer`, weil er von der ISO auf die NVMe
installiert ist.

Schematic-Wechsel ist ein Image-Wechsel, ein `apply-config` allein reicht nicht.
Beides nacheinander, und bei Control-Plane-Nodes mit `--preserve`, sonst wird
die EPHEMERAL-Partition samt etcd-Daten geleert und der Member muss neu syncen:

```bash
talhelper genconfig   # SOPS_AGE_KEY_FILE beachten, siehe unten
talosctl --talosconfig clusterconfig/talosconfig apply-config -n <ip> \
  --file clusterconfig/homelab-<node>.yaml
talosctl --talosconfig clusterconfig/talosconfig upgrade -n <ip> --preserve \
  --image factory.talos.dev/<platform>-installer/<schematic-id>:<talos-version>
```

## Plattform (Stand 2026-08-08)

ArgoCD kommt aus `homelab-terraform/argocd-talos/`, einem eigenen Stack mit
eigenem State. Bewusst nicht ein Stack mit umgebogenem kubeconfig: solange zwei
Cluster parallel laufen, waere ein Apply gegen den falschen Kontext ein
Totalschaden am jeweils anderen.

```bash
cd homelab-terraform/argocd-talos && terraform apply
KUBECONFIG=talos/clusterconfig/kubeconfig kubectl apply -f bootstrap/root-app-talos.yaml
```

Was danach per GitOps kommt, steht in `clusters/talos/kustomization.yaml`: die
app-of-apps des neuen Clusters. Sie zieht die Application-Manifeste aus `apps/`
und sagt nur, welche davon hier schon laufen und was sich unterscheidet. Ein
Dienst wandert damit durch eine Zeile mehr in der Liste, nicht durch eine Kopie.

Aktuell sieben: `sealed-secrets`, `metallb`, `traefik`, `cert-manager`,
`longhorn`, `readsb`, `fr24`. Belegt funktionierend: Traefik auf `192.168.2.240` liefert das
Let's-Encrypt-Wildcard, also greifen SealedSecrets (Cloudflare-Token),
cert-manager (DNS-01) und der TLSStore-Default.

Longhorn steht seit dem 2026-08-08, drei Storage-Nodes mit je 116 GiB frei.
Ende zu Ende geprueft: PVC gebunden, Daten geschrieben und wieder gelesen, zwei
Replikate auf zwei Nodes, Backup-Target `available: true`.

**Beide Cluster teilen sich dasselbe CIFS-Backup-Target.** Das neue Cluster hat
beim ersten Sync alle 18 BackupVolumes und 141 Backups des alten eingelesen,
lesend, es wurde nichts geloescht (in beiden Clustern gezaehlt). Das ist die
Voraussetzung fuer den Restore und kein Unfall. Ein Job ist deshalb bewusst aus:
`system-backup-daily`, siehe `clusters/talos/longhorn/kustomization.yaml`.

**Die Sealing-Keys sind aus dem k3s-Cluster uebertragen**, alle sieben
(30-Tage-Rotation, sieben Monate Historie). Deshalb funktioniert jedes
`*-sealed.yaml` im Repo unveraendert und es gab keinen Reseal-Lauf.

**Die UI ist in der Parallelphase nur per Port-Forward erreichbar.** Der
Wildcard-Rewrite zeigt `*.elmstreet79.de` weiter auf die `.250`, also auf das
k3s-Cluster.

```bash
KUBECONFIG=talos/clusterconfig/kubeconfig kubectl -n argocd port-forward svc/argocd-server 8080:80
```

## Bedienung

```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

talhelper genconfig                       # nach ./clusterconfig/
talosctl validate --config clusterconfig/homelab-talos-cp-1.yaml --mode metal
```

Erstmalige Installation, Node fuer Node (im Maintenance-Mode, dort noch per
DHCP-Adresse erreichbar, `--insecure` weil noch kein Client-Cert existiert):

```bash
talosctl apply-config --insecure --nodes <dhcp-ip> \
  --file clusterconfig/homelab-talos-cp-1.yaml
```

Danach genau **einmal** im ganzen Cluster etcd bootstrappen:

```bash
export TALOSCONFIG=./clusterconfig/talosconfig
talosctl config endpoint 192.168.2.20 192.168.2.21 192.168.2.22
talosctl bootstrap --nodes 192.168.2.20
talosctl kubeconfig --nodes 192.168.2.20
```

Aenderungen danach immer ueber `talconfig.yaml` und `talhelper genconfig`, nie
direkt an einer generierten Datei: die wird beim naechsten Lauf ueberschrieben.

```bash
talosctl apply-config --nodes 192.168.2.20 --file clusterconfig/homelab-talos-cp-1.yaml
```

## Fallen

- **`node-role.kubernetes.io/worker` steht in der machine config** und muss da
  bleiben. Rund 20 Manifeste selektieren darauf, unter anderem die nodeSelector
  von MetalLB und cert-manager. Fehlt es, bleibt die halbe Plattform Pending,
  ohne Fehlermeldung, nur mit "0/3 nodes are available". Dass Talos den fuer das
  kubelet gesperrten Praefix setzen darf, liegt daran, dass es Node-Labels ueber
  einen eigenen Controller anlegt und nicht ueber das kubelet.
- **MetalLB braucht `speaker.ignoreExcludeLB`.** Vanilla Kubernetes setzt auf
  Control-Plane-Nodes `node.kubernetes.io/exclude-from-external-load-balancers`,
  k3s tut das nicht. MetalLB kuendigt von solchen Nodes nichts an, und im
  Startaufbau sind alle drei Nodes Control-Plane. Der Fehler ist leise: der
  Service bekommt seine IP, ArgoCD meldet Synced und Healthy, die Speaker haben
  ARP-Responder und einen sauberen memberlist-Join, aber niemand beantwortet das
  ARP. Zu sehen ist es nur an einem leeren `kubectl get servicel2status -A`.
  Steht in `clusters/talos/kustomization.yaml`.
- **PodSecurity steht auf `baseline`.** `longhorn-system` ist in
  `talconfig.yaml` ausgenommen. Alles andere mit `hostNetwork` oder `hostPath`
  (Home Assistant, csi-driver-smb) braucht beim Migrieren ein
  `pod-security.kubernetes.io/enforce: privileged` am Namespace. Das gehoert in
  die Manifeste, nicht hierher: eine Aenderung hier rebootet die Control-Plane.
- **talos-cp-1 traegt den RTL-SDR und ist deshalb ein Pet.** Der Stick haengt an
  pve und wird per qemu-USB durchgereicht (`usb_devices` in
  `homelab-terraform/proxmox/vm-talos.tf`), der readsb-Pod ist per nodeSelector
  daran gebunden. Diese Node ist die, die Schritt 7 der Migration ueberlebt.
  Zwei Dinge, die dabei ueberrascht haben: **Proxmox steckt USB heiss dazu**, das
  Hinzufuegen des Blocks hat die VM nicht neu gestartet, und **der Dongle laeuft
  nicht an jedem Port**. Hinter dem ASMedia-ASM1074-Hub (`3-2.1`) hat er sich
  einmal angemeldet und dann mit `error -71` und "unable to enumerate"
  verabschiedet, an `3-2.3` laeuft er fehlerfrei. Bei USB-Problemen also zuerst
  `dmesg -T | grep -i usb` auf pve, nicht im Cluster suchen.
- **Longhorn-Disks muessen unter GitOps deklariert werden.** Longhorn legt die
  `default-disk` nur an, wenn es das Node-CR selbst erzeugt. ArgoCD ist
  schneller, longhorn-manager adoptiert das vorhandene CR und ergaenzt nichts.
  Ohne `spec.disks` im Manifest stehen die Nodes auf Ready und Schedulable und
  haben null Kapazitaet, was erst am ersten Pending-Volume auffaellt. Steht in
  `clusters/talos/longhorn/node-config.yaml`. Node-CRs deshalb auch nicht
  loeschen: dann legt Longhorn seine eigene Disk daneben und das Duplikat ist
  nicht mehr aufloesbar.
- **`talosctl reset` nimmt `/var/lib/longhorn` mit.** Die Replikate liegen auf
  der EPHEMERAL-Partition.
- **Zwei Cluster heisst zwei kubeconfigs.** Ein Terraform-Stack mit umgebogenem
  kubeconfig zerlegt in der Parallelphase das jeweils andere Cluster.
- **`coredns-custom` gibt es hier nicht, und das ist kein Blocker.** Der
  Split-Horizon-Rewrite fuer Pods haengt im k3s-Cluster an einer ConfigMap
  namens `coredns-custom`, eine k3s-Eigenheit. Talos deployt vanilla CoreDNS mit
  `forward . /etc/resolv.conf`, also an AdGuard, und dort greift der Wildcard:
  Pods loesen `*.elmstreet79.de` sauber auf. Belegt seit dem 2026-08-09 im
  Betrieb durch die gatus-Checks.

  Der Preis ist die Abhaengigkeit: stirbt AdGuard, verlieren die Pods dieses
  Clusters jede Namensaufloesung, waehrend das k3s-Cluster direkt an Cloudflare
  forwarded. Hinnehmbar, aber es ist die Vorbedingung fuer die Blocky-Ablösung,
  siehe ROADMAP.
- **kured und system-upgrade-controller gehoeren nicht mit herueber.** Beide
  setzen ein OS mit Paketmanager und Reboot-Semantik voraus. Talos-Upgrades
  laufen ueber `talosctl upgrade`.
- **ArgoCD 3.x legt keine `Endpoints` an.** Seit 3.0 stehen `Endpoints` und
  `EndpointSlice` per Default auf `resource.exclusions`, und ausgeschlossen
  heisst nicht "wird nicht angezeigt", sondern "existiert fuer ArgoCD nicht":
  die neun handgeschriebenen Endpoints aus `manifests/external-services/`
  werden nicht angelegt, die App meldet trotzdem Synced und Healthy. Sichtbar
  nur an 503 von Traefik fuer pve/unifi/plex/nas/dreambox/vscode/glances, weil
  hinter den selektorlosen Services nichts steht. Behoben ueber die
  `resource.exclusions` in `homelab-terraform/argocd-talos/main.tf`, die
  core/`Endpoints` wieder hereinnimmt.

  **Im k3s-Cluster gilt derselbe Ausschluss, faellt dort aber nicht auf**: die
  Objekte stammen aus der Zeit vor 3.0 und werden aus demselben Grund auch
  nicht geprunt. Wer dort eine Endpoint-IP im Repo aendert, aendert sie
  praktisch nicht. Von Hand nachziehen oder den Dienst migrieren.
