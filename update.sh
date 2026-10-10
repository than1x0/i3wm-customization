#!/usr/bin/env bash

# ==============================================================================
# Quick Updater for Kali Linux & Debian i3 Customization
# Runs dotfiles update without re-downloading packages or fonts.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pull latest Git changes if requested or running without arguments
if [ "$1" == "--local" ]; then
    bash "$SCRIPT_DIR/installer.sh" --update
else
    bash "$SCRIPT_DIR/installer.sh" --git-update
fi
