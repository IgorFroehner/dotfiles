# SketchyBar

A Lua configuration for [SketchyBar](https://felixkratz.github.io/SketchyBar) using [SbarLua](https://github.com/FelixKratz/SbarLua), styled with the Nord palette and built around [AeroSpace](https://github.com/nikitabobko/AeroSpace).

## What's on the bar

**Left**

- **Apple logo**: opens the system panel (profile, power actions, battery and uptime, CPU / memory / disk / temperature bars, apps using the most memory)
- **Workspaces 1–9**: AeroSpace's workspaces, shown on the display each one is on; click to focus
- **Front app**: icon and name of the focused app; click to show its menus in the bar

**Right of the notch**

- **Spotify**: current track, click to play/pause, hover for the media panel (artwork and playback controls)

**Right**

- **Clock**: opens the calendar panel (month view, clock, weather)
- **Date**: opens Calendar.app
- **Battery**: charge level; hover for time remaining, click for the Battery menu
- **Wi-Fi**: connection state; hover for SSID, hostname, IP and router (click a row to copy it), click for the Wi-Fi menu
- **Volume**: hover for a slider and output device picker, scroll to adjust, right click for Sound settings

## Layout

```
sketchybarrc            entry point: builds helpers, then loads init.lua
init.lua                loads bar, defaults, events and items in one config batch
bar.lua / default.lua   the --bar and --default domains
settings.lua            sizes, paddings and fonts
colors.lua / icons.lua  palette and SF Symbols
events.lua              custom events (menu swap, AeroSpace workspaces, Spotify)
items/                  one module per bar item, widgets/ for the right side
helpers/
  style.lua             font() helper
  ui.lua                spacer, popup row, menu extra click and panel open/toggle helpers
  menus/                C helper that lists and clicks app / menu bar extra menus
  panels/               SwiftUI app for the system, calendar and media panels
  ssid/                 tiny app that prints the Wi-Fi network name
```

The helper binaries are built by `make` on every load (a no-op when they're up to date).

## Setup

Dependencies: `sketchybar`, `lua`, `aerospace`, `jq` and `switchaudio-osx` from Homebrew, plus SbarLua, which `helpers/install.sh` builds into `~/.local/share/sketchybar_lua`.

macOS only reveals the Wi-Fi network name to apps with Location Services access, so the first time the Wi-Fi popup opens, allow **SSID** when asked (System Settings › Privacy & Security › Location Services).

Weather in the calendar panel comes from [Open-Meteo](https://open-meteo.com) (no API key). Set `weather_city` in `settings.lua` for an exact location; otherwise it is estimated from your IP address.
