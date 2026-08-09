#!/bin/sh
# Gegenmassnahmen aus siderolabs/sbc-raspberrypi#91 fuer end0 auf raspi5.
#
# Setzt drei Dinge und haelt sie: EEE aus, TSO/GSO aus, groessere Ring-Buffer.
# Warum, steht im Kopf von daemonset.yaml.
#
# Zwei Eigenheiten, die den Aufbau erklaeren:
#
# 1. Die Einstellungen ueberleben einen Link-Reset nicht. Deshalb die Schleife,
#    nicht ein einmaliges Setzen beim Start.
# 2. "ethtool -G" setzt den Link kurz zurueck. Deshalb wird VORHER verglichen
#    und nur bei echter Abweichung geschrieben. Ohne diesen Vergleich wuerde die
#    Schleife die Leitung im Minutentakt bouncen und genau das erzeugen, was sie
#    verhindern soll.
set -u

IFACE="${IFACE:-end0}"
INTERVAL="${INTERVAL:-60}"
RX_WANT="${RX_WANT:-4096}"
TX_WANT="${TX_WANT:-2048}"

log() { echo "$(date -Iseconds) $*"; }

# "Current hardware settings" ist der zweite Block in "ethtool -g", die
# "Pre-set maximums" der erste. Ohne das Umschalten liest man das Maximum
# statt des Ist-Werts und schreibt nie.
ring_now() {
  ethtool -g "$IFACE" 2>/dev/null | awk -v key="$1" '
    /Current hardware settings:/ { cur = 1; next }
    cur && $1 == key":" { print $2; exit }
  '
}
ring_max() {
  ethtool -g "$IFACE" 2>/dev/null | awk -v key="$1" '
    /Pre-set maximums:/ { pre = 1; next }
    /Current hardware settings:/ { pre = 0 }
    pre && $1 == key":" { print $2; exit }
  '
}
feature_on() { ethtool -k "$IFACE" 2>/dev/null | grep -qE "^$1: on"; }
eee_enabled() { ethtool --show-eee "$IFACE" 2>/dev/null | grep -qE "EEE status:[[:space:]]*enabled"; }

dump_state() {
  log "Ist-Zustand $IFACE:"
  ethtool --show-eee "$IFACE" 2>&1 | sed 's/^/    /'
  ethtool -k "$IFACE" 2>/dev/null | grep -E "^(tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload):" | sed 's/^/    /'
  ethtool -g "$IFACE" 2>&1 | sed 's/^/    /'
}

log "Start. Interface=$IFACE Intervall=${INTERVAL}s Ziel: eee off, tso off, gso off, rx=$RX_WANT tx=$TX_WANT"
dump_state

first=1
while :; do
  changed=0

  if eee_enabled; then
    if ethtool --set-eee "$IFACE" eee off 2>&1 | sed 's/^/    /'; then
      log "EEE war aktiv, ausgeschaltet"
    else
      log "EEE ausschalten fehlgeschlagen (Treiber unterstuetzt es womoeglich nicht)"
    fi
    changed=1
  fi

  for f in tcp-segmentation-offload generic-segmentation-offload; do
    if feature_on "$f"; then
      short=$(echo "$f" | sed 's/tcp-segmentation-offload/tso/; s/generic-segmentation-offload/gso/')
      ethtool -K "$IFACE" "$short" off 2>&1 | sed 's/^/    /'
      log "$f war an, ausgeschaltet"
      changed=1
    fi
  done

  rx_now=$(ring_now RX); tx_now=$(ring_now TX)
  rx_max=$(ring_max RX); tx_max=$(ring_max TX)
  # Nie ueber das Hardware-Maximum hinaus anfordern, sonst lehnt ethtool den
  # ganzen Aufruf ab und auch der gueltige zweite Wert wird nicht gesetzt.
  rx_set=$RX_WANT; tx_set=$TX_WANT
  [ -n "${rx_max:-}" ] && [ "$rx_max" -lt "$rx_set" ] 2>/dev/null && rx_set=$rx_max
  [ -n "${tx_max:-}" ] && [ "$tx_max" -lt "$tx_set" ] 2>/dev/null && tx_set=$tx_max

  if [ -n "${rx_now:-}" ] && [ -n "${tx_now:-}" ] &&
     { [ "$rx_now" != "$rx_set" ] || [ "$tx_now" != "$tx_set" ]; }; then
    log "Ring-Buffer $rx_now/$tx_now weicht ab, setze auf $rx_set/$tx_set (kurzer Link-Reset)"
    ethtool -G "$IFACE" rx "$rx_set" tx "$tx_set" 2>&1 | sed 's/^/    /'
    changed=1
  fi

  if [ "$changed" = 1 ]; then
    log "Nach dem Setzen:"
    dump_state
  elif [ "$first" = 1 ]; then
    log "Alle Zielwerte lagen bereits an, nichts geaendert"
  fi

  first=0
  sleep "$INTERVAL"
done
