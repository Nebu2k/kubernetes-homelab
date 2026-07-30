#!/bin/bash

# Install Git hooks from .githooks/ directory
# Run this once after cloning the repository

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/.githooks"

echo "🔧 Installing Git hooks..."

# Configure Git to use .githooks directory.
# Bewusst RELATIV: Git loest core.hooksPath vom Wurzelverzeichnis des Working
# Tree auf. Ein absoluter Pfad ueberlebt kein Verschieben/Umbenennen des Repos,
# und ein toter hooksPath wird von Git kommentarlos ignoriert - die Hooks waeren
# dann still aus, ohne Fehlermeldung.
git config core.hooksPath ".githooks"

echo "✅ Git hooks installed successfully!"
echo ""
echo "Configured hooks:"
ls -1 "$HOOKS_DIR" | grep -v "install.sh" | grep -v "README.md" || echo "  (none)"
echo ""
echo "To disable hooks temporarily:"
echo "  git commit --no-verify"
