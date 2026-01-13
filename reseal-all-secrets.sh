#!/bin/bash
set -e

# Git root directory
HOMELAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT="${HOMELAB_DIR}/sealed-secrets-pub-cert.pem"

# Farben für Output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting to reseal all secrets..."
echo

# Counter
SUCCESS=0
FAILED=0

# Finde alle -unsealed.yaml Dateien direkt
for unsealed_path in $(find "${HOMELAB_DIR}/manifests" -type f -name '*-unsealed.yaml'); do
  # Bestimme den sealed Namen
  sealed_path="${unsealed_path//-unsealed.yaml/-sealed.yaml}"
  
  # Relative Pfade für Ausgabe
  dir=$(dirname "$unsealed_path" | sed "s|${HOMELAB_DIR}/manifests/||")
  unsealed=$(basename "$unsealed_path")
  sealed=$(basename "$sealed_path")
  
  echo -n "[$dir] $unsealed -> $sealed ... "
  
  # Versiegle neu
  if kubeseal --format=yaml --cert="$CERT" < "$unsealed_path" > "$sealed_path" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((SUCCESS++))
  else
    echo -e "${RED}✗${NC}"
    ((FAILED++))
  fi
done

echo
echo "==========================================="
echo -e "${GREEN}Complete: $SUCCESS successful, $FAILED failed${NC}"
echo "==========================================="
