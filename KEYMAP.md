# Keymap

Source of truth for keybindings across Karabiner, AeroSpace, Ghostty, zellij,
nvim and zsh. Change a binding here first, then in the tool's config.

## Layers

Each layer of the stack owns one modifier. If you know the layer, you know the
modifier.

| Modifier | Layer | Tool |
|---|---|---|
| `Hyper` (caps lock held) | macOS windows, workspaces, displays | AeroSpace |
| `Alt` (left Option) | terminal panes and tabs | zellij |
| `Ctrl+hjkl` | nvim splits, continuing into zellij panes at the edge | nvim + zellij |
| `Space` (leader) | editor actions | nvim |
| `Cmd` | macOS app conventions | everything; Ghostty translates a few |

**Notation:** `Hyper` = right Ctrl + right Option + right Cmd, sent while caps
lock is held. In `aerospace.toml` it's written `ctrl-alt-cmd`.
`Hyper+Shift+h` means caps + Shift + h.

## Vocabulary

The same key means the same thing at every layer. `Shift` turns "go there"
into "take the current thing there".

| Key | Meaning | `+Shift` |
|---|---|---|
| `h j k l` | focus left / down / up / right | move / swap in that direction |
| `1`–`9` | go to Nth container (space, tab) | send current thing to Nth |
| `[` `]` | prev / next container | send current thing to prev / next |
| `,` `.` | secondary prev / next (displays, swap layouts, buffers) | send to secondary prev / next |
| `n` | new (auto placement) | |
| `x` | close | close the bigger container |
| `f` | fullscreen / zoom | |
| `space` | toggle floating | move between floating and tiled layer |

## Karabiner

| Chord | Action | Was |
|---|---|---|
| caps double-tap | `Esc` | caps tap |
| caps hold | `Hyper` (lazy) | — |
| left `Cmd+hjkl` | arrow keys | same |
| right `Cmd+hjkl` | — (native Cmd) | arrow keys |

## AeroSpace

Workspaces are AeroSpace's own, not macOS Spaces, so switching is instant.
The default layout is a vertical accordion: every window fills the workspace
and `j`/`k` walk through them, like yabai's stack layout. Odd workspaces
live on the main display and even ones on the other, so `Hyper+2` also moves
focus to the second display.

| Chord | Action | Was (yabai) |
|---|---|---|
| `Hyper+hjkl` | focus window | same (`j`/`k` needed a stack fallback) |
| `Hyper+Shift+hjkl` | swap window | same |
| `Hyper+Tab` / `Hyper+Shift+Tab` | next / prev window in the workspace, wrapping around | App Exposé (`Ctrl+↓`) |
| `Hyper+1`–`9` | focus workspace N | focus space N |
| `Hyper+Shift+1`–`9` | send window to workspace N | send window to space N |
| `Hyper+[` / `]` | focus prev / next workspace on the focused display | prev / next space on any display |
| `Ctrl+←` / `→` (`Ctrl+Cmd+h` / `l`) | same as `Hyper+[` / `]` | same, through a display check in skhd |
| `Hyper+Shift+[` / `]` | send window to prev / next workspace on the focused display | prev / next space on any display |
| `Hyper+,` / `.` | focus display left / right | same |
| `Hyper+Shift+,` / `.` | send window to display left / right and follow | same |
| `Hyper+f` | toggle fullscreen inside the workspace | toggle zoom-fullscreen |
| `Hyper+space` | toggle floating | toggle float, centered on a 4:4:1:1:2:2 grid |
| `Hyper+e` | balance sizes | balance space |
| `Hyper+r` | flip orientation | rotate space 270° |
| `Hyper+b` | tiles side by side; again flips to rows | bsp layout |
| `Hyper+s` | vertical accordion; again flips to horizontal | stack layout |

Dropped, with no AeroSpace equivalent: `Hyper+y` / `x` (mirror),
`Hyper+Shift+space` (float the whole space) and `Alt` + mouse drag
(move / resize).

## Ghostty

Ghostty translates macOS tab conventions (Chrome, Safari, Finder, iTerm)
into zellij's Alt chords, so they work the same in the terminal. The Alt chords
stay the real bindings; the Cmd chords are aliases. Ghostty tabs and splits
aren't used, so these override Ghostty's own defaults for the same keys.

