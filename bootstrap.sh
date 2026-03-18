#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  Dotfiles bootstrap"
echo "============================================"
echo ""

# Xcode Command Line Tools (needed for git, make, swiftc)
if ! xcode-select -p &>/dev/null; then
  echo "==> Installing Xcode Command Line Tools"
  xcode-select --install
  echo "  Waiting for installation to complete..."
  echo "  Re-run this script after Xcode tools finish installing."
  exit 0
fi

# Install packages
bash "$DOTFILES_DIR/installs"

# Link configs
bash "$DOTFILES_DIR/config.sh"

# SketchyBar helpers (fonts, SbarLua)
bash "$DOTFILES_DIR/sketchybar/helpers/install.sh"

# macOS defaults
bash "$DOTFILES_DIR/macconfigs"

# Start services
echo ""
echo "==> Starting services"
brew services start yabai 2>/dev/null || echo "  yabai already running"
brew services start skhd 2>/dev/null || echo "  skhd already running"
brew services start sketchybar 2>/dev/null || echo "  sketchybar already running"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.zsh_secrets with your API keys"
echo "  2. Configure sudoers for yabai: sudo yabai --load-sa"
echo "  3. Restart your terminal"
echo ""
