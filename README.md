
# Dotfiles (macOS)

Personal macOS dotfiles for a tiling + terminal-focused workflow.

Main stack:
- `yabai` + `skhd` for window management
- `sketchybar` (Lua + SbarLua) for the top bar
- `neovim` (Lazy.nvim-based config)
- `ghostty` + `zsh` (`oh-my-zsh` + `powerlevel10k`)
- `zellij` for terminal multiplexing

## What is in this repo

- `yabai/yabairc` - window manager rules, paddings, signals
- `skhd/skhdrc` - global hotkeys for layouts, focus, swaps, spaces
- `sketchybar/` - Lua config, widgets, and helper binaries
- `nvim/` - Neovim config and plugin specs
- `ghostty/config` - terminal emulator config
- `zellij/` - multiplexer config and layouts
- `.zshrc`, `.p10k.zsh` - shell and prompt setup

## Tools used by the setup/configs

Installed by `installs` and/or referenced by configs:
- Core: `homebrew`, `git`, `curl`, `coreutils`, `gawk`, `gpg`
- Shell: `oh-my-zsh`, `powerlevel10k`, zsh plugins
- Editors/CLI: `neovim`, `ripgrep`, `jq`, `bat`, `fzf`, `zoxide`, `fd`
- Windowing/UI: `yabai`, `skhd`, `sketchybar`, `SbarLua`, `lua`
- SketchyBar helpers: `switchaudio-osx`, `nowplaying-cli`, SF fonts
- Runtime managers: `asdf` (plugins for `nodejs`, `yarn`, `ruby`)
- Terminal tools: `ghostty`, `zellij`

Also referenced in `.zshrc` as optional/user-local tools:
- `mise`, `sdkman`, `bun`, `ghcup`, Docker CLI path, custom local bins

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
bash install-asdf-plugins
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
- `.zshrc` and `.p10k.zsh` -> `~/`
- copies `.zsh_secrets.example` -> `~/.zsh_secrets`

### 5) Configure secrets/env

Edit `~/.zsh_secrets` and fill values you need (example vars):
- `FONTAWESOME_NPM_AUTH_TOKEN`
- `OPENAI_API_BASE`
- `OPENAI_API_KEY`

## macOS-specific notes

### yabai scripting addition

`yabai/yabairc` calls:
- `sudo yabai --load-sa`

For this to work cleanly, configure `sudoers` to allow that command without a password.

### Start services

```bash
brew services start yabai
brew services start skhd
brew services start sketchybar
```

### Optional macOS defaults

You can apply the tweaks in `macconfigs`:

```bash
bash macconfigs
```

## Component docs

- Neovim notes: `nvim/README.md`
- SketchyBar notes: `sketchybar/README.md`

