# Talos-Cluster (Neubau)

Machine configs fuer das neue Talos-Cluster. Es entsteht **parallel** zum
laufenden k3s-Cluster: eine Talos-Node kann einem k3s-Cluster nicht beitreten,
Talos bringt sein eigenes Kubernetes mit. Der Umbau ist deshalb kein Node-Tausch,
sondern zweites Cluster aufbauen, Workloads migrieren, altes abbauen.

## Was hier liegt

| Datei                 | Inhalt                                                        |
| --------------------- | ------------------------------------------------------------- |
| `talconfig.yaml`      | Quelle der Wahrheit fuer alle machine configs                  |
| `talsecret.sops.yaml` | etcd- und Kubernetes-CAs, SOPS/age-verschluesselt               |
| `.sops.yaml`          | age-Recipient fuer die Verschluesselung                        |
| `clusterconfig/`      | generiert, gitignored, enthaelt die CAs im Klartext            |

**Der private age-Key steht in `~/.config/sops/age/keys.txt` und nirgends
sonst.** Ohne ihn ist `talsecret.sops.yaml` unlesbar und das Cluster muss neu
gebaut werden. Gehoert in den Passwortmanager, nicht nur auf den Mac.

## Aufbau

Drei Control-Plane-VMs auf pve, gebaut aus
`homelab-terraform/proxmox/vm-talos.tf`. Drei statt zwei, weil
`talosctl upgrade` die Node rebootet: mit einem einzelnen etcd-Member haengt
jedes Upgrade am verlorenen Quorum.

| Node         | IP             | VM-ID | Rolle                                       |
| ------------ | -------------- | ----- | ------------------------------------------- |
| `talos-cp-1` | 192.168.2.20   | 110   | Control-Plane, schedulet Workloads           |
| `talos-cp-2` | 192.168.2.21   | 111   | Control-Plane, schedulet Workloads           |
| `talos-cp-3` | 192.168.2.22   | 112   | Control-Plane, schedulet Workloads           |
| VIP          | 192.168.2.248  |       | Kubernetes-Endpoint, von Talos selbst        |

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

Image Factory, Schematic
`88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b`:

- `siderolabs/iscsi-tools` und `siderolabs/util-linux-tools` fuer Longhorn
- `siderolabs/qemu-guest-agent` fuer Proxmox

Die ID steht an zwei Stellen (hier in `talconfig.yaml` und in
`homelab-terraform/proxmox/vm-talos.tf`) und muss zusammenpassen. Laufen sie
auseinander, faellt die Node beim naechsten Upgrade auf ein Image ohne
Extensions zurueck und Longhorn verliert seine Volumes.

Die VMs booten vom `nocloud`-Disk-Image, Upgrades laufen ueber
`nocloud-installer`. Ein `metal`-Installer wuerde die Plattform umstellen.

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

- **`node-role.kubernetes.io/worker` laesst sich nicht per machine config
  setzen.** Rund 20 Manifeste selektieren darauf. Talos setzt Node-Labels mit
  den Credentials der Node selbst, und die NodeRestriction-Admission verbietet
  genau dieses Praefix. Das Label muss im Cluster gesetzt werden (kubectl oder
  GitOps), sonst laufen die Dienste dort, wo Platz ist, statt dort, wo RAM ist.
- **PodSecurity steht auf `baseline`.** `longhorn-system` ist in
  `talconfig.yaml` ausgenommen. Alles andere mit `hostNetwork` oder `hostPath`
  (Home Assistant, csi-driver-smb) braucht beim Migrieren ein
  `pod-security.kubernetes.io/enforce: privileged` am Namespace. Das gehoert in
  die Manifeste, nicht hierher: eine Aenderung hier rebootet die Control-Plane.
- **`talosctl reset` nimmt `/var/lib/longhorn` mit.** Die Replikate liegen auf
  der EPHEMERAL-Partition.
- **SealedSecrets:** ein neues Cluster hat einen neuen Controller-Key, damit
  sind alle `*-sealed.yaml` im Repo wertlos. Entweder den bestehenden Key
  uebertragen oder `reseal-all-secrets.sh` gegen den neuen Controller laufen
  lassen. Vor dem Plattform-Bootstrap klaeren.
- **Zwei Cluster heisst zwei kubeconfigs.** Ein Terraform-Stack mit umgebogenem
  kubeconfig zerlegt in der Parallelphase das jeweils andere Cluster.
