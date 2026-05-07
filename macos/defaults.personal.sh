#!/usr/bin/env bash
# Personal-profile macOS prefs. Sourced by bootstrap.sh when DOTFILES_PROFILE=personal.
# Idempotent — safe to re-run.

set -euo pipefail

# --- Dock ---
# Pinned apps + right-side folders, captured from a known-good state.
# Apps that are not installed are skipped (the dock won't show '?' icons).

if ! command -v dockutil >/dev/null 2>&1; then
  echo "==> dockutil not installed; skipping Dock setup."
  echo "    (Install via Brewfile.personal, then re-run bootstrap.)"
  return 0 2>/dev/null || exit 0
fi

echo "==> Configuring Dock"
dockutil --remove all --no-restart >/dev/null

DOCK_APPS=(
  "/System/Applications/Calendar.app"
  "/System/Applications/System Settings.app"
  "/Applications/1Password.app"
  "/Applications/iTerm.app"
  "/Applications/Sublime Text.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Google Chrome.app"
  "/System/Applications/Photos.app"
  "/Applications/Claude.app"
  "/System/Applications/Music.app"
  "/System/Applications/Notes.app"
  "/System/Applications/Contacts.app"
  "/System/Applications/Messages.app"
  "/Applications/Anki.app"
)

for app in "${DOCK_APPS[@]}"; do
  if [ -e "$app" ]; then
    dockutil --add "$app" --no-restart >/dev/null
  else
    echo "  (skip missing: $app)"
  fi
done

DOCK_FOLDERS=(
  "/Applications"
  "$HOME/Documents"
  "$HOME/Documents/job"
  "$HOME/Documents/projects"
  "$HOME/Downloads"
)

for path in "${DOCK_FOLDERS[@]}"; do
  if [ -e "$path" ]; then
    dockutil --add "$path" --view list --display folder --no-restart >/dev/null
  fi
done

killall Dock 2>/dev/null || true
echo "==> Dock configured"
