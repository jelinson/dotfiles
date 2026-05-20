#!/usr/bin/env bash
# Personal-profile macOS prefs. Sourced by bootstrap.sh when DOTFILES_PROFILE=personal.
# Idempotent — safe to re-run.

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> macOS defaults: personal"

# --- Dock ---
# App and folder lists are external data files (so scripts/drift.sh can detect
# divergence and rewrite them without sed-editing this script).
if ! command -v dockutil >/dev/null 2>&1; then
  echo "==> dockutil not installed; skipping Dock setup."
  echo "    (Install via Brewfile.personal, then re-run bootstrap.)"
  exit 0
fi

echo "==> Configuring Dock"
dockutil --remove all --no-restart >/dev/null

while IFS= read -r app; do
  [ -z "$app" ] && continue
  case "$app" in \#*) continue ;; esac
  if [ -e "$app" ]; then
    dockutil --add "$app" --no-restart >/dev/null
  else
    echo "  (skip missing: $app)"
  fi
done < "$DIR/dock.personal.apps"

while IFS= read -r path; do
  [ -z "$path" ] && continue
  case "$path" in \#*) continue ;; esac
  expanded="${path/#\~/$HOME}"
  if [ -e "$expanded" ]; then
    dockutil --add "$expanded" --view grid --display folder --sort name --no-restart >/dev/null
  fi
done < "$DIR/dock.personal.others"

killall Dock 2>/dev/null || true
echo "==> Dock configured"
