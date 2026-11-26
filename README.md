# Dotfiles (macOS)

Personal macOS dotfiles for a tiling + terminal-focused workflow.

<img width="3600" height="2338" alt="Screenshot 2026-10-17 at 18 17 39" src="https://github.com/user-attachments/assets/e9a976d0-d0a7-4320-bf37-285fc412e58a" />

Main stack:
- `aerospace` for window management and its hotkeys
- `sketchybar` (Lua + SbarLua) for the top bar
- `neovim` (Lazy.nvim-based config)
- `ghostty` + `zsh` (`oh-my-zsh` + `powerlevel10k`)
- `zellij` for terminal multiplexing
- `karabiner-elements` for key remapping
- `colima` + Docker CLI for containers (no Docker Desktop)

## What is in this repo

- `aerospace/aerospace.toml` - tiling, workspaces, gaps, floating rules and global hotkeys
- `sketchybar/` - Lua config, widgets, and helper binaries
- `nvim/` - Neovim config and plugin specs
- `ghostty/config` - terminal emulator config
- `zellij/` - multiplexer config and layouts
- `karabiner/` - key remapping (Cmd+hjkl → arrows, Caps Lock double-tap → Escape, hold → Hyper)
- `.zshrc`, `.p10k.zsh` - shell and prompt setup
- `colima/default.yaml` - Colima VM defaults (CPU, memory, disk, vz + Rosetta, virtiofs)

## Tools used by the setup/configs

Installed by `installs` and/or referenced by configs:
- Core: `homebrew`, `git`, `curl`, `coreutils`, `gawk`, `gpg`
- Shell: `oh-my-zsh`, `powerlevel10k`, zsh plugins
- Editors/CLI: `neovim`, `ripgrep`, `jq`, `bat`, `fzf`, `zoxide`, `fd`
- Windowing/UI: `aerospace`, `sketchybar`, `SbarLua`, `lua`
- SketchyBar helpers: `switchaudio-osx`, `nowplaying-cli`, SF fonts
- Runtime managers: `mise` (for `nodejs`, `yarn`, `ruby`, etc.)
- Terminal tools: `ghostty`, `zellij`
- Key remapping: `karabiner-elements`
- Containers: `colima`, `docker`, `docker-compose`, `docker-buildx`, `docker-credential-helper`

Also referenced in `.zshrc` as optional/user-local tools:
- `sdkman`, `bun`, `ghcup`, custom local bins

## Setup

### 1) Clone

```bash
git clone https://github.com/<your-user>/<your-dotfiles>.git ~/dotfiles
cd ~/dotfiles
```

### 2) Install base packages

```bash
bash installs
```

`installs` covers most dependencies, but your shell config also uses `fd`:

```bash
brew install fd
```

### 3) Install extras used by configs

```bash
bash zsh-plugins-install
bash sketchybar/helpers/install.sh
```

`sketchybar/helpers` compiles helper binaries with `make` and `swiftc`, so install Xcode Command Line Tools if needed:

```bash
xcode-select --install
```

### 4) Link configs into `$HOME` and `~/.config`

Run from the repo root:

```bash
bash config.sh
```

This links:
- `nvim` -> `~/.config/nvim`
- `ghostty` -> `~/.config/ghostty`
- `zellij` -> `~/.config/zellij`
- `karabiner` -> `~/.config/karabiner`
- `sketchybar` -> `~/.config/sketchybar`
- `aerospace` -> `~/.config/aerospace`
- `.zshrc` and `.p10k.zsh` -> `~/`
- `colima/default.yaml` -> `~/.colima/_templates/default.yaml`
- merges Homebrew's plugin dir and the keychain credential helper into `~/.docker/config.json`
- copies `.zsh_secrets.example` -> `~/.zsh_secrets`

### 5) Configure secrets/env

Edit `~/.zsh_secrets` and fill values you need (example vars):
- `FONTAWESOME_NPM_AUTH_TOKEN`
- `OPENAI_API_BASE`
- `OPENAI_API_KEY`

## macOS-specific notes

### AeroSpace

AeroSpace needs no SIP changes or sudoers entry. Start it once, grant it
Accessibility access when asked, and it starts at login after that
(`start-at-login` in `aerospace.toml`):

```bash
open -a AeroSpace
brew services start sketchybar
```

It uses its own virtual workspaces rather than macOS Spaces, so keep exactly
one Space per display: remove any extra ones in Mission Control. A window left
on another Space makes macOS slide over to it whenever AeroSpace focuses it.

### Docker (Colima)

Colima doesn't start at login: run `colima start` when you need Docker and
`colima stop` to free its memory. The first start creates the VM from the
template and downloads its image, which takes a few minutes. To keep it
running at login instead, use `brew services start colima`.

`colima/default.yaml` only applies when a VM is created. To change an existing
VM, use `colima start --edit`, or `colima delete && colima start` to rebuild it
from the template (this wipes images and volumes).

Some tools ignore Docker contexts and expect `/var/run/docker.sock`. Point
them at `DOCKER_HOST=unix://$HOME/.colima/default/docker.sock`, or link the socket:

```bash
sudo ln -sf ~/.colima/default/docker.sock /var/run/docker.sock
```

### Optional macOS defaults

You can apply the tweaks in `macconfigs`:

```bash
bash macconfigs
```

## Component docs

- Neovim notes: `nvim/README.md`
- SketchyBar notes: `sketchybar/README.md`

