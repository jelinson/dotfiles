# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal macOS bootstrap. Replaces a new-laptop checklist Google Doc. Lives at
`~/.dotfiles`. Single user (jelinson); no contributors, no test suite, no CI.

## Architecture

Three orthogonal layers, each driven by a different mechanism:

- **Symlinked dotfiles** — GNU Stow packages under `common/`, `personal/`,
  `work/`. Each package mirrors `$HOME`: `common/Library/KeyBindings/X` becomes
  `~/Library/KeyBindings/X`. `bootstrap.sh` runs `stow --restow common` then
  `stow --restow $DOTFILES_PROFILE`.
- **Homebrew packages** — `brew/Brewfile.{common,personal,work}`. Bundle is
  applied as `common` + `$PROFILE`. Splitting rule: `Brewfile.common` is
  universally welcome on any Mac; `mas` and anything that requires personal
  Apple ID sign-in stays in `Brewfile.personal`; `Brewfile.work` is for
  things corp MDM does NOT already provide (typically sparse).
- **macOS preferences** — `macos/defaults.sh` is a flat list of idempotent
  `defaults write` calls. `macos/duti.list` is a stub for default-app
  associations.

The two layers stay decoupled: stowed config files don't depend on Brewfile
state and vice versa. Either can be applied in isolation.

### Profile selection

`DOTFILES_PROFILE` env var (default: `personal`). Only valid values are
`personal` and `work` — `bootstrap.sh` rejects anything else. The variable
controls which secondary stow package and which `Brewfile.$PROFILE` get applied
on top of `common`.

### Entry points

- `install.sh` — bare-macOS curl-pipe entry. Triggers `xcode-select --install`,
  waits for it, clones the repo, hands off to `bootstrap.sh`. Run this exactly
  once per machine via the README one-liner.
- `bootstrap.sh` — idempotent. Run from inside `~/.dotfiles`. Safe to re-run
  any time after a config change; `stow --restow` and `brew bundle` both no-op
  on already-correct state.

## Common operations

```bash
# Apply all repo state to the machine (idempotent):
~/.dotfiles/bootstrap.sh

# Force the work profile for a single run:
DOTFILES_PROFILE=work ~/.dotfiles/bootstrap.sh

# Audit installed brew state vs. tracked Brewfiles:
~/.dotfiles/scripts/drift.sh                # checks personal
~/.dotfiles/scripts/drift.sh work           # checks work

# Add a new tracked dotfile (move-then-restow pattern):
mv ~/.tmux.conf ~/.dotfiles/common/.tmux.conf
~/.dotfiles/bootstrap.sh
```

## Editing conventions

- **Brewfile splits** — when adding a new entry, default to `personal` unless
  the tool is genuinely universal. Chrome, anything `mas`, anything tied to
  personal accounts → `personal`. CLI utilities, neutral GUI apps → `common`.
- **`defaults.sh`** — every line must be idempotent (a re-applied
  `defaults write` is fine; anything else needs guarding). Append a TODO
  comment for prefs that have no `defaults write` equivalent rather than
  silently dropping them.
- **Manual steps** — anything the scripts can't do (Apple ID, Touch ID,
  Bluetooth pairing, display rotation, GUI-only privacy permissions) belongs
  in the README "Manual steps" section, not in a script.
- **Shebangs** — `#!/usr/bin/env bash` for portability across Intel/Apple
  Silicon Homebrew prefixes. `bootstrap.sh` does its own brew-prefix probe
  via `brew shellenv`.

## What lives where, in one line each

- `install.sh`, `bootstrap.sh` — entry points.
- `common/`, `personal/`, `work/` — stow packages (mirror `$HOME`).
- `brew/Brewfile.*` — Homebrew bundle inputs, split by profile.
- `macos/defaults.sh` — `defaults write` seeds.
- `macos/duti.list` — default-app association stub.
- `scripts/drift.sh` — `brew bundle check` + `cleanup --dry-run` audit.
- `scripts/setup-ssh.sh` — one-time ed25519 key gen + `~/.ssh/config` keychain
  persistence + `gh ssh-key add` registration. Required before SSH clone of
  the (currently private) repo.
