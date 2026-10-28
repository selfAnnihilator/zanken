# Zellij workspace

Prefix: Ctrl+Space or Ctrl+B, release, then press the next key.
Escape cancels the prefix. Ordinary application keys pass through unchanged.

## Zellij's native guide

The default is locked mode, with your frequent shortcuts available directly.
The top guide is hidden while locked, leaving the full height for your apps.
Opening it shows a one-row overlay at the top without resizing your panes.
Alt+G unlocks Zellij's native normal mode; the top guide displays its controls.
Plain h/j/k/l then focus left/down/up/right, staying unlocked for repeated moves.
Press Alt+G again to lock and send ordinary letters to the application.
Ctrl+P opens pane controls, Ctrl+T tab controls, Ctrl+N resize controls,
Ctrl+H move controls, Ctrl+S scroll controls, and Ctrl+O session controls.
Follow the contextual hints. Alt+G from any guided mode locks Zellij again.
Enter/Escape leaves a guide mode and returns keyboard input to the application.
Pane/tab actions and popups also return to locked mode so their displayed keys
work immediately. Alt+G opens the guide again when needed. The unlocked normal
mode is for Zellij controls; type in locked mode.
Ctrl+Space/Ctrl+B still enter your separate tmux-style compatibility prefix.
Native Alt shortcuts follow Zellij defaults while unlocked; the custom shortcuts
below apply in locked mode and the compatibility prefix.

## Panes

