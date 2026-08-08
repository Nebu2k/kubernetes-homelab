# Node-lokaler Zustand

Die k3s-Flags, die DNS-Konfiguration und ein paar Kernel- und Boot-Parameter
leben ausschliesslich auf den Nodes, nicht im Cluster und nicht in einem
Helm-Chart. Solange das so ist, kann keine Node neu gebaut werden, egal ob mit
Debian, Terraform oder Talos. Dieses Verzeichnis ist die Vorlage dafuer.

**Es ist eine Kopie, keine Quelle.** Nichts hier wird ausgerollt, ArgoCD sieht
es nicht. Geaendert wird weiterhin auf der Node, danach `./nodes/collect.sh`
und der Diff zeigt, was sich bewegt hat.

```bash
./nodes/collect.sh            # alle Nodes
./nodes/collect.sh raspi5     # nur eine
git diff nodes                # was hat sich seit dem letzten Stand geaendert
```

## Was nicht hier liegt, und warum

Das Repo ist public. Drei Dinge bleiben deshalb aussen vor:

| Was | Wo es liegt | Warum nicht hier |
|-----|-------------|------------------|
| k3s-Server-Token | `ExecStart` der Server-Units, `*.service.env` der Agents | Join-Token fuers Cluster. In den kopierten Units steht `<K3S_SERVER_TOKEN>`. |
| `k3s.yaml` | `/etc/rancher/k3s/` auf den Servern | kubeconfig mit Client-Zertifikat, also Cluster-Admin. |
| `K3S_URL` | `*.service.env` der Agents | Steht ohnehin als `--server` in den Server-Units. |

`collect.sh` prueft nach jedem Lauf, ob ein Token-Muster durchgerutscht ist, und
bricht dann ab. Diese Gegenprobe nicht entfernen.

**Der Token steht im Klartext in der ExecStart-Zeile**, und damit auch in
`ps aux`, sichtbar fuer jeden Nutzer auf der Node. Beim naechsten Node-Neubau
gehoert er in eine `EnvironmentFile`-Datei mit `0600` statt in die Kommandozeile.

## Die drei Node-Typen

| Node | OS | Rolle | Netz/DNS |
|------|----|-------|----------|
| k3s-cp-1, k3s-worker-1, prodesk | Ubuntu 24.04 | server / agent / agent | netplan + systemd-networkd + resolved |
| raspi4 | Debian 13 trixie | server | netplan-NM-Hybrid, NM speichert als netplan-YAML |
| raspi5 | Debian 12 bookworm | server | reines NetworkManager mit `dns=none`, resolv.conf eingefroren |

Alle drei Wege fuehren zum selben Ziel: `1.1.1.1, 192.168.2.16, 192.168.2.4`
und **kein v6-Resolver**. Der Grund ist die 3-Nameserver-Grenze der libc: kommen
per Router-Advertisement noch v6-Resolver dazu, faellt hinten etwas heraus. Auf
den Ubuntu-Nodes stellt der networkd-Drop-in `no-ra-dns.conf` das ab, was netplan
selbst nicht ausdruecken kann (`dhcp6-overrides` greift nur bei DHCPv6, nicht bei
SLAAC/RDNSS).

## Abweichungen zwischen den Nodes

Stand 2026-08-08 beim Einsammeln aufgefallen. Nichts davon ist akut kaputt, aber
beim Neubau soll es nicht unbemerkt mitwandern:

- **raspi4 fehlt `/etc/sysctl.d/99-k3s-ipv6.conf`** (`net.ipv6.conf.all.forwarding = 1`).
  Die anderen vier haben die Datei. Als einzige Node ohne v6-Forwarding ist
  raspi4 damit die Ausnahme, nicht die Regel.
- **raspi5 hat `search elmstreet79.de` in der resolv.conf**, die anderen nicht.
  Auf dieser Node loest ein einlabeliger Name also anders auf als auf den
  uebrigen. Passt zum Wildcard-Rewrite, ist aber nirgends sonst so gesetzt.
- **Unterschiedliche `cmdline.txt`:** raspi5 hat zusaetzlich
  `cgroup_enable=cpuset`, raspi4 dafuer `cfg80211.ieee80211_regdom=DE`.
  `cgroup_memory=1 cgroup_enable=memory` steht auf beiden und ist fuer k3s auf
  Raspberry Pi Pflicht. Ohne das startet kubelet nicht.
- **worker-1 hat zwei zusaetzliche Datentraeger** (`etc/fstab.extra`):
  `/var/lib/longhorn` und `/var/lib/k3s-data`, wobei `/var/lib/rancher` ein
  Symlink nach `/var/lib/k3s-data/rancher` ist. Ein Neubau ohne diesen Symlink
  legt k3s auf die Systemplatte.
- **Auf den Server-Nodes liegen alte `k3s.service.bak-*`-Dateien** von frueheren
  Aenderungen. Nicht kopiert, aber gut zu wissen, dass sie da sind.

## Beim Wiederaufbau

- **Debian/Ubuntu:** die Dateien per cloud-init an ihren Pfad legen, das ist
  eine 1:1-Uebernahme. Danach Node-DNS pruefen, sonst kommen die toten
  RA-v6-Resolver zurueck.
- **Talos:** der journald-Teil entfaellt ersatzlos, Talos hat kein systemd. Der
  Image-GC-Teil aus `config.yaml` gehoert nach `machine.kubelet.extraConfig` und
  wird dort besser als heute: die volle `KubeletConfiguration` erlaubt
  `imageMaximumGCAge`, also Aufraeumen nach Alter statt nach Fuellstand. Unter
  k3s ging das nicht, weil der Parameter kein CLI-Flag hat und `--kubelet-arg`
  nur Flags durchreicht.
- **Die etcd-Mehrheit darf nicht auf ein Blech wandern.** Heute sitzt cp-1 auf
  pve und die zwei Raspis auf eigener Hardware. Bei jedem Node-Tausch pruefen,
  dass das so bleibt.
