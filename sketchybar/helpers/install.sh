#!/usr/bin/env bash
set -euo pipefail

# SketchyBar app font
FONT_PATH="$HOME/Library/Fonts/sketchybar-app-font.ttf"
if [ ! -f "$FONT_PATH" ]; then
  echo "==> Installing SketchyBar app font"
  curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf -o "$FONT_PATH"
else
  echo "==> SketchyBar app font already installed"
fi

# SbarLua
if [ ! -f "$HOME/.local/share/sketchybar_lua/sketchybar.so" ]; then
  echo "==> Building and installing SbarLua"
  TMPDIR="$(mktemp -d)"
  git clone https://github.com/FelixKratz/SbarLua.git "$TMPDIR/SbarLua"
  (cd "$TMPDIR/SbarLua" && make install)
  rm -rf "$TMPDIR"
else
  echo "==> SbarLua already installed"
fi
