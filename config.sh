#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    local current_target
    current_target="$(readlink "$dest")"
    if [ "$current_target" = "$src" ]; then
      echo "  [ok] $dest -> $src"
      return
    fi
    echo "  [update] $dest (was -> $current_target)"
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "  [backup] $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  ln -s "$src" "$dest"
  echo "  [link] $dest -> $src"
}

echo "==> Linking configs"

mkdir -p ~/.config

# ~/.config targets
link "$DOTFILES_DIR/nvim"       "$HOME/.config/nvim"
link "$DOTFILES_DIR/ghostty"    "$HOME/.config/ghostty"
link "$DOTFILES_DIR/zellij"     "$HOME/.config/zellij"
link "$DOTFILES_DIR/karabiner"  "$HOME/.config/karabiner"
link "$DOTFILES_DIR/sketchybar" "$HOME/.config/sketchybar"
link "$DOTFILES_DIR/aerospace"  "$HOME/.config/aerospace"
link "$DOTFILES_DIR/git"       "$HOME/.config/git"
link "$DOTFILES_DIR/mise"      "$HOME/.config/mise"

# ~/ targets
link "$DOTFILES_DIR/.zshrc"        "$HOME/.zshrc"
link "$DOTFILES_DIR/.p10k.zsh"     "$HOME/.p10k.zsh"

# Colima template: only used when a VM is created, so an existing one is untouched
mkdir -p "$HOME/.colima/_templates"
link "$DOTFILES_DIR/colima/default.yaml" "$HOME/.colima/_templates/default.yaml"

# Docker CLI config (merged, not linked: `docker login` and colima write to it).
# Finds Homebrew's compose/buildx plugins and keeps registry logins in the
# keychain ("desktop" is Docker Desktop's helper, gone once it's uninstalled).
echo "==> Docker CLI config"
docker_config="$HOME/.docker/config.json"
if command -v jq &>/dev/null; then
  mkdir -p "$HOME/.docker"
  [ -f "$docker_config" ] || echo '{}' > "$docker_config"
  tmp="$(mktemp)"
  jq --arg dir "/opt/homebrew/lib/docker/cli-plugins" '
    .cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$dir] | unique)
    | if .credsStore == null or .credsStore == "desktop" then .credsStore = "osxkeychain" else . end
  ' "$docker_config" > "$tmp"
  mv "$tmp" "$docker_config"
  echo "  [ok] $docker_config"
else
  echo "  [skip] jq not installed, run installs first"
fi

# Secrets file (copy, don't link — it contains local values)
if [ ! -f "$HOME/.zsh_secrets" ]; then
  cp "$DOTFILES_DIR/.zsh_secrets.example" "$HOME/.zsh_secrets"
  echo "  [copy] ~/.zsh_secrets (from example — edit with your values)"
else
  echo "  [ok] ~/.zsh_secrets already exists, skipping"
fi