| Chord | Sends | Effect | Was |
|---|---|---|---|
| `Cmd+Shift+[` / `]` | `\x1b[91;3u` / `\x1b[93;3u` (`Alt+[` / `]`) | zellij prev / next tab | `Ctrl+Shift+h` / `l` |
| `Ctrl+Shift+Tab` / `Ctrl+Tab` | `\x1b[91;3u` / `\x1b[93;3u` (`Alt+[` / `]`) | zellij prev / next tab | Ghostty tabs |
| `Cmd+1`–`9` | `\x1b[49;3u`–`\x1b[57;3u` (`Alt+1`–`9`) | zellij go to tab N | Ghostty tabs |
| `Cmd+T` | `\x1b[116;3u` (`Alt+t`) | zellij new tab | Ghostty new tab |
| `Cmd+W` | `\x1b[120;3u` (`Alt+x`) | zellij close pane | close Ghostty window |
| `Cmd+Shift+W` | `close_window` (Ghostty action) | close Ghostty window, zellij detaches | — |
| `Cmd+D` / `Cmd+Shift+D` | `\x1b[118;3u` / `\x1b[115;3u` (`Alt+v` / `s`) | zellij split right / down | Ghostty splits |
| `Cmd+Shift+h` / `l` | — | removed | `next_tab` / `previous_tab` (never fired) |

`Cmd+W` on the *last* pane of the *last* tab ends the zellij session (closing
the window with it). `Cmd+Shift+W` only detaches, so the session survives.

Setting: `macos-option-as-alt = left`. Left Option is `Alt`; right Option
still types special characters.

## zellij

### Normal mode (`shared_except "locked"`)

| Chord | Action | Was |
|---|---|---|
| `Ctrl+hjkl` | focus pane, or nvim split if nvim is focused (vim-zellij-navigator) | `Ctrl+Shift+hjkl` |
| `Alt+hjkl` | focus pane (`h`/`l` cross into tabs), bypassing nvim | same, but swallowed by skhd |
| `Alt+Shift+hjkl` | move pane | move mode (unreachable) |
| `Alt+1`–`9` | go to tab N | `Ctrl+Shift+1`–`9` |
| `Alt+[` / `]` | prev / next tab | tab mode `h`/`l` |
| `Alt+Shift+[` / `]` | move tab left / right | `Alt+i` / `o` |
| `Alt+,` / `.` | prev / next swap layout | `Alt+[` / `]` |
| `Alt+n` | new pane (auto) | same |
| `Alt+v` | split right (like nvim `C-w v`) | pane mode `r` |
| `Alt+s` | split down (like nvim `C-w s`) | pane mode `d` |
| `Alt+t` | new tab | `Ctrl+Shift+n` |
| `Alt+Shift+t` | break pane into new tab | tab mode `b` |
| `Alt+x` | close pane | pane mode `x` |
| `Alt+Shift+x` | close tab | `Ctrl+Shift+w` |
| `Alt+f` | toggle pane fullscreen | pane mode `f` (`Alt+f` was floating) |
| `Alt+space` | toggle floating panes | `Alt+f` |
| `Alt+Shift+space` | embed / float current pane | pane mode `e` |
| `Alt+=` / `+` / `-` | resize increase / decrease | same |
| `Alt+p` | pane & tab mode | `Ctrl+p` / `Ctrl+t` |
| `Alt+r` | resize mode | unreachable |
| `Alt+u` | scroll mode | `Ctrl+s` |
| `Alt+o` | session mode | `Ctrl+o` |
| `Alt+g` | lock / unlock | `Ctrl+g` |

Removed: `Ctrl+p`, `Ctrl+t`, `Ctrl+s`, `Ctrl+o`, `Ctrl+b` (tmux mode),
`Ctrl+g`, `Ctrl+q`. Plain Ctrl belongs to nvim and zsh again.

Also removed: `Alt+left/down/up/right`. Option+←/→ is the macOS word jump and
must reach the shell and nvim.

### Modes

All modes exit with `Esc` or `Enter`.

| Mode | Keys |
|---|---|
| pane & tab (`Alt+p`) | `c` rename pane, `r` rename tab, `i` pin, `z` frames, `s` sync tab, `[` / `]` break pane left / right |
| resize (`Alt+r`) | `hjkl` grow, `HJKL` shrink, `+` / `-` |
| scroll (`Alt+u`) | `j`/`k` line, `d`/`u` half page, `h`/`l` page, `s` search, `e` edit scrollback, `Ctrl+c` bottom + exit |
| search | `n`/`p` next / prev, `c` case, `w` wrap, `o` whole word |
| session (`Alt+o`) | `d` detach, `w` sessions, `c` config, `p` plugins, `a` about, `q` quit |

The zjstatus `mode_*` hint strings in `zellij/config.kdl` must match this table.

## nvim

### Ctrl

| Chord | Mode | Action | Was |
|---|---|---|---|
| `Ctrl+hjkl` | n | focus split, then zellij pane at the edge (`navigate()` in `keymaps.lua`) | `<C-w>hjkl` only |
| `Ctrl+,` / `.` | n | prev / next buffer (barbar when `ide_layout`) | same |
| `Ctrl+n` | n | toggle neo-tree | same |
| `Ctrl+l` | i | Copilot accept | same |
| `Ctrl+]` / `Ctrl+p` | i | Copilot next / prev | same (`Ctrl+p` was eaten by zellij) |
| `Ctrl+x` | i | Copilot dismiss | same |
| `Ctrl+d` | telescope buffers (i) | delete buffer | same |

