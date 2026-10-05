-- Add the sketchybar module to the package cpath
package.cpath = package.cpath .. ";" .. os.getenv("HOME") .. "/.local/share/sketchybar_lua/?.so"

-- Build the helper binaries (no-op when they are up to date)
os.execute("make -C helpers >/dev/null")
