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
│   ├── defaults.sh     # `defaults write` seeds
│   └── duti.list       # default-app associations
└── scripts/
    └── drift.sh        # audit installed state vs. Brewfiles
```

## New-machine setup

One-liner from a fresh Mac:

```bash
curl -fsSL https://raw.githubusercontent.com/jelinson/dotfiles/main/install.sh | bash
```

That triggers the Xcode CLT GUI installer (for `git`), clones this repo to
`~/.dotfiles`, and hands off to `bootstrap.sh`.

To select a profile (default is `personal`):

```bash
DOTFILES_PROFILE=work curl -fsSL .../install.sh | bash
```

Or, after cloning manually:

```bash
git clone https://github.com/jelinson/dotfiles.git ~/.dotfiles
DOTFILES_PROFILE=personal ~/.dotfiles/bootstrap.sh
```

## What `bootstrap.sh` does

1. Installs Homebrew if missing.
2. Installs `stow`.
3. `stow common` and `stow $DOTFILES_PROFILE` — symlinks dotfiles into `~`.
4. `brew bundle` against `Brewfile.common` then `Brewfile.$PROFILE`.
5. Runs `macos/defaults.sh`.

Re-run any time. All steps are idempotent.

## Manual steps (cannot be scripted)

Done by hand on every new machine. Keep this list current — it's the canonical
replacement for the old Google Doc.

### Network & accounts
- Wifi.
- Apple ID — System Settings → Apple ID. (Personal-only on a corp machine
  unless policy explicitly allows it.)
- Gmail sign-in.

### System settings
- Enable Find My.
- Touch ID — enroll fingerprints.
- Night Shift — Displays → Night Shift schedule.
- Dock — pin/remove apps as desired (no scripted seed yet).

### Displays
- Right monitor: rotate 270°.
- Set the center monitor as main (drag the menu bar in Displays prefs).

### Bluetooth
- Pair mouse / trackpad / keyboard / Elgato.
- Pair home headphones (long-hold the button to enter pairing mode).

### External keyboard
- Swap Control and Command (System Settings → Keyboard → Modifier Keys, per device).
- Home/End — handled automatically by the symlinked
  `~/Library/KeyBindings/DefaultKeyBinding.dict` (stowed from `common/`).

### Apps
- **Chrome** — sign in, let extensions/profiles sync.
- **1Password** — sign in. **v6, not v7**: recover from App Store →
  account dropdown → Purchased (the listing now ships v7+).
- **iTerm2** — `QuitWhenAllWindowsClosed` is set automatically; import any
  saved color preset / profile manually.
- **Sublime Text** — sign in for license, import User folder if you have one.
- **Elgato Control Center** — pair lights/keys.
- **Emacs** — installed via Homebrew; bring `.emacs` / `init.el` into
  `common/` once captured.

### Permissions (Privacy & Security)
- Google Meet / Zoom — Screen Recording, Camera, Microphone.
- Anything else that prompts on first run.

### Shell environment (not yet captured in repo)
The following currently live outside the repo. Move them into `common/` as
you stabilize them, then `bootstrap.sh` will symlink them automatically:
- `.bashrc` / `.bash_profile` (aliases, color prompt, Python setup).
- `.tmux.conf`.
- `.gitconfig`.

## Drift audit

```bash
~/.dotfiles/scripts/drift.sh                # checks personal profile
~/.dotfiles/scripts/drift.sh work           # checks work profile
```

Reports declared-but-missing (need to install) and installed-but-undeclared
(should be added to a Brewfile or removed). Run it weekly-ish.

## Adding a new tracked dotfile

```bash
# Move the real file into the repo, then re-stow.
mv ~/.tmux.conf ~/.dotfiles/common/.tmux.conf
~/.dotfiles/bootstrap.sh   # re-runs stow, restoring the symlink
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
