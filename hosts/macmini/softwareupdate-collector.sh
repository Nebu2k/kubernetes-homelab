#!/bin/bash
# Writes the pending macOS updates as a node_exporter textfile metric.
# Scheduled by ~/Library/LaunchAgents/com.speters.softwareupdate-collector.plist.
#
# A failed scan leaves the previous file untouched instead of reporting zero
# pending updates; HostUpdateMetricsStale is what catches that.
set -u

OUT=/usr/local/var/lib/node_exporter/textfile_collector/softwareupdate.prom
TMP="${OUT}.$$"

list=$(/usr/sbin/softwareupdate --list 2>&1)

# softwareupdate exits 0 in both cases, so the marker line is the only honest
# signal that the scan reached Apple.
if ! grep -qE 'No new software available|found the following' <<<"$list"; then
	echo "$(date '+%F %T') scan failed:" >&2
	echo "$list" >&2
	exit 1
fi

count() { grep -c "$1" <<<"$list" || true; }

pending=$(count '^[[:space:]]*\* Label:')
recommended=$(count 'Recommended: YES')
restart=$(count 'Action: restart')

cat >"$TMP" <<EOF
# HELP softwareupdate_pending Updates offered by softwareupdate --list.
# TYPE softwareupdate_pending gauge
softwareupdate_pending $pending
# HELP softwareupdate_pending_recommended Pending updates Apple marks as recommended.
# TYPE softwareupdate_pending_recommended gauge
softwareupdate_pending_recommended $recommended
# HELP softwareupdate_restart_required Pending updates that need a restart.
# TYPE softwareupdate_restart_required gauge
softwareupdate_restart_required $restart
EOF

mv "$TMP" "$OUT"
