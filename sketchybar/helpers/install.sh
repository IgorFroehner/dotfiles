#!/usr/bin/env bash
set -euo pipefail

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