Ctrl keys freed by zellij go back to their nvim defaults: `C-o` jump back,
`C-b` page up, `C-g` file info, `C-q` visual block, `C-s`, `C-t`.

### Built-ins (0.11+), no custom maps

| Key | Action | Replaces |
|---|---|---|
| `K` | hover | `<S-k>` custom map |
| `gd` | definition (Telescope) | same, keep the override |
| `grr` | references (override to Telescope) | `<leader>gr` |
| `grn` | rename | `<leader>rn` |
| `gra` | code action (n, v) | `<leader>ca` |
| `[b` / `]b` | prev / next buffer | — (alias to `Ctrl+,` / `.`) |
| `[c` / `]c` | prev / next git hunk | same (custom) |

### Leader (`Space`)

Each group gets a which-key label. No mapping may be a prefix of another.

| Key | Action | Was |
|---|---|---|
| `<leader><leader>` | buffers | same |
| `<leader>w` / `W` | close buffer / close others | same |
| `<leader>y` | yank to clipboard (operator, n/v) | same |
| **`f` find / files** | | |
| `<leader>ff` | find files | `<D-p>` only |
| `<leader>fg` | live grep | `<D-F>` only |
| `<leader>fb` | buffers | `<D-e>` only |
| `<leader>fr` | recent files in project | same |
| `<leader>fn` | copy file name | `<leader>yf` (shadowed `<leader>y` + `f` motion) |
| **`g` git** | | |
| `<leader>gp` | preview hunk | same |
| `<leader>gb` | toggle line blame | same |
| `<leader>gr` | reset hunk | `<leader>grh` |
| **`c` code** | | |
| `<leader>cf` | format | `<leader>gf` |
| **`a` AI** | | |
| `<leader>ac` | CodeCompanion chat toggle | `<leader>com` |
| **`t` toggles** | | |
| `<leader>tr` | reader mode | `<leader>zr` |

`<D-p>`, `<D-F>` and `<D-e>` stay as aliases only if they reach nvim through
Ghostty → zellij. If they don't, translate them in Ghostty or drop them.

## zsh

| Chord | Action | Was |
|---|---|---|
| `Ctrl+p` | history search up | `Ctrl+j` (reversed vs vim) |
| `Ctrl+n` | history search down | `Ctrl+k` (reversed vs vim) |
| `Alt+←` / `→` | backward / forward word (macOS word jump) | eaten by zellij pane focus |

With `macos-option-as-alt`, Ghostty sends `Alt+←/→` as `\x1b[1;3D` / `\x1b[1;3C`;
bind those to `backward-word` / `forward-word` if zsh doesn't already.

`Ctrl+hjkl` in a shell pane moves zellij focus, so `Ctrl+l` (clear) and fzf's
`Ctrl+j`/`k` are gone. Use `clear` and fzf's `Ctrl+n`/`p` instead.

## Implementation notes

- **Karabiner:** remove the `caps_lock → escape` simple modification. Simple
  modifications run before complex ones and would turn caps into Esc before
  the Hyper rule sees it.
- **Karabiner:** send Hyper as *right*-side modifiers so it can't trigger the
  `left_command+hjkl` arrow rule. AeroSpace's `cmd`/`ctrl`/`alt` match either side.
  Use `optional: ["any"]` on the caps rule so Shift can be added.
- **Hyper timing:** the modifiers are active on key down, so there's no hold
  delay. Esc needs a double tap: the second press must land within 500ms
  of the first, and the first must not have been used as Hyper. A single tap
  (or a held caps released without a chord) sends nothing.
- **AeroSpace:** `[` `]` `,` `.` are `leftSquareBracket` `rightSquareBracket`
  `comma` `period` in binding names.
- **AeroSpace:** `Ctrl+←` / `→` only reach it while macOS's own "Move left / right
  a space" shortcuts are off (`macconfigs` disables them).
- **macOS:** Accessibility shortcuts use `Ctrl+Opt+Cmd+8` (invert colors) and
  `Ctrl+Opt+Cmd+,` / `.` (contrast). Disable them in System Settings →
  Keyboard → Keyboard Shortcuts → Accessibility if they fire instead of AeroSpace.
- **Ghostty → zellij:** `Alt+[` must be sent as kitty CSI-u (`\x1b[91;3u`), not
  `ESC [`, which is ambiguous with every escape sequence.
- **Seamless navigation:** zellij `hiasr/vim-zellij-navigator` (bound to
  `Ctrl+hjkl`) forwards the keys to nvim when it's focused; nvim's `navigate()`
  in `keymaps.lua` calls `zellij action move-focus[-or-tab]` at the edge.

## Adding a binding

1. Pick the layer. That decides the modifier.
2. Reuse a verb from the vocabulary table before inventing a key.
3. Check this file for the chord, including prefixes in nvim.
4. Add it here, then in the config.
