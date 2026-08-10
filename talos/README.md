# Talos-Cluster

Machine configs des Clusters. Talos hat keine SSH und keinen Paketmanager: was
auf einer Node laeuft, steht vollstaendig in `talconfig.yaml` und wird von dort
generiert und appliziert.

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

Drei Control-Plane-Nodes, alle schedulen Workloads. Zwei davon sind Blech, nur
eine ist eine VM auf pve: ein Ausfall von pve kostet damit weder das
etcd-Quorum noch alle Longhorn-Repliken.

| Node         | IP           | Hardware                        | Rolle                                 |
| ------------ | ------------ | ------------------------------- | ------------------------------------- |
| `talos-cp-1` | 192.168.2.20 | VM auf pve (`vm-talos.tf`)      | Control-Plane, traegt den RTL-SDR     |
| `raspi5`     | 192.168.2.22 | Raspberry Pi 5, SD + NVMe       | Control-Plane                         |
| `prodesk`    | 192.168.2.23 | HP ProDesk 600 G4 DM, 31 GB RAM | Control-Plane                         |
| VIP          | 192.168.2.29 |                                 | Kubernetes-Endpoint, von Talos selbst |

**Adressen:** Nodes aus dem Block `.20-.29`, der VIP als `.29` darin. MetalLB
vergibt aus `.240-.253`, Traefik haelt darin fest die `.250`. Der VIP liegt
bewusst nicht im MetalLB-Bereich, sonst muesste der Pool ein Loch haben.

**Fehlerdomaenen:** jede Node traegt ein eigenes
`topology.kubernetes.io/zone` (`pve`, `raspi5`, `blech`). Longhorn verteilt
Repliken darueber, Gegenstueck ist `replicaZoneSoftAntiAffinity: "false"` in
`manifests/longhorn/values.yaml`. Eine neue Node braucht deshalb zuerst ihr
Zonen-Label.

Pod- und Service-CIDR sind `10.42.0.0/16` und `10.43.0.0/16`, nicht die
Talos-Defaults. Manifeste verlassen sich darauf:
`home-assistant/configmap-configuration.yaml` traegt `10.42.0.0/16` als
trusted_proxy, `gatus/configmap.yaml` prueft CoreDNS unter `10.43.0.10`.

## Image

Image Factory, drei Schematics. Alle drei tragen `siderolabs/iscsi-tools` und
`siderolabs/util-linux-tools` fuer Longhorn:

- **VM auf pve**, zusaetzlich `siderolabs/qemu-guest-agent`, `nocloud-installer`:
  `88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b`
- **prodesk**, ohne weitere Extensions, `metal-installer`:
  `613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245`
- **raspi5**, `rpi_5`-Overlay plus `configTxtAppend: dtparam=cooling_fan=on`,
  `metal-installer`:
  `5a66af048bde96b95010bf8bba792973932e5bb7359e77f2ef7d8edb9aacc2a6`

Der Guest-Agent gehoert nur in die VM-Schematic. Auf Blech findet er keinen
virtio-Port, bleibt dauerhaft in `Waiting` und steht in jedem
`talosctl services` und `talosctl health` im Weg.

Installer-Plattform und Boot-Medium muessen zusammenpassen: die VM bootet vom
`nocloud`-Disk-Image, ein `metal`-Installer wuerde die Plattform beim naechsten
Upgrade umstellen. prodesk und raspi5 sind von einer ISO beziehungsweise einem
Disk-Image auf Blech installiert und brauchen `metal`.

Die Schematic-ID steht bei der VM an zwei Stellen (hier und in
`homelab-terraform/proxmox/vm-talos.tf`) und muss zusammenpassen. Laufen sie
auseinander, faellt die Node beim naechsten Upgrade auf ein Image ohne
Extensions zurueck und Longhorn verliert seine Volumes.

Eine Schematic-Aenderung ist ein Image-Wechsel, `apply-config` allein reicht
nicht. Beides nacheinander, und bei Control-Plane-Nodes mit `--preserve`, sonst
wird die EPHEMERAL-Partition samt etcd-Daten geleert und der Member muss neu
syncen:

```bash
talhelper genconfig
talosctl --talosconfig clusterconfig/talosconfig apply-config -n <ip> \
  --file clusterconfig/homelab-<node>.yaml
talosctl --talosconfig clusterconfig/talosconfig upgrade -n <ip> --preserve \
  --image factory.talos.dev/<platform>-installer/<schematic-id>:<talos-version>
```