Alt+Z                Toggle focused pane zoom (also works in guided modes)
h/j/k/l              Focus left/down/up/right in unlocked normal mode
Ctrl+Shift+H/J/K/L     Focus left/down/up/right
Alt+Enter            Split top/bottom
Alt+Shift+Enter      Split left/right
Alt+Escape           Close the focused pane
Ctrl+Alt+X           Close pane, or its tab if alone; final tab clears saved state (repeat guarded)
Prefix h / v         Split top/bottom / left/right
Prefix z             Zoom pane
Prefix { / }         Move pane left/right
Ctrl+Alt+Shift+arrows Resize in that direction (Zellij's native step size)

## Tabs (tmux windows)

Alt+1 through Alt+9   Select tab
Alt+Left / Right     Previous/next tab
Alt+Shift+Left/Right Move the tab
Prefix c             New tab
Prefix x             Close active pane; if alone, close tab; final close clears saved state
Ctrl+T, then x       Close tab (from the unlocked guide)
Prefix n / p         Next/previous tab
Prefix Tab           Last tab
Prefix r             Rename tab, Enter accepts, Escape cancels

## Sessions

Prefix d             Detach, keep programs running
Prefix s / w         Session manager, including saved/exited sessions
Prefix C             Create or switch to a named session
Prefix R             Rename session
Prefix k / K         Kill current session, clear saved state and close terminal
Prefix P / N         Previous/next live session
Alt+Up / Down        Previous/next live session

Prefix k (lowercase; uppercase K also works) stops all programs in the current
session, deletes its saved resurrection state and closes the launcher terminal
window. It does not create a replacement session. Other sessions are preserved.
Super+Enter then reopens the previous remembered session. If none remains, it
creates a fresh default main workspace.

Prefix x closes only the active pane while other panes exist in its tab. When
it is the only pane, it closes the tab. The final close ends the session and
clears its saved resurrection state; Super+Enter returns to the previous
remembered session, or starts a fresh main workspace if none remains. Ctrl+Alt+X
has the same behavior. Prefix d detaches instead, preserving the tabs and
running programs for your next attach.

## Scrollback and help

Prefix [             Native scroll mode, with contextual hints
j/k, arrows          Scroll down/up
u/d                  Half page up/down
Ctrl+B/F, PageUp/Down Page up/down
s then Enter         Search; n/p selects next/previous match
Search query         Visible in a temporary pane frame; hidden again on exit
c / w / o            Search: case sensitivity / wrap / whole words
e                    Open scrollback in editor
Esc / Enter          Leave scroll mode and return input to the application
Alt+G                Open the native guide / return to locked mode
Mouse selection      Copies to the Wayland clipboard
Prefix ?             This reference (q closes it)
Prefix Ctrl+Space    Send a literal Ctrl+Space to the application
Prefix Ctrl+B        Send a literal Ctrl+B to the application

The configuration reloads automatically when saved.

## Reopening and reboot recovery

Super+Enter focuses the most recently used live workspace's existing Foot
window. If it has no window, it opens a terminal attached to that workspace.
Missing or stale history still falls back to a surviving live session.
Super+Alt+Enter always opens a fresh, separate session.
`t` or `zanken-launch-zellij` resumes the last workspace from a shell;
`zanken-launch-zellij --new` starts a fresh one. Plain `zellij` still attaches
to main by default. Super+T remains available for a plain terminal.
Other named sessions: `zanken-launch-zellij SESSION`.
Session history is stored under `$XDG_STATE_HOME/zanken/` (normally
`~/.local/state/zanken/zellij-session-history`). Killing a session removes it
from that history; an empty history makes Super+Enter start a fresh main session.
The built-in session picker can still select other sessions. Live sessions are
reconciled with history, and existing desktop window focus determines recency.
When no live sessions remain, a saved remembered session can be restored after
reboot; otherwise the launcher starts a fresh main workspace.

Several windows can be attached to the same session. Prefix k kills the session
and closes all of those views. Super+Q/Super+W closes just a window and detaches.

Closing the terminal detaches. After a reboot, reattaching restores saved tabs,
panes, directories, discovered commands, and up to 50,000 scrollback lines per
pane. Restored commands normally wait for Enter; detected editor files can reopen
automatically. Save files before rebooting; application
memory, Neovim buffers, and Claude conversation selection need app-specific
session recovery. Existing tmux sessions are independent and remain available.

## Grouped panes and built-in tools

Alt+P                Add/remove the focused pane from a group
Alt+Shift+P          Toggle group marking while moving between panes
Group menu           b break out, s stack, f float, e embed, l/r break left/right
Group menu           c close selected panes, Tab move menu, Escape cancel
Alt+G, Ctrl+O        Session tools, then follow the displayed letter shortcuts

Vim keys are also available in the local menus where they do not conflict:

- About/tips: j/k select or scroll; h/l navigate horizontally where supported.
  Enter opens, Escape goes back.
- Configuration: h/j/k/l act as arrows; presets support j/k. Capturing a new
  shortcut still accepts literal letters.
- Layout Manager: leave search with Escape (twice when a query is present),
  then j/k select. Enter explicitly opens the selected layout in a new tab.
  h/l do not open or change layouts; `/` returns to search.
- Sharing token list: j/k select, Escape goes back; names accept normal typing.

Session, plugin, and file-picker searches still use h/j/k/l as text.
The new Vim aliases never replace Enter/Escape, open layouts, or confirm actions.
All existing arrow keys and letter actions are preserved. The extended menus
show an extra hint line and may request permissions on their first opening.

Plugin Manager uses the local 0.45.1 repair in `plugins/`; the first opening
asks for its state, launch, and messaging permissions. Its list refreshes once
per second while visible. After upgrading Zellij, retest the bundled manager
before removing the local override.

In the file picker, Escape clears search immediately. Upstream 0.45.1's
Ctrl+C clears the search state but waits for the next key to redraw it.

The full one-row guide lists your actual configured actions, including all
Session tools. Compact is a separate layout with a minimal bar. Layout Manager
Enter opens the selected layout as a new tab; it is not a compact-mode toggle.

Session controls: Alt+G, Ctrl+O, then v opens Layout Manager.
In Session controls, h/l move focus left/right; they never open a tool.

## Appearance

The bottom bar follows xtrasmal's numbered-icon style: muted inactive tabs,
a blue active bold-number tab, dotted separators and a local clock on the right.
Both bars use the same subtle dark strip. The bottom tab bar remains docked.
The full-size numbers are display labels; actual tab names stay available when renaming.
The one-row keyboard guide uses matching colors and dotted separators over the
same dark strip. It appears at the top after Alt+G or Ctrl+Space/Ctrl+B and
disappears when returning to locked mode, with no reserved gap. Normal shows
only the mode menu; entering a mode replaces it with the related keybindings.
No rotating tips or extra hint line are shown.
During search, the query occupies the first line above the guide.
Alt+G still unlocks/locks; all existing keys keep their meanings.
Pane borders and titles are normally hidden. The bottom footer uses two rows: one blank spacer above the one-row tab bar.
The docked tab row uses a full-width dark background; its spacer remains clear.
Style settings live in `layouts/zanken.kdl`.
