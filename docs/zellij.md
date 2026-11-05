# Zellij workflow and keybinds

Zanken opens terminal workspaces in Foot with Zellij and Fish. A **session**
contains tabs; each **tab** contains one or more panes. Use sessions for separate
projects, tabs for tasks, and panes for commands you want visible together.
These keys describe Zanken's bundled configuration, not stock Zellij defaults.

## Open and resume work

| Shortcut | Action |
| --- | --- |
| `Super+Enter` | Focus the most recent workspace window, or open Foot attached to it |
| `Super+Alt+Enter` | Open a fresh, separate session |
| `Super+S` | Open the desktop session picker; type to filter, arrows to select, Enter to open |
| `Super+T` | Open plain Foot without Zellij |
| `t` or `zanken-launch-zellij` | Resume the last workspace from a shell |
| `zanken-launch-zellij project` | Attach to or create the named session `project` |
| `zanken-launch-zellij --new` | Start a fresh session from a shell |

Plain `zellij` uses the configured `main` session. The Zanken launcher remembers
recent workspaces, falls back to surviving sessions, and can restore a remembered
saved session when none is running. Without one, it creates a fresh `main`.

## Everyday workflow

1. Press `Super+Enter` to resume work. For a separate project, use
   `Super+Alt+Enter`, then prefix `R` to give the session a name.
2. Open an editor in one pane. Press `Alt+Shift+Enter` for a pane beside it,
   then run your server or tests there. Use `Ctrl+Shift+H/J/K/L` to move focus.
3. Use prefix `c` for another tab and prefix `r` to name it. Switch with
   `Alt+1` through `Alt+9` or `Alt+Left/Right`.
4. Use prefix `d` to leave programs running. `Super+Enter` returns to the
   workspace; `Super+S` lets you choose another one.

**Prefix** means press `Ctrl+Space` or `Ctrl+B`, release both keys, then press
the listed key. Uppercase keys require Shift. Escape cancels the prefix.

## Panes and tabs

| Shortcut | Action |
| --- | --- |
| `Alt+Enter` / prefix `h` | Split top/bottom |
| `Alt+Shift+Enter` / prefix `v` | Split left/right |
| `Ctrl+Shift+H/J/K/L` | Focus left/down/up/right |
| `Alt+Z` / prefix `z` | Toggle focused pane zoom |
| `Ctrl+Alt+Shift+arrows` | Resize in that direction |
| Prefix `{` / `}` | Move pane left/right |
| `Alt+Escape` | Close the focused pane |
| Prefix `x` / `Ctrl+Alt+X` | Close the focused pane; close its tab if it is the only pane |
| Prefix `c` | New tab |
| Prefix `r` | Rename tab; Enter accepts, Escape cancels |
| `Alt+1`–`Alt+9` | Select tab |
| `Alt+Left/Right` / prefix `p`/`n` | Previous/next tab |
| `Alt+Shift+Left/Right` | Move tab |
| Prefix `Tab` | Switch to last tab |

## Sessions and closing

| Shortcut | Action |
| --- | --- |
| Prefix `d` | Detach, keeping programs running |
| Prefix `s` / `w` | Open the built-in session manager, including saved sessions |
| Prefix `C` | Create or switch to a named session |
| Prefix `R` | Rename the session |
| Prefix `P` / `N`, or `Alt+Up/Down` | Previous/next live session |
| Prefix `k` / `K` | Kill the current session and clear its saved state |

Prefix `k` stops all programs in the session and closes its launcher terminal;
it does not create a replacement. Other sessions are preserved. Multiple windows
attached to that session lose their session together.

Prefix `x` closes one pane at a time. Its final close ends the session and clears
saved resurrection state. Use prefix `d` when you want to return later.
Closing just the Foot window with `Super+Q` or `Super+W` detaches instead.

## Guide and application input

Zellij starts **locked**: ordinary keys go to the application, while the direct
shortcuts above remain available. `Alt+G` opens the native guide. In unlocked
normal mode, `h/j/k/l` move pane focus; return to locked mode before typing.

| After `Alt+G` | Controls |
| --- | --- |
| `Ctrl+P` | Panes |
| `Ctrl+T` | Tabs; `x` closes the whole tab |
| `Ctrl+N` | Resize |
| `Ctrl+H` | Move |
| `Ctrl+S` | Scroll |
| `Ctrl+O` | Sessions and built-in tools |

`Alt+G` locks again. Enter/Escape leave guided modes, and pane/tab actions and
popups return input to locked mode. The one-row guide overlays the top; the
numbered tab bar and clock stay at the bottom. Prefix `?` opens the installed
reference (`q` closes it). Prefix followed by `Ctrl+Space` or `Ctrl+B` sends
that literal control key to the application.

## Scrollback and search

| Shortcut | Action |
| --- | --- |
| Prefix `[` | Enter scroll mode |
| `j/k` or down/up arrows | Scroll down/up |
| `u/d` | Half page up/down |
| `Ctrl+B/F` or PageUp/PageDown | Page up/down |
| `s`, type query, Enter | Search scrollback |
| `n/p` | Next/previous search match |
| `c/w/o` in search mode | Toggle case sensitivity, wrapping, whole words |
| `e` in scroll mode | Open scrollback in the editor |
| Escape/Enter | Return input to the application |
| Mouse selection | Copy to the Wayland clipboard |

The search query appears in a temporary pane frame. Search letters are commands
only after entering the relevant mode.

## Groups and tools

`Alt+P` adds or removes the focused pane from a group. `Alt+Shift+P` toggles
marking while moving between panes. Follow the group menu to stack, float,
embed, break out or close selected panes; Escape cancels.

From `Alt+G`, `Ctrl+O`, use `w` for the session manager, `c` for configuration,
`p` for plugins, `a` for about, or `v` for layouts. Layout Manager's Enter opens
the selected layout in a new tab. Plugins may request permissions on first use.

## Recovery and configuration

The configuration enables layout and viewport serialization every second, with
up to 50,000 scrollback lines per pane. Reattaching after reboot can restore
saved tabs, panes, directories and discovered commands. Ordinary restored
commands wait for Enter; detected editor files can reopen automatically.
This does not restore running process memory or unsaved editor buffers.
Save files and use application-specific recovery where needed.

Session history lives under `~/.local/state/zanken/` (or `$XDG_STATE_HOME/zanken/`).
Killing a session removes it from history. Existing tmux sessions are independent.

The installed configuration is `~/.config/zellij/config.kdl`; layout styling is
in `~/.config/zellij/layouts/zanken.kdl`. Zellij reloads configuration when saved,
but these are managed workflow defaults and release updates replace them.
The bundled plugins require Zellij 0.45.1; see [installation](installation.md).
