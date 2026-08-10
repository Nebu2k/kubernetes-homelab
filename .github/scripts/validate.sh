#!/usr/bin/env bash
#
# Validates every manifest and Helm chart in the repo without cluster access.
# Runs locally and in CI (.github/workflows/validate.yml) from the same code.
#
#   .github/scripts/validate.sh            # everything
#   .github/scripts/validate.sh manifests  # kustomize part only
#   .github/scripts/validate.sh helm       # chart part only
#   .github/scripts/validate.sh arch       # only the arm64 test of the images
#
# It lives under .github/ because it belongs to CI, not to the cluster content.
#
# Purpose: the gate for Renovate automerge. It catches broken manifests BEFORE
# they land on main, where ArgoCD rolls them out at once with selfHeal + prune.

set -uo pipefail

cd "$(git rev-parse --show-toplevel)"

# The cluster version validated against. Bump it along with a Talos upgrade:
# the target version is kubernetesVersion in talos/talconfig.yaml, which also
# carries the Renovate anchor.
KUBE_VERSION="1.36.3"

# Charts that query cluster capabilities fail to render otherwise: Traefik's
# servicemonitor template aborts with "You have to deploy
# monitoring.coreos.com/v1 first", because helm template does not know the
# cluster's CRDs. Supply the APIs that actually exist in the cluster.
API_VERSIONS="monitoring.coreos.com/v1"

# Schemas for custom resources. The datreeio catalogue covers ArgoCD, Traefik,
# cert-manager, Longhorn, MetalLB and the Prometheus operator.
CRD_CATALOG='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

# RecurringJob is skipped: the datreeio catalogue trails Longhorn and does not
# know the "system-backup" task, which the live CRD accepts. A pure false
# alarm. Check on the next Longhorn update whether the catalogue caught up.
SKIP_KINDS="RecurringJob"

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
failures=0

# All rendered YAML collects here so the arm64 image test builds on the same
# pass instead of rendering twice. It needs the rendered CHARTS: half the
# cluster's images appear nowhere in the repo and come from the charts.
RENDERED=$(mktemp)
trap 'rm -f "$RENDERED"' EXIT

# kustomize is installed in CI, locally the built-in kubectl kustomize will do.
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

    printf '%s\n---\n' "$built" >> "$RENDERED"

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

  # Parse the ArgoCD Applications. Only sources with chart: are of interest,
  # the additional self-references to this repo are ignored.
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
            # $values/ points at the ref source, i.e. at this repo
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

    # pass valueFiles straight through
    while IFS= read -r vf; do
      [ -n "$vf" ] && args+=(-f "$vf")
    done < <(printf '%s' "$line" | python3 -c 'import sys,json;[print(v) for v in json.load(sys.stdin)["values"]]')

    # write valuesObject (inline in the Application) to a temp file
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

    printf '%s\n---\n' "$rendered" >> "$RENDERED"

    if out=$(printf '%s' "$rendered" | conform 2>&1); then
      echo "${GREEN}✓ $name${RESET} ($version) ${out##*- }"
    else
      echo "${RED}✗ $name${RESET} ($version)"
      echo "$out" | grep -v '^Summary' | head -5 | sed 's/^/    /'
      failures=$((failures + 1))
    fi
  done <<< "$charts"
}

# raspi5 is arm64, the other two nodes are amd64, and all three carry the
# worker label. An image without arm64 therefore does not fail reliably, only
# when the scheduler happens to place the pod there, and exactly that kind of
# fault would slip onto main through Renovate automerge.
#
# The script receives the rendered YAML as a whole, not just the image names:
# whether an amd64-only image is acceptable depends on the workload's
# nodeSelector, which only appears there.
validate_arch() {
  echo "== arm64-Faehigkeit der Images =="

  if [ ! -s "$RENDERED" ]; then
    echo "${YELLOW}nichts gerendert, uebersprungen${RESET}"
    return
  fi

  if ! python3 .github/scripts/check-image-arch.py "$RENDERED"; then
    failures=$((failures + 1))
  fi
}

case "${1:-all}" in
  manifests) validate_manifests ;;
  helm)      helm repo update >/dev/null 2>&1; validate_helm ;;
  arch)      validate_manifests >/dev/null; helm repo update >/dev/null 2>&1
             validate_helm >/dev/null; validate_arch ;;
  all)       validate_manifests; echo; echo; helm repo update >/dev/null 2>&1
             validate_helm; echo; echo; validate_arch ;;
  *)         echo "usage: $0 [all|manifests|helm|arch]" >&2; exit 2 ;;
esac

echo
if [ "$failures" -gt 0 ]; then
  echo "${RED}$failures Fehler${RESET}"
  exit 1
fi
echo "${GREEN}Alles valide${RESET}"
