# dotfiles

Personal macOS bootstrap. Replaces the new-laptop checklist Google Doc.

## Layout

```
.dotfiles/
├── install.sh          # bare-macOS entry: installs CLT, clones repo, runs bootstrap
├── bootstrap.sh        # idempotent: brew, stow, brew bundle, defaults
├── common/             # stow package — symlinks into ~ on every machine
├── personal/           # stow package — personal-only overrides
├── work/               # stow package — corp-only overrides
├── brew/
│   ├── Brewfile.common
│   ├── Brewfile.personal
│   └── Brewfile.work
├── macos/
│   ├── defaults.common.sh    # `defaults write` seeds (always applied)
│   ├── defaults.personal.sh  # personal-only (text replacements + Dock)
│   ├── dock.personal.apps    # data file: Dock pinned apps, one per line
│   ├── dock.personal.others  # data file: Dock pinned folders, one per line
│   └── duti.list             # default-app associations (stub)
└── scripts/
    ├── drift.sh        # audit brew + Dock vs. tracked state (--capture-dock to update)
    └── setup-ssh.sh    # one-time: generate ed25519 key, register with GitHub
```

## New-machine setup

The repo is **private**, which means the curl-pipe one-liner won't work
(both `raw.githubusercontent.com` and `git clone` need auth before the repo
is reachable). Use the manual SSH path:

```bash
# 1. Install Xcode Command Line Tools (for git). A GUI dialog will appear.
xcode-select --install

# 2. Generate an SSH key, copy the pubkey, and add it to GitHub.
#    Easiest if `gh` is installed + authed (brew install gh && gh auth login),
#    in which case the script can register the key for you.
bash <(curl -fsSL https://raw.githubusercontent.com/jelinson/dotfiles/main/scripts/setup-ssh.sh) \
  || {
    # Fallback: do it by hand. Pubkey will be on your clipboard via pbcopy.
    ssh-keygen -t ed25519 -C "you@example.com"
    pbcopy < ~/.ssh/id_ed25519.pub
    open https://github.com/settings/ssh/new
  }

# 3. Clone over SSH and bootstrap.
git clone git@github.com:jelinson/dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh

# 4. Re-run setup-ssh.sh to populate ~/.ssh/config (keychain persistence)
#    if you skipped it in step 2.
~/.dotfiles/scripts/setup-ssh.sh
```

To select a profile (default `personal`):

```bash
DOTFILES_PROFILE=work ~/.dotfiles/bootstrap.sh
```

### If the repo is ever made public

```bash
curl -fsSL https://raw.githubusercontent.com/jelinson/dotfiles/main/install.sh | bash
```

`install.sh` triggers the CLT installer, clones via SSH (so `setup-ssh.sh`
must have been run first), and hands off to `bootstrap.sh`.

## What `bootstrap.sh` does

1. Installs Homebrew if missing.
2. Installs `stow`.
3. `stow common` and `stow $DOTFILES_PROFILE` — symlinks dotfiles into `~`.
4. `brew bundle` against `Brewfile.common` then `Brewfile.$PROFILE`.
5. Runs `macos/defaults.sh`.
6. Applies default-app associations from `macos/duti.list`.

Re-run any time. All steps are idempotent.

## Manual steps (cannot be scripted)

Done by hand on every new machine. Keep this list current — it's the canonical
replacement for the old Google Doc.

### Network & accounts
- [ ] Wifi.
- [ ] Apple ID — System Settings → Apple ID. (Personal-only on a corp machine
  unless policy explicitly allows it.)
- [ ] Gmail sign-in.
- [ ] **GitHub CLI auth** — `gh auth login`. Bootstrap warns if skipped but continues.
  `~/.config/gh/hosts.yml` (OAuth tokens) is never tracked; re-auth on each new machine.
  For a work machine with a separate Figma account: `gh auth login`, then verify with `gh auth status`.

### System settings
- [ ] Enable Find My.
- [ ] Touch ID — enroll fingerprints.
- [ ] Night Shift — Displays → Night Shift schedule (currently default-off; not yet scripted).

### Displays
- [ ] Right monitor: rotate 270°.
- [ ] Set the center monitor as main (drag the menu bar in Displays prefs).

### Bluetooth
- [ ] Mouse.
- [ ] Elgato stream deck / lights.
- [ ] Headphones (long-hold the button to enter pairing mode).