Eine Schematic entsteht deterministisch aus ihrem YAML: dasselbe YAML nochmal
an die Factory geschickt ergibt wieder dieselbe ID. Images werden deshalb
nirgends aufbewahrt, nur die IDs oben.

## Plattform

ArgoCD kommt aus `homelab-terraform/argocd-talos/`, einem eigenen Stack mit
eigenem State, und ist das einzige, was nicht aus diesem Repo deployt wird.

```bash
cd homelab-terraform/argocd-talos && terraform apply
kubectl apply -f bootstrap/root-app.yaml
```

Alles Weitere haengt an `apps/kustomization.yaml`, der App-of-Apps.

## Bedienung

```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

talhelper genconfig                       # nach ./clusterconfig/
talosctl validate --config clusterconfig/homelab-talos-cp-1.yaml --mode metal
```

Aenderungen immer ueber `talconfig.yaml` und `talhelper genconfig`, nie direkt
an einer generierten Datei: die wird beim naechsten Lauf ueberschrieben.

```bash
talosctl apply-config --nodes 192.168.2.20 --file clusterconfig/homelab-talos-cp-1.yaml
```

Erstmalige Installation einer Node im Maintenance-Mode, dort noch per
DHCP-Adresse erreichbar und `--insecure`, weil noch kein Client-Cert existiert:

```bash
talosctl apply-config --insecure --nodes <dhcp-ip> \
  --file clusterconfig/homelab-<node>.yaml
```

Beim Neubau des ganzen Clusters danach genau **einmal** etcd bootstrappen. Ein
zweiter Aufruf zerlegt das Cluster, eine hinzukommende Node bekommt ihn nicht:

```bash
export TALOSCONFIG=./clusterconfig/talosconfig
talosctl config endpoint 192.168.2.20 192.168.2.22 192.168.2.23
talosctl bootstrap --nodes 192.168.2.20
talosctl kubeconfig --nodes 192.168.2.20
```

### Nach jeder Aenderung an `talconfig.yaml`: Soll-Ist-Vergleich

`talconfig.yaml` zu aendern aendert keine einzige Node. talhelper erzeugt daraus
nur Dateien, erst `talosctl apply-config` traegt sie auf ein Geraet. Alles, was
cluster-weit gilt (die beiden certSAN-Listen, der Endpoint, die
apiserver-Argumente), muss deshalb auf **jede** Node einzeln appliziert werden,
auch auf die, an der sich augenscheinlich nichts geaendert hat. Eine Node mit
veralteter Config meldet sich nicht: sie ist `Ready`, etcd hat seine Member,
ArgoCD ist gruen.

Der Vergleich ist ein Einzeiler, ein leerer Diff heisst "Node traegt, was in git
steht":

```bash
for n in talos-cp-1:192.168.2.20 raspi5:192.168.2.22 prodesk:192.168.2.23; do
  talosctl -n ${n##*:} apply-config --dry-run \
    -f clusterconfig/homelab-${n%%:*}.yaml
done
```

certSAN-Aenderungen brauchen **keinen Reboot**, Talos zieht das Zertifikat neu
und startet den apiserver-Pod. Ueber drei Control-Planes nacheinander gerollt
merkt das Cluster nichts, ausser einem Aussetzer von rund einer halben Minute
auf der Node, die gerade den VIP haelt.

## Ein Longhorn-Volume aus dem NAS-Backup herholen

**1. Frisches Backup erzwingen**, nicht auf den naechsten Lauf von
`backup-daily` warten. Ein Snapshot-CR, danach ein Backup-CR darauf:

```bash
kubectl apply -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: Snapshot
metadata: {name: restore-x, namespace: longhorn-system}
spec: {volume: pvc-<uuid>, createSnapshot: true}
EOF
# danach, mit snapshotName: restore-x, ein Backup gleichen Namens
```

Warten, bis `.status.state` des Backups `Completed` ist.

**2. Backup-Target-Sync anstossen** (`syncRequestedAt` am
`backuptarget/default` setzen), sonst kennt Longhorn das frische Backup noch
nicht.

**3. Volume restaurieren**, ein Volume-CR mit `fromBackup` auf die
`status.url` des Backups. `nodeSelector: [storage]` und `numberOfReplicas: 2`
muessen zur StorageClass passen, sonst findet Longhorn keine Disk. Fertig ist
das Restore, wenn `.status.restoreRequired` auf `false` steht.

