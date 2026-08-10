#!/bin/bash
set -euo pipefail

# Reseals every *-unsealed.yaml under manifests/.
#
# Seals directly against the controller (--controller-namespace) rather than a
# local cert file. A cert in the repo would be a pure source of error: the
# controller rotates its sealing key every 30 days, the file would stay put,
# and one would eventually seal against a months-old key without anything
# failing. The price is that this script needs cluster access.

HOMELAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTROLLER_NS="kube-system"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check first whether the controller is reachable at all, otherwise the script
# runs through and reports a failure for every single secret.
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

  # Through a temporary file rather than ">" onto the target directly: the
  # redirection would truncate the existing sealed.yaml BEFORE kubeseal runs,
  # so a failure would destroy the working secret.
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