### External keyboard
- [ ] Swap Control and Command (System Settings → Keyboard → Modifier Keys, per device).

### Apps
Homebrew installs most apps automatically. Steps below cover sign-in, licensing, or profile import after install.

- [ ] **Chrome** *(Homebrew — personal)* — sign in, let extensions/profiles sync.
- [ ] **1Password** *(manual — App Store, Purchased tab)* — **v6, not v7**: the listing now ships v7+;
  recover v6 from account dropdown → Purchased.
- [ ] **iTerm2** *(Homebrew — common)* — import saved color preset / profile if you have one stashed.
- [ ] **Sublime Text** *(Homebrew — common)* — sign in for license, import User folder if you have one.
- [ ] **Elgato Control Center** *(Homebrew — common)* — pair lights/keys after Bluetooth step above.
- [ ] **Emacs** *(Homebrew — common)* — bring `.emacs` / `init.el` into `common/` once captured.

### Permissions (Privacy & Security)
- [ ] Google Meet / Zoom — Screen Recording, Camera, Microphone.
- [ ] Anything else that prompts on first run.

### Text replacements
- [ ] System Settings → Keyboard → Text Replacements. Not tracked in repo
  (entries contain personal email addresses).

### Shell environment
Tracked by stow:
- `common/.bash_profile` — neutral parts (PS1, brew, NVM); sources `~/.bash_profile.local`.
- `common/.bash_aliases`, `common/.gitignore`, `common/.emacs`, `common/.sqliterc`.
- `common/.gitconfig` — aliases, core, filters. No identity. Includes `~/.gitconfig.local`.
- `personal/.gitconfig.local` — git identity (`[user]` name + email) for the personal account.
- `personal/.bash_profile.local` — personal paths (`proj`/`interviews`/`finance`/`hop`/antigravity).
- `personal/.zshrc`.
- `personal/.config/gh/config.yml` — gh preferences (aliases, protocol, etc). **Not** `hosts.yml` — that holds OAuth tokens and is never tracked.

Not yet captured: `.tmux.conf`. Bring it in once stable.

## Drift audit

```bash
~/.dotfiles/scripts/drift.sh                 # check brew + Dock (personal profile)
~/.dotfiles/scripts/drift.sh work            # check work profile
~/.dotfiles/scripts/drift.sh --capture-dock  # accept live Dock layout into the repo
```

Reports declared-but-missing brew packages, installed-but-undeclared brew
packages, and Dock divergence. Run weekly-ish. After GUI-rearranging the Dock,
run with `--capture-dock` and commit the diff.

## Adding a new tracked dotfile

```bash
# Move the real file into the repo, then re-stow.
mv ~/.tmux.conf ~/.dotfiles/common/.tmux.conf
~/.dotfiles/bootstrap.sh   # re-runs stow, restoring the symlink
```

## Adding a new default-app association

`macos/duti.list` is the source of truth. No Finder UI needed.

```bash
# 1. Append a line to macos/duti.list:
#      <bundle-id> <UTI-or-extension> <role>
#    Roles: all | viewer | editor | shell | none
#    Examples:
#      com.microsoft.vscode  py   all
#      com.google.chrome     pdf  viewer

# 2. Apply it (idempotent — same step bootstrap.sh runs):
duti -v ~/.dotfiles/macos/duti.list

# 3. Confirm it stuck:
duti -x py      # prints the .app path now associated with .py

# Commit and you're done.
```

If you don't know an app's bundle ID:

```bash
osascript -e 'id of app "Visual Studio Code"'
# or:
mdls -name kMDItemCFBundleIdentifier -r "/Applications/Visual Studio Code.app"
```

## Profile guidance

- `Brewfile.common` — universally welcome (CLI tools, neutral GUI apps).
- `Brewfile.personal` — anything that needs a personal Apple ID (`mas`, App
  Store apps), or apps you don't want on a corp machine.
- `Brewfile.work` — only what corp's MDM / Self Service does NOT already
  provide. Likely sparse.

## Corp laptop caveats

Corp MDM/backup typically handles app installs and file backup, but does **not**
cover: shell config, editor config, personal git config, custom keybindings, or
most `defaults write` values. That's where this repo earns its keep on a work
machine. See `Brewfile.work` for guidance on what to put there.