**4. PV und PVC verdrahten.** Das PV steht in `manifests/<dienst>/pv.yaml`, mit
`claimRef` vorwaerts auf die PVC daneben. Die PVC selbst bleibt unveraendert.
Der Grund steht ausfuehrlich im Kopf von `manifests/ripe-atlas/pv.yaml`: ohne
vorgebundenes PV bindet die PVC an ein frisch provisioniertes, leeres Volume,
der Pod startet, und das faellt erst auf, wenn die Daten fehlen.

**5. Die Recurring-Job-Gruppen auf das Volume labeln:**

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
kein Snapshot, kein Trim, und **das meldet nichts**. Das Volume ist `healthy`,
die App laeuft, ArgoCD ist gruen, und `backup-monitor` prueft die S3-Ziele,
nicht Longhorn. Nach dem Labeln kontrollieren:

```bash
kubectl -n longhorn-system get volumes.longhorn.io -o json | \
  jq -r '.items[] | "\(.metadata.name) \(.metadata.labels | keys | map(select(startswith("recurring-job-group"))))"'
```

Das Restore selbst gehoert bewusst **nicht** ins git: die Backup-URL ist eine
Momentaufnahme, ein Re-Sync duerfte daraus nie einen alten Stand herstellen.
Das Labeln ist aus demselben Grund ein Handgriff und keine YAML im Repo: das
Volume-CR entsteht beim Restore, nicht aus einem Manifest.

## Eine Node aufnehmen oder tauschen

**Erst joinen, dann die alte Node entfernen**, sonst steht das Cluster
zwischendurch auf zwei Membern. Vier Member sind ein bewusst kurzer Zustand:
eine gerade Anzahl vertraegt nicht mehr Ausfaelle als drei.

1. **Schematic bauen**, falls die Hardware eine eigene braucht (Overlay,
   Extensions). Auf <https://factory.talos.dev> zusammenklicken oder per API:

   ```bash
   curl -X POST --data-binary @- https://factory.talos.dev/schematics <<'EOF'
   customization:
     systemExtensions:
       officialExtensions:
         - siderolabs/iscsi-tools
         - siderolabs/util-linux-tools
   EOF
   ```

   Die Antwort ist die Schematic-ID. Das Disk-Image dazu liegt unter
   `https://factory.talos.dev/image/<id>/<talos-version>/<platform>.raw.zst`.
   **Die Version in dieser URL ist keine Automatik**: sie muss das sein, was das
   Cluster gerade faehrt (`talosctl version`), sonst kommt die Node mit einem
   aelteren Talos zurueck als die anderen, und zwar ohne Fehlermeldung.

2. **In `talconfig.yaml` eintragen**, mit `nodeLabels`
   (`topology.kubernetes.io/zone`, siehe oben), `installDisk` oder
   `installDiskSelector` und dem passenden `talosImageURL`. Auf Blech den
   `deviceSelector` ueber `hardwareAddr` statt ueber den Treibernamen: stimmt
   die Adresse nicht, faellt das nicht als Fehler auf, die Node kommt schlicht
   ohne Netz hoch. Ablesen im Maintenance-Mode mit
   `talosctl -n <dhcp-ip> get links --insecure`.

   Soll `EPHEMERAL` auf einer anderen Disk liegen als das System, gehoert der
   `VolumeConfig`-Patch **in das erste `apply-config`**. Talos wendet eine
   VolumeConfig nur an, solange das Volume noch nicht provisioniert ist;
   nachtraeglich liegt `/var` auf der Systemdisk und bleibt dort. Die Zieldisk
   muss vorher leer sein, sonst faellt `EPHEMERAL` stillschweigend auf die
   Systemdisk zurueck. Aus dem Maintenance-Mode:

   ```bash
   talosctl -n <dhcp-ip> disks --insecure
   talosctl -n <dhcp-ip> wipe disk nvme0n1 --insecure
   ```

3. **Config anwenden** (`--insecure`, siehe oben) und warten, bis die Node
   wirklich Member ist, nicht nur `Ready`:

   ```bash
   talosctl -n <ip> etcd members
   kubectl get nodes
   ```

