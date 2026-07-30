#!/usr/bin/env bash
#
# Validiert alle Manifeste und Helm-Charts des Repos, ohne Cluster-Zugriff.
# Laeuft lokal und in CI (.github/workflows/validate.yml) ueber denselben Code.
#
#   .github/scripts/validate.sh            # alles
#   .github/scripts/validate.sh manifests  # nur Kustomize-Teil
#   .github/scripts/validate.sh helm       # nur Chart-Teil
#
# Liegt bewusst unter .github/ und nicht in scripts/: dort greift die
# .gitignore-Regel "scripts*/*" (lokale Skripte mit Credentials).
#
# Zweck: Gate fuer Renovate-Automerge. Faengt kaputte Manifeste ab, BEVOR sie
# auf main landen, weil ArgoCD dort mit selfHeal + prune sofort ausrollt.

set -uo pipefail

cd "$(git rev-parse --show-toplevel)"

# Version des Clusters, gegen die validiert wird. Bei k3s-Upgrade mitziehen.
# Aktuell: v1.34.3+k3s1
KUBE_VERSION="1.34.3"

# Helm-Charts, die Cluster-Capabilities abfragen, scheitern sonst beim Rendern.
# traefik/templates/servicemonitor.yaml bricht z.B. hart ab ("You have to deploy
# monitoring.coreos.com/v1 first"), weil helm template die CRDs des Clusters
# nicht kennt. Hier die APIs nachreichen, die im Cluster tatsaechlich existieren.
API_VERSIONS="monitoring.coreos.com/v1"

# Schemas fuer Custom Resources. Der datreeio-Katalog deckt ArgoCD, Traefik,
# cert-manager, Longhorn, MetalLB und Prometheus-Operator ab.
CRD_CATALOG='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

# RecurringJob wird uebersprungen: der datreeio-Katalog hinkt Longhorn hinterher
# und kennt task "system-backup" noch nicht, das die live CRD von Longhorn 1.10
# sehr wohl akzeptiert (geprueft am Cluster). Waere ein reiner Fehlalarm.
# Beim naechsten Longhorn-Update pruefen, ob der Katalog aufgeholt hat.
SKIP_KINDS="RecurringJob"

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
failures=0

# kustomize ist in CI installiert, lokal tut es das eingebaute kubectl kustomize.
if command -v kustomize >/dev/null 2>&1; then
  kbuild() { kustomize build "$1"; }
elif command -v kubectl >/dev/null 2>&1; then
  kbuild() { kubectl kustomize "$1"; }
else
  echo "${RED}Weder kustomize noch kubectl gefunden${RESET}" >&2
  exit 1
fi

for tool in kubeconform helm; do
  command -v "$tool" >/dev/null 2>&1 || { echo "${RED}$tool fehlt${RESET}" >&2; exit 1; }
done

conform() {
  kubeconform \
    -strict \
    -summary \
    -ignore-missing-schemas \
    -skip "$SKIP_KINDS" \
    -kubernetes-version "$KUBE_VERSION" \
    -schema-location default \
    -schema-location "$CRD_CATALOG" \
    -
}

