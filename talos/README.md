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
| VIP          | 192.168.2.29  |       | Kubernetes-Endpoint, von Talos selbst |

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

Was danach per GitOps kommt, steht in `apps/kustomization.yaml`: die
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
`system-backup-daily`, siehe `manifests/longhorn/recurring-backup-jobs.yaml`.

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

## Ein Longhorn-Volume aus dem NAS-Backup herholen

So sind am 2026-08-09 die 13 Volumes der zweiten Welle umgezogen. Beide Cluster
zeigen auf dasselbe CIFS-Share, der Umzug laeuft also ueber ein Backup und nicht
ueber eine Kopie.

**1. Frisches Backup im Quellcluster erzwingen.** Nicht auf den naechsten Lauf
von `backup-daily` warten: was zwischen letztem Backup und Prune geschrieben
wurde, ist sonst weg. Ein Snapshot-CR, danach ein Backup-CR darauf.

```bash
kubectl apply -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: Snapshot
metadata: {name: migration-x, namespace: longhorn-system}
spec: {volume: pvc-<uuid>, createSnapshot: true}
EOF
# danach, mit snapshotName: migration-x, ein Backup gleichen Namens
```

Warten, bis `.status.state` des Backups `Completed` ist, und **erst dann** die
App im Quellcluster prunen. Der Prune loescht PVC und Volume, das Backup ist
danach die einzige Kopie.

**2. Im Zielcluster den Backup-Target-Sync anstossen** (`syncRequestedAt` am
`backuptarget/default` setzen), sonst kennt es das frische Backup noch nicht.

**3. Volume restaurieren**, ein Volume-CR mit `fromBackup` auf die
`status.url` des Backups. `nodeSelector: [storage]` und `numberOfReplicas: 2`
muessen zur StorageClass passen, sonst findet Longhorn keine Disk. Fertig ist
das Restore, wenn `.status.restoreRequired` auf `false` steht.

**4. PV und PVC verdrahten.** Das PV steht in `manifests/<dienst>/pv.yaml`, mit
`claimRef` vorwaerts auf die PVC daneben. Die PVC selbst bleibt unveraendert. Der Grund steht ausfuehrlich
im Kopf von `manifests/ripe-atlas/pv.yaml`: ohne vorgebundenes PV bindet
die PVC an ein frisch provisioniertes, leeres Volume, der Pod startet, und das
faellt erst auf, wenn die Daten fehlen.

**5. Die Recurring-Job-Gruppen auf das Volume labeln.** Der Schritt, der beim
Umzug am 2026-08-09 fehlte und deshalb hier steht:

```bash
kubectl -n longhorn-system label volumes.longhorn.io <volume> \
  recurring-job-group.longhorn.io/backup=enabled \
  recurring-job-group.longhorn.io/snapshot=enabled \
  recurring-job-group.longhorn.io/maintenance=enabled \
  recurring-job-group.longhorn.io/default- --overwrite
```

Ein per `fromBackup` erzeugtes Volume laeuft **nicht** durch den
StorageClass-Provisioner, also greift dessen `recurringJobSelector` nicht und
das Volume traegt keine Gruppe. Longhorn stempelt ihm daraufhin selbst
`default` auf, und in `default` liegt kein einziger Job. Ergebnis: kein Backup,
kein Snapshot, kein Trim.

**Das meldet nichts.** Das Volume ist `healthy`, die App laeuft, ArgoCD ist
gruen, und `backup-monitor` prueft die S3-Ziele, nicht Longhorn. Aufgefallen
sind die 15 unbesicherten Volumes erst am 2026-08-09 bei einem Drift-Durchgang,
also einen Tag nach dem Umzug. Nach dem Labeln kontrollieren:

```bash
kubectl -n longhorn-system get volumes.longhorn.io -o json | \
  jq -r '.items[] | "\(.metadata.name) \(.metadata.labels | keys | map(select(startswith("recurring-job-group"))))"'
```

