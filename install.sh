#!/usr/bin/env bash
# Bare-macOS entry point. Run via:
#   curl -fsSL https://raw.githubusercontent.com/jelinson/dotfiles/main/install.sh | bash
# Installs Xcode CLT (for git), clones the repo, then hands off to bootstrap.sh.

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-git@github.com:jelinson/dotfiles.git}"
TARGET="${DOTFILES_DIR:-$HOME/.dotfiles}"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "==> Installing Xcode Command Line Tools (a GUI dialog will appear)..."
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
  echo "==> Command Line Tools installed."
fi

if [ ! -d "$TARGET/.git" ]; then
  echo "==> Cloning $REPO_URL -> $TARGET"
  git clone "$REPO_URL" "$TARGET"
else
  echo "==> $TARGET already exists; pulling latest"
  git -C "$TARGET" pull --ff-only
fi

exec "$TARGET/bootstrap.sh" "$@"
