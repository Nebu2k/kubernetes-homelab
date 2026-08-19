#!/bin/sh
# Countermeasures from siderolabs/sbc-raspberrypi#91 for end0 on raspi5:
# EEE off, TSO/GSO off, larger ring buffers. The reasoning is in the header of
# daemonset.yaml.
#
# Two quirks explain the structure:
#
# 1. The settings do not survive a link reset, hence the loop rather than a
#    one-off call at startup.
# 2. "ethtool -G" briefly resets the link, so values are compared BEFORE
#    writing and only written on a real difference. Without that comparison
#    the loop would bounce the line every minute and cause exactly what it is
#    meant to prevent.
set -u

IFACE="${IFACE:-end0}"
INTERVAL="${INTERVAL:-60}"
RX_WANT="${RX_WANT:-4096}"
TX_WANT="${TX_WANT:-2048}"

log() { echo "$(date -Iseconds) $*"; }

# "Current hardware settings" is the second block in "ethtool -g", "Pre-set
# maximums" the first. Without switching blocks one reads the maximum instead
# of the current value and never writes.
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

# Sets EEE_STATE to on, off, unsupported or unknown, and keeps the raw output
# in EEE_RAW. Not a $(...) function on purpose: the caller needs both values,
# and a subshell would drop EEE_RAW.
#
# The distinction matters because "cannot read it" is not "it is off". On this
# driver "ethtool --show-eee end0" answers "netlink error: Not supported", so a
# check for "enabled" is false either way and countermeasure 1 from issue 91
# would be silently skipped while the log still looks like a full pass.
EEE_STATE=unknown
EEE_RAW=""
eee_probe() {
  EEE_RAW=$(ethtool --show-eee "$IFACE" 2>&1)
  if echo "$EEE_RAW" | grep -qiE "not supported"; then
    EEE_STATE=unsupported
  elif echo "$EEE_RAW" | grep -qE "EEE status:[[:space:]]*(enabled|active)"; then
    EEE_STATE=on
  elif echo "$EEE_RAW" | grep -qE "EEE status:"; then
    EEE_STATE=off
  else
    EEE_STATE=unknown
  fi
}

dump_state() {
  log "Ist-Zustand $IFACE:"
  # The state, not ethtool's raw answer: a bare "netlink error: Not supported"
  # in the middle of the block reads like a hiccup instead of a knob that is
  # not reachable here.
  eee_probe
  echo "    EEE: $EEE_STATE"
  ethtool -k "$IFACE" 2>/dev/null | grep -E "^(tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload):" | sed 's/^/    /'
  ethtool -g "$IFACE" 2>&1 | sed 's/^/    /'
}

log "Start. Interface=$IFACE Intervall=${INTERVAL}s Ziel: eee off, tso off, gso off, rx=$RX_WANT tx=$TX_WANT"
dump_state

first=1
while :; do
  changed=0

  eee_probe
  case "$EEE_STATE" in
    on)
      # The exit code has to come from ethtool. Piping it into sed makes the
      # if-condition test sed, which succeeds even when ethtool refused.
      out=$(ethtool --set-eee "$IFACE" eee off 2>&1); rc=$?
      [ -n "$out" ] && echo "$out" | sed 's/^/    /'
      if [ "$rc" = 0 ]; then
        log "EEE war aktiv, ausgeschaltet"
      else
        log "EEE ist aktiv, Ausschalten fehlgeschlagen (ethtool rc=$rc)"
      fi
      changed=1
      ;;
    unsupported)
      # Once, not every minute. Reading and writing are separate operations,
      # so the write is attempted rather than assumed to fail: that attempt is
      # the only proof that this knob really is out of reach here.
      if [ "$first" = 1 ]; then
        log "EEE: Status nicht lesbar, der Treiber kennt --show-eee nicht. Setzversuch:"
        out=$(ethtool --set-eee "$IFACE" eee off 2>&1); rc=$?
        [ -n "$out" ] && echo "$out" | sed 's/^/    /'
        if [ "$rc" = 0 ]; then
          log "EEE: Setzen hat trotzdem funktioniert (rc=0)"
        else
          log "EEE: auch nicht setzbar (ethtool rc=$rc). Gegenmassnahme 1 aus Issue 91 laeuft auf dieser Node NICHT, sie muss am Switch-Port erfolgen."
        fi
      fi
      ;;
    unknown)
      [ "$first" = 1 ] && log "EEE: Ausgabe unerwartet, weder Status noch Fehlermeldung erkannt: $(echo "$EEE_RAW" | tr '\n' ' ')"
      ;;
  esac

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
  # Never request beyond the hardware maximum, or ethtool rejects the whole
  # call and the valid second value is not set either.
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
