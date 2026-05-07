#!/usr/bin/env bash
# Audit installed state vs. tracked config.
#   - Brew: declared-but-missing AND installed-but-undeclared
#   - Dock: live pinned apps/folders vs. macos/dock.$PROFILE.{apps,others}
#
# Usage:
#   scripts/drift.sh                 # report only (personal profile)
#   scripts/drift.sh work            # report only (work profile)
#   scripts/drift.sh --capture-dock  # rewrite macos/dock.personal.{apps,others} from live state

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CAPTURE_DOCK=0
PROFILE=""
for arg in "$@"; do
  case "$arg" in
    --capture-dock) CAPTURE_DOCK=1 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) PROFILE="$arg" ;;
  esac
done
PROFILE="${PROFILE:-${DOTFILES_PROFILE:-personal}}"

# ---------- Dock capture mode ----------
if [ "$CAPTURE_DOCK" -eq 1 ]; then
  APPS_FILE="$DOTFILES/macos/dock.$PROFILE.apps"
  OTHERS_FILE="$DOTFILES/macos/dock.$PROFILE.others"

  echo "==> Capturing live Dock -> $APPS_FILE, $OTHERS_FILE"
  defaults read com.apple.dock persistent-apps 2>/dev/null \
    | grep _CFURLString \
    | sed -E 's/.*"file:\/\/(.*)\/?".*/\1/' \
    | sed 's/%20/ /g' \
    | sed 's/\/$//' \
    > "$APPS_FILE"
  defaults read com.apple.dock persistent-others 2>/dev/null \
    | grep _CFURLString \
    | sed -E 's/.*"file:\/\/(.*)\/?".*/\1/' \
    | sed 's/%20/ /g' \
    | sed 's/\/$//' \
    | sed "s|^$HOME|~|" \
    > "$OTHERS_FILE"
  echo "==> Done. Review the diff and commit:"
  echo "    git -C $DOTFILES diff macos/dock.$PROFILE.*"
  exit 0
fi

# ---------- Brew section ----------
COMMON="$DOTFILES/brew/Brewfile.common"
PROFILE_FILE="$DOTFILES/brew/Brewfile.$PROFILE"

if [ ! -f "$PROFILE_FILE" ]; then
  echo "No Brewfile for profile '$PROFILE' at $PROFILE_FILE" >&2
  exit 1
fi

echo "==> Brew check against: $COMMON + $PROFILE_FILE"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat "$COMMON" "$PROFILE_FILE" > "$TMP/Brewfile.merged"

echo
echo "--- declared but missing locally ---"
brew bundle check --verbose --file="$TMP/Brewfile.merged" || true

echo
echo "--- installed but not declared (cleanup --dry-run) ---"
brew bundle cleanup --file="$TMP/Brewfile.merged" || true

# ---------- Dock section ----------
APPS_FILE="$DOTFILES/macos/dock.$PROFILE.apps"
OTHERS_FILE="$DOTFILES/macos/dock.$PROFILE.others"

if [ -f "$APPS_FILE" ] && [ -f "$OTHERS_FILE" ]; then
  echo
  echo "==> Dock check"

  LIVE_APPS="$(defaults read com.apple.dock persistent-apps 2>/dev/null \
    | grep _CFURLString \
    | sed -E 's/.*"file:\/\/(.*)\/?".*/\1/' \
    | sed 's/%20/ /g' \
    | sed 's/\/$//')"
  LIVE_OTHERS="$(defaults read com.apple.dock persistent-others 2>/dev/null \
    | grep _CFURLString \
    | sed -E 's/.*"file:\/\/(.*)\/?".*/\1/' \
    | sed 's/%20/ /g' \
    | sed 's/\/$//' \
    | sed "s|^$HOME|~|")"

  TRACKED_APPS="$(grep -vE '^\s*(#|$)' "$APPS_FILE" || true)"
  TRACKED_OTHERS="$(grep -vE '^\s*(#|$)' "$OTHERS_FILE" || true)"

  if [ "$LIVE_APPS" = "$TRACKED_APPS" ] && [ "$LIVE_OTHERS" = "$TRACKED_OTHERS" ]; then
    echo "  Dock matches tracked state."
  else
    echo "  Dock has drifted. Diff (tracked < / live >):"
    diff <(printf '%s\n' "$TRACKED_APPS") <(printf '%s\n' "$LIVE_APPS") || true
    diff <(printf '%s\n' "$TRACKED_OTHERS") <(printf '%s\n' "$LIVE_OTHERS") || true
    echo
    echo "  To accept live state into the repo:"
    echo "    $0 --capture-dock"
  fi
fi

echo
echo "Tip: \`brew bundle dump --file=- --describe\` prints a Brewfile of current state."