Das Restore selbst gehoert bewusst **nicht** ins git: die Backup-URL ist eine
Momentaufnahme, ein Re-Sync duerfte daraus nie einen alten Stand herstellen.
Das Labeln ist aus demselben Grund ein Handgriff und keine YAML im Repo: das
Volume-CR entsteht beim Restore, nicht aus einem Manifest.

## Fallen

- **`talconfig.yaml` zu aendern aendert keine einzige Node.** talhelper erzeugt
  daraus nur Dateien, erst `talosctl apply-config` traegt sie auf ein Geraet.
  Alles, was cluster-weit gilt (die beiden certSAN-Listen, der Endpoint, die
  apiserver-Argumente), muss deshalb auf **jede** Node einzeln appliziert
  werden, auch auf die, an der sich augenscheinlich nichts geaendert hat.

  Am 2026-08-09 gefunden: beim Tausch von talos-cp-2 gegen raspi5 war
  `talconfig.yaml` richtig gepflegt, appliziert wurde die neue Liste aber nur
  auf die neue Node. Danach trugen alle drei Nodes wochenlang die `.21` des
  abgebauten cp-2 im Cert und **nicht** die `.22` von raspi5. Folge: das
  apiserver-Zertifikat deckte raspi5' eigene Adresse nicht ab, jeder Zugriff
  ueber `https://192.168.2.22:6443` waere am Zertifikat gescheitert. Nichts
  davon meldet sich: die Nodes sind `Ready`, etcd hat drei Member, ArgoCD ist
  gruen, und ueber den VIP laeuft ohnehin alles.

  **Der Soll-Ist-Vergleich ist ein Einzeiler und kostet nichts.** Er gehoert
  nach jeder Aenderung an `talconfig.yaml` einmal ueber alle Nodes:

  ```bash
  for n in talos-cp-1:192.168.2.20 raspi5:192.168.2.22 prodesk:192.168.2.23; do
    talosctl -n ${n##*:} apply-config --dry-run \
      -f clusterconfig/homelab-${n%%:*}.yaml
  done
  ```

  Ein leerer Diff heisst, die Node traegt was in git steht. certSAN-Aenderungen
  brauchen dabei **keinen Reboot**, Talos zieht das Zertifikat neu und startet
  den apiserver-Pod. Ueber drei Control-Planes nacheinander gerollt merkt das
  Cluster nichts, ausser einem Aussetzer von rund einer halben Minute auf der
  Node, die gerade den VIP haelt.

- **`cluster.endpoint` zu aendern macht JEDES ausgestellte ServiceAccount-Token
  ungueltig.** Talos leitet `--service-account-issuer` des apiservers aus dem
  Endpoint ab. Steht dort danach eine andere Adresse, traegt jedes vorher
  ausgestellte Token den alten Issuer und wird abgelehnt: `failed to list ...
  Unauthorized`, quer durch das Cluster, von kube-proxy und CoreDNS bis zu
  ArgoCD. Frisch ausgestellte Token gehen sofort, `kubectl` mit dem
  Admin-Zertifikat merkt gar nichts, und genau das macht die Diagnose
  unangenehm: das Cluster sieht von aussen gesund aus, waehrend die Controller
  blind sind.

  Passiert am 2026-08-09 beim Umzug des VIP von der .248 auf die .29. Kein
  Reboot, keine Fehlermeldung beim Apply, der Bruch faellt erst Minuten spaeter
  auf. **Wer den Endpoint anfasst, plant den Rollout gleich mit ein:**

  ```bash
  # Netzwerkschicht zuerst, DaemonSets rollen ohnehin Node fuer Node
  kubectl -n kube-system rollout restart ds/kube-proxy ds/kube-flannel ds/kube-router
  kubectl -n kube-system rollout restart deploy/coredns
  # danach alles Uebrige
  for ns in $(kubectl get ns -o name | cut -d/ -f2); do
    for r in $(kubectl -n $ns get deploy,ds,sts -o name); do
      kubectl -n $ns rollout restart $r
    done
  done
  ```

  Ohne den Rollout heilt es sich zwar von selbst, aber erst wenn das kubelet
  die projizierten Token turnusmaessig erneuert (rund eine Stunde), und nur bei
  Clients, die die Token-Datei neu lesen.

  **Die Abwaegung war es rueckblickend kaum wert:** der Anlass war ein Loch im
  MetalLB-Bereich, also zwei Eintraege in einer YAML statt einem. Wer den
  Endpoint aus einem so kleinen Grund anfassen will, sollte es lassen.

