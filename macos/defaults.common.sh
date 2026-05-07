#!/usr/bin/env bash
# macOS preference seeds. Idempotent — safe to re-run.
# Add `defaults write` lines here as you discover prefs worth tracking.
# Tip: capture a current value with `defaults read <domain> <key>`.

set -euo pipefail

echo "==> macOS defaults"

# --- iTerm2 ---
# Quit when last window is closed (matches expected app lifecycle).
defaults write com.googlecode.iterm2 QuitWhenAllWindowsClosed -bool true

# --- Stage Manager / wallpaper click ---
# Click the wallpaper to reveal the desktop ONLY when Stage Manager is on.
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# --- Finder ---
# Show all filename extensions.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# --- Screenshots ---
# Keep at default (~/Desktop). Override here if you decide otherwise:
# mkdir -p "$HOME/Pictures/Screenshots"
# defaults write com.apple.screencapture location "$HOME/Pictures/Screenshots"

# Items from the original checklist that COULD be scripted but are pending
# decisions on the desired values. See questions in commit/PR history. Once
# decided, encode here and remove from README's manual section.

echo "==> Defaults applied. Some apps need a relaunch to pick changes up."
