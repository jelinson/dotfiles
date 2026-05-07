#!/usr/bin/env bash
# macOS preference seeds. Idempotent — safe to re-run.
# Captured from a known-good machine state.

set -euo pipefail

echo "==> macOS defaults: common"

# --- Appearance ---
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# --- Title bar / window behavior ---
defaults write NSGlobalDomain AppleActionOnDoubleClick -string "Maximize"
defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false
defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false

# --- Scroll & input ---
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false       # natural scroll OFF
defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 0.125       # very slow mouse wheel
defaults write NSGlobalDomain com.apple.sound.beep.feedback -int 0             # no beep on volume change

# --- Finder ---
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool false

# --- Dock ---
defaults write com.apple.dock mru-spaces -bool false                           # don't auto-rearrange spaces

# --- Stage Manager / wallpaper click ---
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# --- iTerm2 ---
defaults write com.googlecode.iterm2 QuitWhenAllWindowsClosed -bool true

# --- Trackpad (built-in + bluetooth) ---
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  defaults write "$domain" Clicking -bool true                                 # tap to click
  defaults write "$domain" TrackpadThreeFingerDrag -bool false
  defaults write "$domain" TrackpadThreeFingerTapGesture -int 0
done

# --- Mouse (built-in + bluetooth) ---
for domain in com.apple.AppleMultitouchMouse com.apple.driver.AppleBluetoothMultitouch.mouse; do
  defaults write "$domain" MouseButtonMode -string "OneButton"
  defaults write "$domain" MouseTwoFingerDoubleTapGesture -int 3               # Mission Control
done

# --- Screenshots ---
defaults write com.apple.screencapture style -string "selection"
defaults write com.apple.screencapture video -int 0

echo "==> Defaults applied. Some apps need a relaunch to pick changes up."
