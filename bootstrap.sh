#!/usr/bin/env bash
# Idempotent bootstrap. Run from inside ~/.dotfiles after install.sh, or directly
# on a machine that already has git + this repo cloned.
#
# Profile selection: DOTFILES_PROFILE=personal|work (default: personal)

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${DOTFILES_PROFILE:-personal}"

case "$PROFILE" in
  personal|work) ;;
  *) echo "Unknown DOTFILES_PROFILE='$PROFILE' (expected: personal | work)" >&2; exit 1 ;;
esac

echo "==> Profile: $PROFILE"
echo "==> Dotfiles: $DOTFILES"

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available in this shell regardless of which prefix it chose.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- stow ---
if ! command -v stow >/dev/null 2>&1; then
  echo "==> Installing stow"
  brew install stow
fi

# --- symlink dotfiles ---
echo "==> Stowing common -> \$HOME"
stow --dir="$DOTFILES" --target="$HOME" --restow common

echo "==> Stowing $PROFILE -> \$HOME"
stow --dir="$DOTFILES" --target="$HOME" --restow "$PROFILE"

# --- brew bundle ---
# --adopt lets brew claim casks whose .app already exists from a non-brew install
# (e.g. direct download). Harmless on a fresh Mac (nothing to adopt).
export HOMEBREW_CASK_OPTS="--adopt"

echo "==> brew bundle: common"
brew bundle --file="$DOTFILES/brew/Brewfile.common"

if [ -s "$DOTFILES/brew/Brewfile.$PROFILE" ]; then
  echo "==> brew bundle: $PROFILE"
  brew bundle --file="$DOTFILES/brew/Brewfile.$PROFILE"
fi

# --- rbenv: install latest stable Ruby if not already set (personal only) ---
if [ "$PROFILE" = personal ] && command -v rbenv >/dev/null 2>&1; then
  LATEST_RUBY=$(rbenv install --list 2>/dev/null | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+\s*$' | tail -1 | tr -d ' ')
  CURRENT_RUBY=$(rbenv global 2>/dev/null || true)
  if [ "$CURRENT_RUBY" != "$LATEST_RUBY" ]; then
    echo "==> Installing Ruby $LATEST_RUBY"
    rbenv install --skip-existing "$LATEST_RUBY"
    rbenv global "$LATEST_RUBY"
  else
    echo "==> Ruby $CURRENT_RUBY already set as global"
  fi
fi

# --- macOS defaults ---
echo "==> Applying macOS defaults: common"
bash "$DOTFILES/macos/defaults.common.sh"

if [ -f "$DOTFILES/macos/defaults.$PROFILE.sh" ]; then
  echo "==> Applying macOS defaults: $PROFILE"
  bash "$DOTFILES/macos/defaults.$PROFILE.sh"
fi

# --- default-app associations (duti) ---
if command -v duti >/dev/null 2>&1 && [ -s "$DOTFILES/macos/duti.list" ]; then
  echo "==> Applying default-app associations from duti.list"
  duti -v "$DOTFILES/macos/duti.list" || true
fi

# --- gh auth ---
if ! gh auth status -h github.com &>/dev/null; then
  echo "⚠ gh: not authenticated with github.com. Run 'gh auth login' when your account is ready."
fi

echo
echo "==> Bootstrap complete. Manual steps remaining: see README.md"
