# Zellij menus and bars

## zjstatus bottom bar

`zjstatus.wasm` is based on the official [v0.25.0 source](https://github.com/dj95/zjstatus/releases/tag/v0.25.0)
with the small local `zjstatus.patch`: `{index_icon}` displays numbered Nerd Font
boxes for tabs 1–9, with a numeric fallback above 9. Tab names and click targets
are preserved. The previous official binary checksum is retained in
`zjstatus.upstream.sha256`; `zjstatus.sha256` verifies the installed local build.
The MIT license is `zjstatus.LICENSE`. The current preset uses padded bold `{index}` digits; the optional boxed glyph extension remains available.

The bottom row follows [xtrasmal's preset](https://gist.github.com/xtrasmal/1a56f8bb269ff769492cc5287022ce0f):
bold number labels, dotted separators, pink skull/yellow smile modes and a
local clock on the right. The decorative heart and arrow from the reference
are removed. Gaps between the mode icon, tab numbers and separators use two spaces.
The docked tab row uses a full-width dark strip (`#242436`), matching the
top guide. The blank spacer above it retains the terminal background. It uses a two-row borderless footer: a blank spacer above the tab row, with local Indian time.
A blank top border (`border_char " "`, `border_position "top"`) reserves the
spacer inside the two-row plugin pane, keeping the terminal content clear of it.
The user retained the previous full-size bold numbers and brighter clock;
the terminal default is 11pt. Other control modes remain visible with colored names. The tab rename field
shows the actual name. Existing keybindings are retained rather than copied
from the reference. Rebuild the tab bar with `bash build-zjstatus.sh`; `build.sh`
rebuilds the six local Zellij extensions separately.

The layout uses an explicit local URL and inline configuration. New tabs use
this layout. When relocating an existing bar, serialize the current layout,
change only the bar configuration/position and apply with both retain-existing
flags, verifying terminal IDs, running commands and floating geometry in a
private session first. A dumped foreground command can differ from the original
shell invocation: normalize only confirmed shell-origin panes back to bare pane
slots and remove inherited root cwd when matching those original invocations,
or override can create duplicate applications even with retention enabled.
Close only the identified old bar before applying so it
is not retained as an extra pane. Preserve tab names, existing terminal commands,
float visibility and the new-tab template; never close working tabs to restyle.
Back up source/installed layouts and saved session state before deployment.

## Local menus for Zellij 0.45.1

The local About, Configuration, Layout Manager, and Share menus add Vim keys
only in contexts where those letters are unused:

- About pages and tips: j/k select or scroll; h/l follow left/right navigation.
  Enter opens a selection and Escape goes back.
- Configuration: h/j/k/l mirror the arrows; presets add j/k. Shortcut capture
  receives the actual key, including h/j/k/l. The existing preset l is preserved.
- Layout Manager: after leaving search with Escape, j/k select. h/l do not
  trigger open, close, save or layout changes. Enter explicitly opens the selected
  layout in a new tab; Alt+W remains the native override action.
  Search still starts immediately; Escape clears a nonempty query first, then
  leaves search on the next press. Name and search fields remain literal.
- Sharing token list: j/k select; h/l follow left/right navigation. Escape goes back.
  Token names remain literal.

Session Manager, Plugin Manager, and the file picker retain their original
letter-to-search behavior, including h/j/k/l. No search-mode change is required.
Arrows and existing shortcuts remain available. Each extended menu shows an
additional hint line.

`vim-navigation.patch` adds these aliases to the official `v0.45.1` source.
The four files are launched directly from the session controls, so existing
sessions do not need to restart. Local menus request the capabilities their
upstream implementations use on first opening. Sharing initializes token access
only after permission is granted, because a denied synchronous query can panic.

## Native guide repair

QuickNav recognizes new-pane shortcuts followed by return-to-Normal or
return-to-Locked, so the configured Alt+n shortcut is shown instead of UNBOUND.
This changes hint lookup only; shortcut actions stay unchanged.

`status-bar.patch` keeps the native key lookup and adds a one-row contextual guide. It matches actions that
return to Locked as well as Normal, and lists all six Session tools by their
configured alias, built-in URL, or local WASM path. The old two-line implementation
only attempted Session Manager and discarded that match when its return mode
was Locked. The one-line menu lookup also supports the local files.

The alias keeps `hide_when_locked true`, `overlay true`, and `search_titles true`.
The overlay defaults to the new reference style; an optional `reference_style false`
retains native ribbons. Keeping the alias options unchanged preserves live
MessagePlugin routing for the close/reset shortcuts. The reference style uses gray/blue labels and cyan dotted separators over a
full-width dark strip (`#242436`). Normal shows only the mode menu, with no
rotating tip. Entering a mode replaces that menu with its related shortcuts
in the same row. The prefix view includes close, detach, kill and sessions
using the actual configured actions. Width adaptation stays native.
One background guide loaded by `load_plugins` follows the active tab. It is
suppressed while locked and appears as a pinned, borderless one-row floating
overlay at the top while using controls. No rows are reserved and terminal geometry stays
unchanged. The background load also restores the guide after resurrection.
Search temporarily enables the native pane frame and moves the guide down one
row so the query remains visible above it.
The overlay, hide and search options default to false for layouts that use the
ordinary fixed guide; reference styling follows the overlay setting unless
explicitly configured.

`config.kdl` maps the `status-bar` alias to this WASM and loads it in the background.
Session-mode h/l move pane focus; v opens Layout Manager.
Existing built-in bars must be replaced in place without replacing
terminal panes. For an overlay update, close only the known old guide panes,
then load one replacement with all three options through `zellij pipe` (below);
startup uses `load_plugins`. Do not use `launch-plugin` for the overlay: it
creates a tab-bound instance that stops receiving mode changes once suppressed.

```bash
zellij --session NAME pipe \
  --plugin "file:$HOME/.config/zellij/plugins/status-bar.wasm" \
  --plugin-configuration hide_when_locked=true,overlay=true,search_titles=true \
  --name zanken-guide-init ready
```

Close only the identified old guide first so the pipe creates a new background
instance. Grant permissions to that guide, then toggle modes to verify both
visibility and hidden geometry. This also works after detaching and reattaching.
The background guide also removes obsolete footer instances from cached layouts.
For fixed guides, its `zanken-replace-guide` pipe accepts an explicit new:old
plugin ID pair, validates the old pane is a guide, and replaces only that pane.
These IDs are never saved in configuration or resurrection state. First use requests the read/change-state capabilities used by
the native bar, local maintenance messages, and running the local session helper
for Ctrl+Alt+X and prefix x; allow initialization to finish before testing mode shortcuts.
The session helper ignores repeated close requests until there has been a
750ms quiet gap, preventing a held key from cascading through panes and tabs.

Prefix k/K kills the current session and removes its saved state through a
detached helper, allowing the launcher terminal to close. It does not use a
reset bridge or reopen a replacement session.
The helper also removes that session from the persistent launcher history.
Super+Enter selects a surviving live session even when history is empty/stale,
preferring the most recently focused matching Foot window. It focuses that
window instead of creating a second view. Detached sessions are attached in a
new terminal; saved remembered sessions can resurrect when no live sessions
remain. Otherwise it starts a fresh main workspace. Super+Alt+Enter always
starts a separate fresh session. History updates reconcile all live sessions,
including ones opened through the built-in picker.
The desktop wrapper launches Foot explicitly with `~/.config/foot/foot.ini` and
the current terminal directory. Do not route it through generic terminal
selection: `xdg-terminal-exec` may select Alacritty and change the appearance.

The optional `zanken-cmd-zellij-session reset` command uses a transient `zanken-reset.*` bridge to keep the
same terminal client open while the session helper stops and deletes the old
session. Its `zanken-reset-return` pipe carries a temporary JSON session name and
home directory. Only a guide inside a reset bridge accepts this message and
switches its own client to the fresh `zanken` layout; normal session guides ignore
it. This reuses the guide's existing permissions. The bridge and its saved state
are then removed. The helper waits for attachment before stopping the old session
and waits for shutdown before deleting saved state. No runtime session names are
written into the configuration or layouts.

Vim aliases are navigation only. They do not substitute Enter or Escape, open
layouts, save, confirm, or close menus. Layout changes still require the native
explicit actions. A `compact` tab intentionally uses its built-in minimal bar;
opening that layout does not change the saved `zanken` default.

## Plugin Manager repair

The bundled manager listens to `SessionUpdate`, but this version's screen
thread broadcasts a current-session snapshot with an empty plugin map. This
leaves the plugin list empty even when plugins are running.

`plugin-manager.patch` applies to the official `v0.45.1` source. It queries
`get_session_list()` on a one-second timer while visible, and ignores incomplete
push snapshots. It never queries from `SessionUpdate` or `render`, since that
would create the event loop described in
[upstream issue 5602](https://github.com/zellij-org/zellij/issues/5602).

The included WASM files were built with Rust 1.95.0 and the upstream lockfile.
Rebuild all six with `bash build.sh`; Rust, curl, tar, and patch are required.
The original upstream source is MIT licensed; its license is included here.

Install the six WASM files under `~/.config/zellij/plugins/`. The session
mode's `p` binding launches that file directly, so an existing session can use
the repair without restarting. A first-use permission prompt requests the
state, launch, and messaging capabilities used by the manager.

These are local extensions, not an upstream release. After upgrading Zellij,
review all three patches against the new source, retest the menus, and remove the
Plugin Manager repair if the upstream bug is fixed.
