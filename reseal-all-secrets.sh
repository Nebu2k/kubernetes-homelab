#!/bin/bash
set -euo pipefail

# Versiegelt alle *-unsealed.yaml unter manifests/ neu.
#
# Sealt direkt gegen den Controller (--controller-namespace) statt gegen ein
# lokales Cert-File. Ein Cert im Repo waere eine reine Fehlerquelle: der
# Controller rotiert seinen Sealing-Key alle 30 Tage, das File bliebe stehen,
# und man versiegelte irgendwann gegen einen Monate alten Key, ohne dass etwas
# fehlschlaegt. Preis dafuer: das Skript braucht Cluster-Zugriff.

HOMELAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTROLLER_NS="kube-system"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Erst pruefen, ob der Controller ueberhaupt erreichbar ist. Sonst laeuft das
# Skript durch und meldet fuer jedes Secret einzeln einen Fehlschlag.
if ! kubeseal --fetch-cert --controller-namespace="${CONTROLLER_NS}" >/dev/null 2>&1; then
  echo -e "${RED}Kein Zugriff auf den sealed-secrets-Controller in ${CONTROLLER_NS}.${NC}" >&2
  echo "kubectl-Kontext pruefen, dann erneut versuchen." >&2
  exit 1
fi

echo "Starting to reseal all secrets..."
echo

SUCCESS=0
FAILED=0

while IFS= read -r unsealed_path; do
  sealed_path="${unsealed_path//-unsealed.yaml/-sealed.yaml}"

  dir=$(dirname "$unsealed_path" | sed "s|${HOMELAB_DIR}/manifests/||")
  unsealed=$(basename "$unsealed_path")
  sealed=$(basename "$sealed_path")

  echo -n "[$dir] $unsealed -> $sealed ... "

  # Ueber eine temporaere Datei, nicht per ">" direkt aufs Ziel: die Umlenkung
  # wuerde das bestehende sealed.yaml leeren, BEVOR kubeseal laeuft. Ein
  # Fehlschlag haette bisher also das funktionierende Secret zerstoert.
  tmp=$(mktemp)
  if kubeseal --format=yaml --controller-namespace="${CONTROLLER_NS}" \
       < "$unsealed_path" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
    mv "$tmp" "$sealed_path"
    echo -e "${GREEN}✓${NC}"
    ((SUCCESS++)) || true
  else
    rm -f "$tmp"
    echo -e "${RED}✗${NC}"
    ((FAILED++)) || true
  fi
done < <(find "${HOMELAB_DIR}/manifests" -type f -name '*-unsealed.yaml' | sort)

echo
echo "==========================================="
if [ "$FAILED" -eq 0 ]; then
  echo -e "${GREEN}Complete: $SUCCESS successful, $FAILED failed${NC}"
else
  echo -e "${RED}Complete: $SUCCESS successful, $FAILED failed${NC}"
fi
echo "==========================================="

[ "$FAILED" -eq 0 ]