- **Immer nur ein Restore auf einmal.** Zwei gleichzeitig laufende Restores
  mounten das CIFS-Share aus zwei Replica-Prozessen zugleich, einer von beiden
  scheitert mit `cannot mount CIFS share ...: mount failed: exit status 32` und
  das Volume bleibt `faulted`. Am 2026-08-09 gleich beim ersten Paar passiert
  (ripe-atlas), einzeln nachgezogen lief dasselbe Volume fehlerfrei. Ein
  faulted Volume ist nicht reparierbar, es muss geloescht und neu restauriert
  werden. **Backups** duerfen dagegen parallel laufen, dort ist es nie
  aufgetreten.
- **Pool-Aenderung und IP-Aenderung nicht in denselben Push.** Beim
  .250-Schwenk am 2026-08-09 lagen die neue Pool-Adresse (App `metallb`,
  sync-wave 1) und die neue Traefik-Annotation (App `traefik`, wave 3) in einem
  Commit. ArgoCD hat trotzdem zuerst den Service angefasst: die Waves ordnen die
  Ressourcen INNERHALB einer Application, die App-of-Apps-Sync wartet auf
  Health und lief zu dem Zeitpunkt noch. Ergebnis war ein Traefik, das eine
  Adresse anforderte, die in keinem Pool stand, also gar keine bekam und den
  Ingress fuer ein paar Minuten stilllegte. Erst den Pool pushen und die
  `ipaddresspool` live pruefen, dann die Annotation.
- **NetworkPolicies sind hier wirkungslos.** Talos deployt vanilla Flannel, und
  Flannel bringt keinen NetworkPolicy-Controller mit. k3s hatte einen
  eingebauten. Die `default-deny-ingress` von mealie, paperless-ngx und
  teslamate sind mitgewandert, werden aber von niemandem durchgesetzt: das API
  nimmt sie an, `kubectl get netpol` zeigt sie, und sie tun nichts. Kein
  Blocker, aber eine stille Verschlechterung gegenueber k3s. Steht als offener
  Punkt in der ROADMAP.
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
  Steht in `manifests/metallb/values.yaml`.
- **PodSecurity steht auf `baseline`.** `longhorn-system` ist in
  `talconfig.yaml` ausgenommen. Alles andere mit `hostNetwork` oder `hostPath`
  (Home Assistant, csi-driver-smb) braucht beim Migrieren ein
  `pod-security.kubernetes.io/enforce: privileged` am Namespace. Das gehoert in
  die Manifeste, nicht hierher: eine Aenderung hier rebootet die Control-Plane.

  **Nicht nur hostNetwork und hostPath stossen an baseline.** ripe-atlas hat
  weder das eine noch das andere und braucht die Ausnahme trotzdem: es setzt
  `NET_RAW` fuer ICMP und Traceroute, und `NET_RAW` steht nicht auf der Liste
  erlaubter `capabilities.add` (CHOWN, DAC_OVERRIDE, FOWNER, KILL, SETGID,
  SETUID und ein paar mehr sind erlaubt). Vor dem Migrieren also den ganzen
  `securityContext` lesen, nicht nur die Pod-Ebene.

  **Wo die Ausnahme hingehoert, haengt daran, wer den Namespace anlegt.**
  `managedNamespaceMetadata` an der Application wirkt nur bei
  `CreateNamespace=true` und nur beim Anlegen. Bringt die App ihr eigenes
  `namespace.yaml` mit (ripe-atlas, home-assistant), muss das Label per Patch
  an dieses Manifest.
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
  `manifests/longhorn/node-config.yaml`. Node-CRs deshalb auch nicht
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

## Eine neue Node aufnehmen: raspi5 als Control-Plane

