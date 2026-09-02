#!/bin/bash
# Writes the running Plex version, the newest one published on plex.tv and the
# state of Plex' own auto-update as node_exporter textfile metrics.
# Scheduled by ~/Library/LaunchAgents/com.speters.plex-collector.plist.
#
# A failed lookup leaves the previous file untouched instead of reporting
# "current"; HostUpdateMetricsStale is what catches that.
set -u

OUT=/usr/local/var/lib/node_exporter/textfile_collector/plex.prom
TMP="${OUT}.$$"

# Only the MediaContainer line: the XML declaration carries a version="1.0" of
# its own, and apiVersion sits on the same line as the one wanted.
running=$(/usr/bin/curl -sf --max-time 10 http://127.0.0.1:32400/identity |
	grep MediaContainer | tr ' ' '\n' | sed -n 's/^version="\([^"]*\)".*/\1/p')
latest=$(/usr/bin/curl -sf --max-time 10 https://plex.tv/api/downloads/5.json |
	/usr/bin/jq -r '.computer.MacOS.version')

if [ -z "$running" ] || [ -z "$latest" ] || [ "$latest" = null ]; then
	echo "$(date '+%F %T') version lookup failed: running='$running' latest='$latest'" >&2
	exit 1
fi

# Compare the build numbers only, the trailing -hash has no order. Running
# ahead of the public channel must not count as an update.
newest=$(printf '%s\n%s\n' "${running%%-*}" "${latest%%-*}" | sort -V | tail -1)
if [ "${running%%-*}" != "${latest%%-*}" ] && [ "$newest" = "${latest%%-*}" ]; then
	available=1
else
	available=0
fi

# "always" is the only value that installs by itself, "askme" waits forever.
if [ "$(/usr/bin/defaults read com.plexapp.plexmediaserver ButlerTaskUpdateServer 2>/dev/null)" = always ]; then
	auto=1
else
	auto=0
fi

cat >"$TMP" <<EOF
# HELP plex_version_info Running Plex Media Server version and the newest one published for macOS.
# TYPE plex_version_info gauge
plex_version_info{running="$running",latest="$latest"} 1
# HELP plex_update_available Whether plex.tv publishes a newer version than the one running.
# TYPE plex_update_available gauge
plex_update_available $available
# HELP plex_auto_update_enabled Whether Plex installs server updates itself during maintenance.
# TYPE plex_auto_update_enabled gauge
plex_auto_update_enabled $auto
EOF

mv "$TMP" "$OUT"
