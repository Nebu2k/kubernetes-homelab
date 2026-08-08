#!/usr/bin/env bash
# Zieht den node-lokalen Zustand aller Cluster-Nodes ins Repo.
#
# Warum es das gibt: k3s-Flags, DNS-Konfiguration und ein paar Kernel- und
# Boot-Parameter leben ausschliesslich auf den Nodes. Solange das so ist, kann
# keine Node neu gebaut werden, egal ob mit Debian, Terraform oder Talos. Diese
# Dateien sind die Vorlage dafuer.
#
# Der Lauf ist rein lesend und idempotent: er ueberschreibt nodes/<host>/ und
# laesst `git diff` die Abweichung zeigen. Genau so wird er benutzt, naemlich
# als Drift-Check nach jeder Aenderung an einer Node.
#
#   ./nodes/collect.sh          # alle Nodes
#   ./nodes/collect.sh raspi5   # nur eine
#
# Voraussetzung sind die SSH-Aliase aus ~/.ssh/config und passwortloses sudo
# auf den Nodes.
#
# ACHTUNG, das Repo ist public. Der k3s-Server-Token steht im Klartext in der
# ExecStart-Zeile der Server-Units. Er wird beim Kopieren durch einen Platzhalter
# ersetzt, und am Ende laeuft eine Gegenprobe ueber alles Geschriebene. Findet
# sie ein Token-Muster, bricht das Skript ab und loescht nichts weg: dann ist die
# Maskierung defekt und muss repariert werden, bevor irgendetwas committet wird.
set -euo pipefail

cd "$(dirname "$0")/.."
DEST_ROOT="nodes"

ALL_NODES=(k3s-cp-1 k3s-worker-1 prodesk raspi4 raspi5)
NODES=("${@:-}")
[ -z "${NODES[0]:-}" ] && NODES=("${ALL_NODES[@]}")

# Pfade, die auf jeder Node gleich heissen. Fehlt eine, ist das kein Fehler,
# sondern ein Befund: das Ergebnis soll zeigen, wo eine Node abweicht.
COMMON_PATHS=(
  /etc/rancher/k3s/config.yaml
  /etc/systemd/journald.conf.d/99-maxuse.conf
  /etc/sysctl.d/99-k3s-ipv6.conf
  /etc/resolv.conf
)

# Node-spezifisch, per Glob aufgeloest.
GLOB_PATHS=(
  '/etc/systemd/system/k3s.service'
  '/etc/systemd/system/k3s-agent.service'
  '/etc/netplan/*.yaml'
  '/etc/systemd/network/*/no-ra-dns.conf'
  '/etc/NetworkManager/NetworkManager.conf'
  '/boot/firmware/cmdline.txt'
  '/etc/default/dump1090-mutability'
)

fetch() {
  local host="$1" path="$2"
  local dest="$DEST_ROOT/$host${path}"
  mkdir -p "$(dirname "$dest")"
  # Der Token wird schon auf der Node ersetzt, er landet also gar nicht erst
  # in einer lokalen Datei.
  ssh -o ConnectTimeout=8 "$host" "sudo cat '$path' 2>/dev/null | sed -E \"s/'K10[a-f0-9]{64}::server:[a-f0-9]{32}'/'<K3S_SERVER_TOKEN>'/g\"" > "$dest" 2>/dev/null || true
  if [ ! -s "$dest" ]; then
    rm -f "$dest"
    rmdir -p "$(dirname "$dest")" 2>/dev/null || true
    return 1
  fi
  echo "  $path"
}

for host in "${NODES[@]}"; do
  echo "== $host"
  rm -rf "${DEST_ROOT:?}/$host"
  for p in "${COMMON_PATHS[@]}"; do
    fetch "$host" "$p" || echo "  $p  (nicht vorhanden)"
  done
  for g in "${GLOB_PATHS[@]}"; do
    # Globs auf der Node aufloesen, nicht lokal. Das `sh -c` ist noetig, weil
    # raspi5 zsh als Login-Shell hat und ein Glob ohne Treffer dort ein Fehler
    # ist, kein leeres Ergebnis.
    while read -r p; do
      [ -n "$p" ] && fetch "$host" "$p" || true
    done < <(ssh -o ConnectTimeout=8 "$host" "sh -c 'ls -1 $g 2>/dev/null'" || true)
  done
  # Nur die Zeilen der fstab, die ueber das Standard-Layout hinausgehen. Die
  # Root- und Boot-Eintraege haengen an UUIDs dieser Installation und waeren
  # beim Neubau ohnehin andere.
  ssh -o ConnectTimeout=8 "$host" "grep -E '/var/lib/(longhorn|k3s-data)' /etc/fstab 2>/dev/null" \
    > "$DEST_ROOT/$host/etc/fstab.extra" 2>/dev/null || true
  [ -s "$DEST_ROOT/$host/etc/fstab.extra" ] && echo "  /etc/fstab (Zusatz-Mounts)" || rm -f "$DEST_ROOT/$host/etc/fstab.extra"
done

# Gegenprobe: nichts Geheimes darf hier liegen.
if grep -rEn "K10[a-f0-9]{64}::server:|BEGIN [A-Z ]*PRIVATE KEY" "$DEST_ROOT" 2>/dev/null; then
  echo
  echo "ABBRUCH: Secret in $DEST_ROOT gefunden, siehe oben. NICHT committen." >&2
  exit 1
fi
echo
echo "OK, keine Secrets gefunden. Abweichungen zeigt: git diff $DEST_ROOT"
