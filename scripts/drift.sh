#!/usr/bin/env bash
# Audit installed Homebrew state against the tracked Brewfiles.
# Prints anything installed locally but missing from the relevant Brewfile.
#
# Usage: scripts/drift.sh [profile]   (profile defaults to $DOTFILES_PROFILE or 'personal')

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${1:-${DOTFILES_PROFILE:-personal}}"

COMMON="$DOTFILES/brew/Brewfile.common"
PROFILE_FILE="$DOTFILES/brew/Brewfile.$PROFILE"

if [ ! -f "$PROFILE_FILE" ]; then
  echo "No Brewfile for profile '$PROFILE' at $PROFILE_FILE" >&2
  exit 1
fi

echo "==> Checking against: $COMMON + $PROFILE_FILE"

# `brew bundle check` reports anything in the file that ISN'T installed.
# We want the inverse too: things installed that AREN'T in the file.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat "$COMMON" "$PROFILE_FILE" > "$TMP/Brewfile.merged"

echo
echo "--- bundle check (declared but missing locally) ---"
brew bundle check --verbose --file="$TMP/Brewfile.merged" || true

echo
echo "--- bundle cleanup --dry-run (installed but not declared) ---"
brew bundle cleanup --file="$TMP/Brewfile.merged" || true

echo
echo "Tip: \`brew bundle dump --file=- --describe\` prints a Brewfile of current state."