4. **Longhorn nachziehen, nach dem Join.** Fuer eine Node, die dazukommt,
   waehrend Longhorn schon laeuft, legt longhorn-manager das Node-CR selbst an,
   mit einem fsid-abgeleiteten Disk-Namen und ohne Tags. Also den vorgefundenen
   Schluessel lesen und unveraendert in `manifests/longhorn/node-config.yaml`
   uebernehmen, samt `storage`-Tag: die StorageClass selektiert darauf, ohne Tag
   meldet die Node Ready und Schedulable und bekommt trotzdem nie ein Replikat.

   ```bash
   kubectl -n longhorn-system get nodes.longhorn.io <node> \
     -o jsonpath='{.spec.disks}'
   ```

   Ein eigener Name waere ein zweiter Eintrag auf demselben Pfad und damit eine
   Webhook-Sackgasse. Die lange Fassung steht im Kopf von
   `manifests/longhorn/node-config.yaml`.

5. **Die alte Node entfernen**, in dieser Reihenfolge:

   ```bash
   kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
   talosctl -n <ip> etcd leave
   kubectl delete node <node>
   ```

   Longhorn braucht dabei einen eigenen Handgriff: das Node-CR laesst sich nicht
   loeschen, solange Repliken darauf liegen (der `validator.longhorn.io`-Webhook
   blockt), und `drain` haengt an den Longhorn-PDBs. Vorher in der Longhorn-UI
   die Node auf `allowScheduling: false` setzen und die Repliken abwandern
   lassen.

### Raspberry Pi 5: das System gehoert auf die SD-Karte

Nicht auf die NVMe, nicht auf einen USB-Stick. Auf dem Pi 5 kann u-boot nur von
SD booten: ihm fehlt der PCIe-Treiber fuer den RP1-Chip, und an dem haengen
sowohl die USB-Ports als auch der M.2-Slot. Der Ablauf sieht dabei taeuschend
gesund aus, weil der EEPROM-Bootloader USB und NVMe sehr wohl kann und
`u-boot.bin` brav vom Stick laedt; erst danach initialisiert u-boot USB selbst
neu, findet nichts mehr und bleibt mit seinem Logo stehen. Keine Fehlermeldung,
kein Prompt, kein Netz.

Die NVMe bleibt trotzdem in Gebrauch: der `VolumeConfig`-Patch zieht `EPHEMERAL`
(`/var`, also Container-Images, Logs und `/var/lib/longhorn`) auf sie. Auf der
SD liegen nur EFI, BOOT, META und STATE, zusammen ein paar hundert MB, die
praktisch nur bei Upgrades beschrieben werden.

Bootreihenfolge steht im EEPROM und wird von rechts nach links gelesen. Der Pi
hat kein Bootmenue, es gibt keine Taste fuer "einmal von diesem Medium".
`BOOT_ORDER=0xf641` heisst SD (1), dann USB (4), dann NVMe (6): die SD gewinnt,
sobald eine steckt.

Image auf macOS schreiben. `rdiskN` statt `diskN` ist um ein Vielfaches
schneller, und `bs=4m` gehoert klein geschrieben, BSD-`dd` kennt kein `4M`:

```bash
zstd -d metal-arm64.raw.zst -o talos.raw
diskutil list                  # richtige Karte suchen
diskutil unmountDisk /dev/diskN
sudo dd if=talos.raw of=/dev/rdiskN bs=4m status=progress
```

`rpi_5` ist bei Sidero ein bewegliches Ziel, `rpi_generic` dagegen das einzige
offiziell getestete Pi-Profil. Ein Talos-Upgrade auf einem Pi gehoert deshalb
nicht ungeprueft ausgerollt.

## Fallen

- **`cluster.endpoint` zu aendern macht JEDES ausgestellte ServiceAccount-Token
  ungueltig.** Talos leitet `--service-account-issuer` des apiservers aus dem
  Endpoint ab. Steht dort danach eine andere Adresse, traegt jedes vorher
  ausgestellte Token den alten Issuer und wird abgelehnt: `failed to list ...
  Unauthorized`, quer durch das Cluster, von kube-proxy und CoreDNS bis zu
  ArgoCD. Frisch ausgestellte Token gehen sofort, `kubectl` mit dem
  Admin-Zertifikat merkt gar nichts, und genau das macht die Diagnose
  unangenehm: das Cluster sieht von aussen gesund aus, waehrend die Controller
  blind sind. Wer den Endpoint anfasst, plant den Rollout gleich mit ein:

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
  Clients, die die Token-Datei neu lesen. Der Endpoint ist nichts, was man
  wegen einer Kleinigkeit anfasst.

