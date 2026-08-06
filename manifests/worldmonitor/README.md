# worldmonitor: Herkunft und Lizenz

Die vier Images unter `ghcr.io/nebu2k/worldmonitor*` sind **unveraenderte Builds**
von [koala73/worldmonitor](https://github.com/koala73/worldmonitor). Sie
existieren nur, weil Upstream selbst kein Image veroeffentlicht, mit dem sich
der Dienst betreiben liesse: das einzige publizierte (`ghcr.io/koala73/worldmonitor`)
enthaelt nur das Frontend und spricht gegen `api.worldmonitor.app`.

## Was gebaut wird

| Image | Dockerfile | Herkunft |
|---|---|---|
| `worldmonitor` | `Dockerfile` | Upstream, unveraendert |
| `worldmonitor-ais-relay` | `Dockerfile.relay` | Upstream, unveraendert |
| `worldmonitor-redis-rest` | `docker/Dockerfile.redis-rest` | Upstream, unveraendert |
| `worldmonitor-seeder` | `Dockerfile.seeder` (in diesem Verzeichnis) | eigenes Rezept, unveraenderter Upstream-Inhalt |

Der Quellstand steht als voller Commit-SHA im `images:`-Block von
`kustomization.yaml` und ist zugleich der Image-Tag. Zu jedem Image laesst sich
der exakte Quelltext damit ueber

    git clone https://github.com/koala73/worldmonitor && git checkout <tag>

wiederherstellen. Dieselbe Angabe steht als OCI-Label `org.opencontainers.image.revision`
im Image selbst, daneben `org.opencontainers.image.source` mit dem Upstream-Repo.

**Am Programm selbst ist nichts geaendert.** `Dockerfile.seeder` ist ein
Bau-Rezept: es installiert die Abhaengigkeiten aus `scripts/package-lock.json`,
kopiert `scripts/`, `shared/` und `data/` unveraendert hinein und ruft
`scripts/run-seeders.sh` auf. Es gibt keinen Patch, keinen Fork, keine
geaenderte Zeile Quelltext.

## Lizenz

worldmonitor steht unter der **GNU Affero General Public License**. Upstream ist
darin nicht ganz eindeutig: `package.json` deklariert `AGPL-3.0-only`, der Kopf
der `LICENSE`-Datei nennt "version 3 or (at your option) any later version".
Wir labeln die Images mit der engeren Angabe `AGPL-3.0-only`, also der, die
Upstream selbst maschinenlesbar macht. Zusatzklauseln (Commons Clause o.ae.)
gibt es keine.

Zwei Pflichten sind relevant:

**§13, Netzwerknutzung.** Der AGPL-typische Teil verlangt Quelltext fuer Nutzer,
die den Dienst ueber das Netz benutzen, **sofern man das Programm modifiziert
hat**. Wir modifizieren nicht, hier ist nichts zu tun. Der Dienst ist ohnehin
intern-only, ohne Cloudflare-Record.

**§4 und §6, Weitergabe.** Ausgeloest dadurch, dass die GHCR-Packages public
sind und damit von jedem gezogen werden koennen. Verlangt sind klare Hinweise
auf den zugehoerigen Quelltext (Labels oben, plus diese Datei) und eine Kopie
des Lizenztextes beim Objektcode.

**Offener Punkt dabei:** in `worldmonitor-seeder` liegt die Lizenz unter
`/usr/share/doc/worldmonitor/LICENSE`, weil das unser Dockerfile ist. Die
anderen drei werden aus Upstreams Dockerfiles gebaut, und die kopieren die
`LICENSE`-Datei nicht mit. Der Lizenztext liegt bei diesen dreien also nur
mittelbar bei, ueber das `image.source`-Label und diese Datei. Wer das
lueckenlos will, hat zwei Wege: die Packages auf privat stellen und dem Cluster
ein `imagePullSecret` geben (dann wird gar nicht weitergegeben und §4/§6 greifen
nicht), oder im Build-Workflow eine duenne zweite Stufe je Image ergaenzen, die
nichts tut ausser die `LICENSE` hineinzukopieren.