Der naechste anstehende Handgriff. Er ersetzt talos-cp-2 und holt die
etcd-Mehrheit von pve herunter, siehe die Randbedingung in der ROADMAP. Die
Reihenfolge ist wichtig: **erst joinen, dann die alte Node entfernen**, sonst
steht das Cluster zwischendurch auf zwei Membern.

**1. Image bauen.** raspi5 braucht ein eigenes Schematic: `rpi_5`-Overlay plus
dieselben zwei Extensions wie die anderen Nodes. Auf
<https://factory.talos.dev> zusammenklicken, oder direkt per API:

```bash
curl -X POST --data-binary @- https://factory.talos.dev/schematics <<'EOF'
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/iscsi-tools
      - siderolabs/util-linux-tools
overlay:
  name: rpi_5
  image: siderolabs/sbc-raspberrypi
  options:
    configTxtAppend: |
      dtparam=cooling_fan=on
EOF
```

Die Antwort ist die Schematic-ID. Fuer raspi5 ist sie am 2026-08-09 erzeugt
worden und lautet
`5a66af048bde96b95010bf8bba792973932e5bb7359e77f2ef7d8edb9aacc2a6`; sie steht
seit dem 2026-08-09 auch in `talconfig.yaml`. Das Disk-Image dazu:

```text
https://factory.talos.dev/image/5a66af048bde96b95010bf8bba792973932e5bb7359e77f2ef7d8edb9aacc2a6/v1.13.8/metal-arm64.raw.zst
```

Die `configTxtAppend`-Option ist beim ersten Bau noch nicht dabei gewesen; die
Schematic ohne sie war
`b00ac8400b2ad823d3d5e972136dd89c0d960d58e0ff2b12d5b8b87e9d53e670`. Sie schaltet
den Device-Tree-Knoten des Luefters ein, ohne den der Kernel den Active Cooler
gar nicht kennt. Ein Nachtrag ist ein **Image**-Wechsel und braucht
`talosctl upgrade --preserve`, nicht `apply-config`, siehe oben. Beim Neubau
also gleich mit einbauen.

Der Luefter dreht damit trotzdem noch ungeregelt: der Talos-Kernel bringt
`CONFIG_PWM_RP1` ueberhaupt nicht mit, und ohne PWM-Provider findet `pwm-fan`
nichts, an dem er haengen koennte. Der Device-Tree-Knoten oben ist die haelfte
der Loesung, die dann greift, sobald ein Treiber da ist. Was dafuer noch fehlt,
steht in der ROADMAP.

**Das Image gehoert auf eine SD-Karte. Nicht auf die NVMe, nicht auf einen
USB-Stick.** Auf dem Pi 5 kann u-boot nur von SD booten: ihm fehlt der
PCIe-Treiber fuer den RP1-Chip, und an dem haengen sowohl die USB-Ports als
auch der M.2-Slot. Beides ist am 2026-08-09 durchprobiert worden, hier steht
das Ergebnis, damit es niemand wiederholt.

Der Ablauf sieht taeuschend gesund aus: der EEPROM-Bootloader der Firmware kann
USB und NVMe sehr wohl, liest die `config.txt` und laedt `u-boot.bin` brav vom
Stick. Erst danach initialisiert u-boot USB selbst neu, findet nichts mehr und
bleibt mit seinem Logo oben rechts stehen. Keine Fehlermeldung, kein Prompt,
kein Netz, auch nicht ueber IPv6-Link-Local. Wer nur auf den Bildschirm schaut,
sucht den Fehler zwangslaeufig an der falschen Stelle.

Zwei Sackgassen auf dem Weg dorthin, beide echt und beide nicht die Loesung:

- **"USB boot requires high current power supply".** Der Pi 5 drosselt die
  USB-Ports auf 600 mA, wenn er beim Netzteil keine 5 A aushandelt, und
  verweigert dann USB-Boot. Das trat auch mit dem Originalnetzteil auf. Der
  Hinweis auf `usb_max_current_enable=1` in der `config.txt` laeuft ins Leere,
  die Datei liegt ja auf dem Medium, das er nicht bootet. Richtig ist
  `PSU_MAX_CURRENT=5000` im EEPROM, das wirkt davor:

  ```bash
  rpi-eeprom-config --out /tmp/boot.conf
  sed -i 's/^PSU_MAX_CURRENT=.*/PSU_MAX_CURRENT=5000/' /tmp/boot.conf  # oder anhaengen
  sudo rpi-eeprom-config --apply /tmp/boot.conf
  ```

  Damit bootet der Pi tatsaechlich von USB. Es hilft nur nichts, weil u-boot
  danach trotzdem aussteigt.