- **Immer nur ein Restore auf einmal.** Zwei gleichzeitig laufende Restores
  mounten das CIFS-Share aus zwei Replica-Prozessen zugleich, einer von beiden
  scheitert mit `cannot mount CIFS share ...: mount failed: exit status 32` und
  das Volume bleibt `faulted`. Ein faulted Volume ist nicht reparierbar, es muss
  geloescht und neu restauriert werden. **Backups** duerfen dagegen parallel
  laufen.

- **Pool-Aenderung und IP-Aenderung nicht in denselben Push.** Die sync-waves
  ordnen die Ressourcen INNERHALB einer Application; die App-of-Apps-Sync wartet
  auf Health und laeuft unter Umstaenden noch, waehrend ArgoCD den Service schon
  anfasst. Eine neue Traefik-Annotation kann so eine Adresse anfordern, die im
  MetalLB-Pool noch nicht steht: der Service bekommt dann gar keine und der
  Ingress liegt still. Erst den Pool pushen und die `ipaddresspool` live
  pruefen, dann die Annotation.

- **`node-role.kubernetes.io/worker` steht in der machine config** und muss da
  bleiben. Rund 20 Manifeste selektieren darauf, unter anderem die nodeSelector
  von MetalLB und cert-manager. Fehlt es, bleibt die halbe Plattform Pending,
  ohne Fehlermeldung, nur mit "0/3 nodes are available". Dass Talos den fuer das
  kubelet gesperrten Praefix setzen darf, liegt daran, dass es Node-Labels ueber
  einen eigenen Controller anlegt und nicht ueber das kubelet.

- **MetalLB braucht `speaker.ignoreExcludeLB`.** Kubernetes setzt auf
  Control-Plane-Nodes `node.kubernetes.io/exclude-from-external-load-balancers`,
  und hier sind alle Nodes Control-Plane. MetalLB kuendigt von solchen Nodes
  nichts an. Der Fehler ist leise: der Service bekommt seine IP, ArgoCD meldet
  Synced und Healthy, die Speaker haben ARP-Responder und einen sauberen
  memberlist-Join, aber niemand beantwortet das ARP. Zu sehen ist es nur an
  einem leeren `kubectl get servicel2status -A`. Steht in
  `manifests/metallb/values.yaml`.

- **PodSecurity steht auf `baseline`.** `longhorn-system` ist in
  `talconfig.yaml` ausgenommen. Alles andere, was daran anstoesst, braucht ein
  `pod-security.kubernetes.io/enforce: privileged` am Namespace. Das gehoert in
  die Manifeste, nicht in `talconfig.yaml`: eine Aenderung dort rebootet die
  Control-Plane.

  **Nicht nur `hostNetwork` und `hostPath` stossen an baseline.** ripe-atlas hat
  weder das eine noch das andere und braucht die Ausnahme trotzdem: es setzt
  `NET_RAW` fuer ICMP und Traceroute, und `NET_RAW` steht nicht auf der Liste
  erlaubter `capabilities.add`. Also den ganzen `securityContext` lesen, nicht
  nur die Pod-Ebene.

  **Wo die Ausnahme hingehoert, haengt daran, wer den Namespace anlegt.**
  `managedNamespaceMetadata` an der Application wirkt nur bei
  `CreateNamespace=true` und nur beim Anlegen. Bringt die App ihr eigenes
  `namespace.yaml` mit (ripe-atlas, home-assistant), muss das Label per Patch
  an dieses Manifest.

- **Longhorn-Disks muessen unter GitOps deklariert werden.** Longhorn legt die
  `default-disk` nur an, wenn es das Node-CR selbst erzeugt. ArgoCD ist
  schneller, longhorn-manager adoptiert das vorhandene CR und ergaenzt nichts.
  Ohne `spec.disks` im Manifest stehen die Nodes auf Ready und Schedulable und
  haben null Kapazitaet, was erst am ersten Pending-Volume auffaellt. Steht in
  `manifests/longhorn/node-config.yaml`. Node-CRs deshalb auch nicht loeschen:
  dann legt Longhorn seine eigene Disk daneben und das Duplikat ist nicht mehr
  aufloesbar.

- **`talosctl reset` nimmt `/var/lib/longhorn` mit.** Die Replikate liegen auf
  der EPHEMERAL-Partition.

