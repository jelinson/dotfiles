#!/usr/bin/env bash
# Idempotent bootstrap. Run from inside ~/.dotfiles after install.sh, or directly
# on a machine that already has git + this repo cloned.
#
# Profile selection: DOTFILES_PROFILE=personal|work (default: personal)

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Profile selection precedence: positional arg > $DOTFILES_PROFILE > default personal
PROFILE="${1:-${DOTFILES_PROFILE:-personal}}"
case "$PROFILE" in
  personal|work) ;;
  *) echo "Error: profile must be 'personal' or 'work' (got: '$PROFILE')" >&2
     echo "Usage: $(basename "$0") [personal|work]" >&2
     exit 1 ;;
esac

if [ $# -eq 0 ] && [ -z "${DOTFILES_PROFILE:-}" ]; then
  echo "==> Profile: $PROFILE (default — pass 'work' or set DOTFILES_PROFILE=work to switch)"
else
  echo "==> Profile: $PROFILE"
fi
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

# --- work profile: ensure a git identity exists before stowing ---
# work/ ships without .gitconfig.local so corp creds aren't committed by default.
# Prompt for them on first run; leave empty to defer.
if [ "$PROFILE" = work ] && [ ! -f "$DOTFILES/work/.gitconfig.local" ]; then
  if [ -t 0 ]; then
    echo "==> work profile is missing git identity (work/.gitconfig.local)"
    read -r -p "    Name (leave blank to skip): " gc_name
    if [ -n "$gc_name" ]; then
      read -r -p "    Email: " gc_email
      cat > "$DOTFILES/work/.gitconfig.local" <<EOF
[user]
	name = $gc_name
	email = $gc_email
EOF
      echo "    Wrote work/.gitconfig.local (review + commit when ready)"
    else
      echo "    Skipping. Re-run bootstrap or write work/.gitconfig.local by hand."
    fi
  else
    echo "⚠ work/.gitconfig.local missing and no TTY to prompt; git commits will fail until you create it" >&2
  fi
fi

# --- stow conflict pre-check ---
# stow's own error on conflict is terse and aborts mid-operation. Dry-run first
# so we can list the exact conflicting files, then offer to back them up (with a
# timestamped suffix so existing .bak files are never clobbered).
check_stow() {
  local pkg="$1" out conflicts ts
  if out=$(stow --dir="$DOTFILES" --target="$HOME" -n --restow "$pkg" 2>&1); then
    return 0
  fi

  # Parse "  * <reason>: <filename>" lines out of stow's conflict report.
  conflicts=$(echo "$out" | grep -E '^[[:space:]]*\*' | sed 's/.*: //')
  if [ -z "$conflicts" ]; then
    echo "⚠ stow failed for '$pkg' (unparseable output):" >&2
    echo "$out" >&2
    exit 1
  fi

  ts=$(date +%Y%m%d-%H%M%S)
  echo "⚠ stow conflicts in '$pkg'. Existing files in \$HOME would block these symlinks:" >&2
  while IFS= read -r f; do echo "    ~/$f" >&2; done <<< "$conflicts"
  echo >&2
  echo "Backup commands (timestamped to avoid clobbering prior .bak files):" >&2
  while IFS= read -r f; do echo "    mv ~/$f ~/$f.bak.$ts" >&2; done <<< "$conflicts"

  if [ -t 0 ]; then
    echo >&2
    read -r -p "Run those backups now? [y/N] " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
      while IFS= read -r f; do
        if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
          mv "$HOME/$f" "$HOME/$f.bak.$ts"
          echo "    moved ~/$f -> ~/$f.bak.$ts"
        fi
      done <<< "$conflicts"
      return 0
    fi
  fi
  exit 1
}
check_stow common
check_stow "$PROFILE"

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
# "Latest stable" here means: the highest X.Y.Z where Y >= 1. This excludes
# brand-new majors (4.0.x, 5.0.x) until they've shipped at least one minor
# release, giving them time to settle. Drop the [1-9] in the regex to track
# absolute-latest instead.
if [ "$PROFILE" = personal ] && command -v rbenv >/dev/null 2>&1; then
  STABLE_RUBY=$(rbenv install --list 2>/dev/null | grep -E '^\s*[0-9]+\.[1-9][0-9]*\.[0-9]+\s*$' | tail -1 | tr -d ' ')
  CURRENT_RUBY=$(rbenv global 2>/dev/null || true)
  if [ "$CURRENT_RUBY" != "$STABLE_RUBY" ]; then
    echo "==> Installing Ruby $STABLE_RUBY"
    rbenv install --skip-existing "$STABLE_RUBY"
    rbenv global "$STABLE_RUBY"
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

# --- MDM detection ---
# On a managed Mac, `defaults write` succeeds but the read returns the MDM-pushed
# value. Flag it so the user doesn't chase ghost preferences.
if [ -d "/Library/Managed Preferences" ] \
   && find "/Library/Managed Preferences" -mindepth 1 -type f -print -quit 2>/dev/null | grep -q .; then
  echo "ℹ Managed Preferences (MDM) detected; some 'defaults write' values may be silently overridden." >&2
fi

# --- default-app associations (duti) ---
if command -v duti >/dev/null 2>&1 && [ -s "$DOTFILES/macos/duti.list" ]; then
  echo "==> Applying default-app associations from duti.list"
  duti -v "$DOTFILES/macos/duti.list" || true

  # If MDM enforces a non-Chrome browser, duti's writes silently lose.
  browser_out=$(duti -x html 2>/dev/null || true)
  if [ -n "$browser_out" ] && ! echo "$browser_out" | grep -qi chrome; then
    echo "⚠ Default .html handler is not Chrome (got: $(echo "$browser_out" | head -1)) — MDM may be overriding duti." >&2
  fi
fi

# --- gh auth ---
if ! gh auth status -h github.com &>/dev/null; then
  echo "⚠ gh: not authenticated with github.com. Run 'gh auth login' when your account is ready."
fi

echo
echo "==> Bootstrap complete. Manual steps remaining: see README.md"