- **Ein neuerer Bootloader.** Naheliegend, aber falsch: dass u-boot ueberhaupt
  startet, beweist, dass die Firmware ihren Teil erledigt hat.

Auf macOS schreibt man das Image so. `rdiskN` statt `diskN` ist um ein
Vielfaches schneller, und `bs=4m` gehoert klein geschrieben, BSD-`dd` kennt
kein `4M`:

```bash
zstd -d metal-arm64.raw.zst -o talos.raw
diskutil list                  # richtige Karte suchen
diskutil unmountDisk /dev/diskN
sudo dd if=talos.raw of=/dev/rdiskN bs=4m status=progress
```

Die NVMe bleibt dabei nicht ungenutzt, im Gegenteil: der VolumeConfig-Patch an
der Node zieht `EPHEMERAL` (`/var`, also Container-Images, Logs und
`/var/lib/longhorn`) auf sie. Auf der SD liegen nur EFI, BOOT, META und STATE,
also ein paar hundert MB, die praktisch nur bei Upgrades beschrieben werden.
Der Verschleissgrund, aus dem raspi5 damals ueberhaupt auf NVMe umgezogen ist,
bleibt damit erledigt.

**Der Pi hat kein Bootmenue**, es gibt keine Taste fuer "einmal von diesem
Medium" (Shift startet den Network-Install, sonst nichts). Die Reihenfolge
steht im EEPROM und wird von rechts nach links gelesen. Seit dem 2026-08-09
steht dort `BOOT_ORDER=0xf641`, also SD (1), dann USB (4), dann NVMe (6). Die
SD gewinnt damit, sobald eine steckt, und ohne Karte faellt er auf das
zurueck, was sonst da ist.

**2. In `talconfig.yaml` eintragen.** Steht dort seit dem 2026-08-09 fertig
drin, mit Begruendung an der Node selbst. Die Punkte, die anders sind als bei
den pve-VMs:

- `ipAddress: 192.168.2.22`, **nicht** die alte raspi5-Adresse `.9`. Der
  Node-Block ist `.20-.29`, und die UniFi-Regel fuer die beiden Gast-VLANs im
  Haus erlaubt `.2-.20`: auf der `.9` haengen Talos-API und kubelet in genau
  diesem Bereich. Im Repo haengt an der `.9` nichts mehr.
- `talosImageURL: factory.talos.dev/metal-installer/<schematic-id>`, also
  `metal`, nicht `nocloud`, wie bei prodesk.
- `installDisk: /dev/mmcblk0`, die SD-Karte, aus dem Grund weiter oben.
- Ein `VolumeConfig`-Patch zieht `EPHEMERAL` per `diskSelector` auf die NVMe.
  **Der muss beim ersten `apply-config` dabei sein**: Talos wendet eine
  VolumeConfig nur an, solange das Volume noch nicht provisioniert ist.
  Nachtraeglich liegt `/var` auf der SD und bleibt dort, ohne dass irgendetwas
  meckert. Der Patch haengt bewusst an der Node und nicht global, prodesk hat
  ebenfalls eine NVMe und der Ausdruck traefe dort genauso zu.
- `nodeLabels: topology.kubernetes.io/zone: raspi5`, eine **eigene** Zone und
  nicht `blech` zu prodesk dazu. Bei zwei Zonen liegt zwangslaeufig immer eine
  der beiden Repliken auf pve, siehe Fallen unten.
- `deviceSelector: hardwareAddr`. Beim Pi 5 ist der Treibername nicht
  `virtio_net`, und es gibt ohnehin nur eine NIC. Falls die Adresse einmal
  nicht stimmt, faellt das nicht als Fehler auf: die Node kommt schlicht ohne
  Netz hoch. Ablesen im Maintenance-Mode:

  ```bash
  talosctl -n <dhcp-ip> get links --insecure
  ```