- **raspi5 braucht `ethtool`-Nachhilfe, sonst zerlegt es etcd.** `end0` kommt
  mit einem 512er-TX-Ring und aktivem TSO/GSO hoch. Sobald echter Verkehr
  anliegt, haengt der TX-Ring lautlos: der etcd-Leader verwirft Raft-Nachrichten
  ("sending buffer is full"), die TCP-Streamverbindung bricht mit EOF, raspi5
  verliert reihenweise den Leader, und Applies dauern Sekunden statt 100 ms.
  **Dabei ist jeder Fehlerzaehler null**, man sucht garantiert erst an der
  falschen Stelle.

  `manifests/rpi5-net-tuning/` setzt `tso off`, `gso off` und `rx 4096 tx 2048`
  und haelt sie, weil die Werte einen Link-Reset nicht ueberleben. Hintergrund
  und Messwerte im Kopf von `manifests/rpi5-net-tuning/daemonset.yaml`, upstream
  siderolabs/sbc-raspberrypi#91. Der `nodeSelector` steht fest auf `raspi5`:
  **gilt fuer jeden weiteren Pi**, der ins Cluster kommt.

- **talos-cp-1 traegt den RTL-SDR und ist deshalb ein Pet.** Der Stick haengt an
  pve und wird per qemu-USB durchgereicht (`usb_devices` in
  `homelab-terraform/proxmox/vm-talos.tf`), der readsb-Pod ist per nodeSelector
  daran gebunden. Zwei Eigenheiten: **Proxmox steckt USB heiss dazu**, das
  Hinzufuegen des Blocks startet die VM nicht neu, und **der Dongle laeuft nicht
  an jedem Port**. Hinter dem ASMedia-ASM1074-Hub (`3-2.1`) meldet er sich
  einmal an und verabschiedet sich dann mit `error -71` und "unable to
  enumerate", an `3-2.3` laeuft er fehlerfrei. Bei USB-Problemen also zuerst
  `dmesg -T | grep -i usb` auf pve, nicht im Cluster suchen.

- **CoreDNS forwardet direkt an die beiden Resolver, nicht an hostDNS.** Talos
  deployt vanilla CoreDNS mit `forward . /etc/resolv.conf`. Per Default steht
  dort nur der hostDNS-Proxy `169.254.116.108`, also ein einziger Upstream, und
  ein toter erster Resolver kostet dann jeden Lookup im Cluster mehrere
  Sekunden. Deshalb steht `forwardKubeDNSToHost: false` in `talconfig.yaml`:
  die Pods sehen `.254` und `.253`, und das forward-Plugin nimmt einen toten
  Upstream selbst heraus. Der Host behaelt seinen hostDNS auf `127.0.0.53` und
  damit auch dessen traeges Failover, das betrifft aber nur ihn selbst, im
  Wesentlichen Image-Pulls.

  Kontrolle, welche Upstreams ein Pod wirklich benutzt:

  ```bash
  talosctl -n 192.168.2.23 read /system/resolved/resolv.conf
  kubectl -n kube-system port-forward deploy/coredns 9153:9153
  curl -s localhost:9153/metrics | grep 'proxy_request_duration_seconds_count{'
  ```

  Die Corefile selbst ist der falsche Hebel: die ConfigMap `kube-system/coredns`
  traegt `managedFields` mit `manager: talos, operation: Apply`, Talos besitzt
  also `data.Corefile` und ueberschreibt jeden Patch, sobald es die
  Bootstrap-Manifeste neu anwendet.

- **CoreDNS haengt an Blocky.** Der Split-Horizon-Wildcard fuer
  `*.elmstreet79.de` greift damit auch fuer Pods. Der Preis ist die
  Abhaengigkeit: sterben beide Instanzen, verlieren die Pods jede
  Namensaufloesung.

- **kured und system-upgrade-controller haben hier nichts zu suchen.** Beide
  setzen ein OS mit Paketmanager und Reboot-Semantik voraus. Talos-Upgrades
  laufen ueber `talosctl upgrade`.

- **ArgoCD 3.x legt per Default keine `Endpoints` an.** Seit 3.0 stehen
  `Endpoints` und `EndpointSlice` in den `resource.exclusions`, und
  ausgeschlossen heisst nicht "wird nicht angezeigt", sondern "existiert fuer
  ArgoCD nicht": die handgeschriebenen Endpoints aus
  `manifests/external-services/` wuerden nicht angelegt, die App meldet trotzdem
  Synced und Healthy. Sichtbar nur an 503 von Traefik, weil hinter den
  selektorlosen Services nichts steht. Deshalb nimmt die `resource.exclusions`
  in `homelab-terraform/argocd-talos/main.tf` core/`Endpoints` wieder herein.