validate_manifests() {
  echo "== Kustomize-Manifeste =="
  for dir in manifests/*/; do
    [ -f "$dir/kustomization.yaml" ] || continue
    name=$(basename "$dir")

    if ! built=$(kbuild "$dir" 2>&1); then
      echo "${RED}✗ $name${RESET} (kustomize build)"
      echo "$built" | head -5 | sed 's/^/    /'
      failures=$((failures + 1))
      continue
    fi

    if out=$(printf '%s' "$built" | conform 2>&1); then
      echo "${GREEN}✓ $name${RESET} ${out##*- }"
    else
      echo "${RED}✗ $name${RESET}"
      echo "$out" | grep -v '^Summary' | head -5 | sed 's/^/    /'
      failures=$((failures + 1))
    fi
  done
}

validate_helm() {
  echo "== Helm-Charts aus apps/ =="

  # ArgoCD-Applications ausparsen. Interessant sind nur sources mit chart:,
  # die zusaetzlichen Self-Referenzen aufs eigene Repo werden ignoriert.
  charts=$(python3 - <<'PY'
import glob, json, yaml
for f in sorted(glob.glob("apps/*.yaml")):
    doc = yaml.safe_load(open(f)) or {}
    if doc.get("kind") != "Application":
        continue
    spec = doc["spec"]
    for src in (spec.get("sources") or [spec.get("source")]):
        if not src or "chart" not in src:
            continue
        helm = src.get("helm") or {}
        vf = helm.get("valueFiles") or []
        print(json.dumps({
            "name": doc["metadata"]["name"],
            "repo": src["repoURL"],
            "chart": src["chart"],
            "version": src["targetRevision"],
            # $values/ zeigt auf die ref-source, also auf dieses Repo
            "values": [v.replace("$values/", "") for v in vf],
            "valuesObject": helm.get("valuesObject"),
        }))
PY
  )

  [ -z "$charts" ] && { echo "${YELLOW}keine Charts gefunden${RESET}"; return; }

  while IFS= read -r line; do
    name=$(printf '%s' "$line" | python3 -c 'import sys,json;print(json.load(sys.stdin)["name"])')
    repo=$(printf '%s' "$line" | python3 -c 'import sys,json;print(json.load(sys.stdin)["repo"])')
    chart=$(printf '%s' "$line" | python3 -c 'import sys,json;print(json.load(sys.stdin)["chart"])')
    version=$(printf '%s' "$line" | python3 -c 'import sys,json;print(json.load(sys.stdin)["version"])')

    helm repo add "val-$name" "$repo" >/dev/null 2>&1

    args=(template "$name" "val-$name/$chart" --version "$version"
          --kube-version "$KUBE_VERSION" --api-versions "$API_VERSIONS")

    # valueFiles direkt durchreichen
    while IFS= read -r vf; do
      [ -n "$vf" ] && args+=(-f "$vf")
    done < <(printf '%s' "$line" | python3 -c 'import sys,json;[print(v) for v in json.load(sys.stdin)["values"]]')

    # valuesObject (inline in der Application) in eine Temp-Datei schreiben
    tmpvals=""
    if printf '%s' "$line" | python3 -c 'import sys,json;sys.exit(0 if json.load(sys.stdin).get("valuesObject") else 1)'; then
      tmpvals=$(mktemp)
      printf '%s' "$line" | python3 -c 'import sys,json,yaml;yaml.safe_dump(json.load(sys.stdin)["valuesObject"],sys.stdout)' > "$tmpvals"
      args+=(-f "$tmpvals")
    fi

    if ! rendered=$(helm "${args[@]}" 2>&1); then
      echo "${RED}✗ $name${RESET} ($chart $version rendert nicht)"
      printf '%s\n' "$rendered" | grep -m3 -i error | sed 's/^/    /'
      failures=$((failures + 1))
      [ -n "$tmpvals" ] && rm -f "$tmpvals"
      continue
    fi
    [ -n "$tmpvals" ] && rm -f "$tmpvals"

    if out=$(printf '%s' "$rendered" | conform 2>&1); then
      echo "${GREEN}✓ $name${RESET} ($version) ${out##*- }"
    else
      echo "${RED}✗ $name${RESET} ($version)"
      echo "$out" | grep -v '^Summary' | head -5 | sed 's/^/    /'
      failures=$((failures + 1))
    fi
  done <<< "$charts"
}

case "${1:-all}" in
  manifests) validate_manifests ;;
  helm)      helm repo update >/dev/null 2>&1; validate_helm ;;
  all)       validate_manifests; echo; helm repo update >/dev/null 2>&1; validate_helm ;;
  *)         echo "usage: $0 [all|manifests|helm]" >&2; exit 2 ;;
esac

echo
if [ "$failures" -gt 0 ]; then
  echo "${RED}$failures Fehler${RESET}"
  exit 1
fi
echo "${GREEN}Alles valide${RESET}"
