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
link "$DOTFILES_DIR/git"       "$HOME/.config/git"

# ~/ targets
link "$DOTFILES_DIR/yabai/yabairc" "$HOME/.yabairc"
link "$DOTFILES_DIR/skhd/skhdrc"   "$HOME/.skhdrc"
link "$DOTFILES_DIR/.zshrc"        "$HOME/.zshrc"
link "$DOTFILES_DIR/.p10k.zsh"     "$HOME/.p10k.zsh"

# Secrets file (copy, don't link — it contains local values)
if [ ! -f "$HOME/.zsh_secrets" ]; then
  cp "$DOTFILES_DIR/.zsh_secrets.example" "$HOME/.zsh_secrets"
  echo "  [copy] ~/.zsh_secrets (from example — edit with your values)"
else
  echo "  [ok] ~/.zsh_secrets already exists, skipping"
fi