**Vorher die NVMe leeren.** Talos legt `EPHEMERAL` nur auf einer Disk an, die
genug freien Platz hat, und die NVMe traegt noch die zwei Partitionen des alten
Raspberry Pi OS ueber die volle Kapazitaet. Passiert das nicht, faellt
`EPHEMERAL` stillschweigend auf die Systemdisk zurueck, also auf die SD-Karte,
und dann liegt genau die Schreiblast dort, die dort nicht hingehoert. Zu sehen
ist das erst hinterher an `talosctl -n <ip> get discoveredvolumes`. Aus dem
Maintenance-Mode heraus:

```bash
talosctl -n <dhcp-ip> disks --insecure
talosctl -n <dhcp-ip> wipe disk nvme0n1 --insecure
```

Nicht schon vorher aus dem laufenden Raspberry Pi OS heraus wipen, auch wenn es
ginge: solange nicht belegt ist, dass der Pi von der SD hochkommt, ist das alte
System der einzige Rueckweg auf die Node.

Danach `talhelper genconfig` und die Config anwenden, im Maintenance-Mode noch
`--insecure`:

```bash
talosctl apply-config --insecure --nodes <dhcp-ip> \
  --file clusterconfig/homelab-raspi5.yaml
```

**Kein `talosctl bootstrap`.** Das war einmalig fuer das erste etcd-Member; ein
zweiter Aufruf zerlegt das Cluster.

**3. Warten, bis er wirklich Member ist**, nicht nur `Ready`:

```bash
talosctl -n 192.168.2.22 etcd members
kubectl get nodes
```

Vier Member sind ein bewusst kurzer Zustand: eine gerade Anzahl vertraegt nicht
mehr Ausfaelle als drei.

Longhorn braucht hier einen eigenen Handgriff, und zwar **nach** dem Join, nicht
davor: fuer eine Node, die dazukommt, waehrend Longhorn schon laeuft, legt
longhorn-manager das Node-CR selbst an, mit einem fsid-abgeleiteten Disk-Namen
und ohne Tags. Also erst den vorgefundenen Schluessel lesen und ihn dann
unveraendert in `manifests/longhorn/node-config.yaml` uebernehmen, samt
`storage`-Tag (die StorageClass selektiert darauf, ohne Tag meldet die Node
Ready und Schedulable und bekommt trotzdem nie ein Replikat):

```bash
kubectl -n longhorn-system get nodes.longhorn.io raspi5 \
  -o jsonpath='{.spec.disks}'
```

Ein eigener Name waere ein zweiter Eintrag auf demselben Pfad und damit die
Webhook-Sackgasse aus dem alten Cluster. Die lange Fassung steht im Kopf von
`manifests/longhorn/node-config.yaml`.

**4. talos-cp-2 sauber entfernen**, in dieser Reihenfolge:

```bash
kubectl drain talos-cp-2 --ignore-daemonsets --delete-emptydir-data
talosctl -n 192.168.2.21 etcd leave
kubectl delete node talos-cp-2
```

Longhorn braucht dabei einen eigenen Handgriff: das Node-CR laesst sich nicht
loeschen, solange Repliken darauf liegen (der `validator.longhorn.io`-Webhook
blockt), und `drain` haengt an den Longhorn-PDBs. Vorher in der Longhorn-UI die
Node auf `allowScheduling: false` setzen und die Repliken abwandern lassen.

**5. Erst wenn raspi5 ein paar Talos-Upgrades ueberlebt hat**, ist raspi4
entbehrlich. Bis dahin steht er abgeschaltet, nicht abgebaut: `rpi_5` ist bei
Sidero ein bewegliches Ziel (Issue #12748: v1.12.2 bootet mit
Ethernet-Problem, v1.12.3 gar nicht), `rpi_generic` dagegen das einzige
offiziell getestete Pi-Profil. Bootet raspi5 nicht, kommt raspi4 an seine
Stelle.
