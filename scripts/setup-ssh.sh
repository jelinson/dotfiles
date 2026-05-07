#!/usr/bin/env bash
# One-time SSH key setup for GitHub.
# Idempotent: an existing key is reused, an existing ~/.ssh/config block is left alone.
#
# What it does:
#   1. Generates an ed25519 key at ~/.ssh/id_ed25519 if missing.
#   2. Adds a github.com block to ~/.ssh/config so the passphrase persists in the
#      macOS keychain across reboots.
#   3. Loads the key into the agent (with keychain on macOS).
#   4. Copies the public key to the clipboard.
#   5. If `gh` is installed and authenticated, offers to register the key.
#   6. Tests `ssh -T git@github.com`.

set -euo pipefail

KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
CONFIG="$HOME/.ssh/config"
EMAIL="${GIT_EMAIL:-$(git config --global user.email 2>/dev/null || true)}"

if [ -z "$EMAIL" ]; then
  read -r -p "Email for SSH key comment: " EMAIL
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$KEY" ]; then
  echo "==> Key already exists at $KEY — keeping it"
else
  echo "==> Generating ed25519 key at $KEY"
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N ""
fi

# Persist passphrase in macOS keychain across reboots.
if ! grep -q "^Host github.com" "$CONFIG" 2>/dev/null; then
  cat >> "$CONFIG" <<EOF

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $KEY
EOF
  chmod 600 "$CONFIG"
  echo "==> Added github.com block to $CONFIG"
fi

ssh-add --apple-use-keychain "$KEY" 2>/dev/null || ssh-add "$KEY" || true

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$KEY.pub"
  echo "==> Public key copied to clipboard"
fi
echo
echo "Public key:"
cat "$KEY.pub"
echo

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  TITLE="$(scutil --get ComputerName 2>/dev/null || hostname)"
  read -r -p "Register this key with GitHub as '$TITLE'? [y/N] " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    gh ssh-key add "$KEY.pub" --title "$TITLE"
  fi
else
  echo "==> gh not authed; add the key manually at https://github.com/settings/ssh/new"
fi

echo
echo "==> Testing connection to GitHub..."
ssh -o StrictHostKeyChecking=accept-new -T git@github.com || true
