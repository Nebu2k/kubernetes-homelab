# macmini host files

Copies of what runs on the macmini outside the cluster. No ArgoCD Application
points here, they all point into `manifests/`. They are in the repo so a
reinstall does not have to rebuild them from memory; the running copy is the one
on the host.

| File | Belongs in |
| --- | --- |
| `plex-collector.sh`, `softwareupdate-collector.sh` | `/usr/local/bin/`, mode 755 |
| `com.speters.*.plist` | `~/Library/LaunchAgents/` |

Both write node_exporter textfile metrics into
`/usr/local/var/lib/node_exporter/textfile_collector/`. That directory only gets
read because `/usr/local/etc/node_exporter.args` carries
`--collector.textfile.directory=...`; brew's plist sources that file, so the
argument survives a `brew upgrade`.

```bash
launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.speters.plex-collector.plist
launchctl kickstart -k gui/501/com.speters.plex-collector   # force a run
launchctl print gui/501/com.speters.plex-collector          # runs, last exit code
```

The alerts reading these metrics are in the `host-updates` group of
`manifests/kube-prometheus-stack/prometheus-rules.yaml`.
