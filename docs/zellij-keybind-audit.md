# Zellij keybinding audit — 2026-10-21

The local Zellij 0.45.1 configuration was exercised through real terminal input
in private sessions. Checks assert resulting files, pane geometry, focus, session
connections, editor behavior, rendered search highlights, and server/token state.
Opening a popup alone is not counted as verifying its controls.

## Repairs installed

- Actions and popups return to `locked`, the configured application-input mode.
  In this setup, `normal` is the command/guide mode and drops unbound input.
- Alt+P and Alt+Shift+P also return to `locked`. This fixes the intercepted letter
  keys and Escape in the grouped-pane menu. Grouping is available while locked.
- Session-mode `p` launches a locally repaired Plugin Manager. The bundled
  manager received empty plugin maps from screen updates, so its list stayed
  empty. The repair queries the complete metadata once per second while visible.
  Its source patch, binary, license, and rebuild instructions are in
  `config/zellij/plugins/`. It avoids querying from an event that the query itself
  broadcasts; see [upstream issue 5602](https://github.com/zellij-org/zellij/issues/5602).
- The active configuration and repaired binary match the repository copies.
  A live screenshot was inspected, all original main-session terminal panes were
  preserved, and the prior Layout Manager and desktop focus were restored.

## Verified coverage

| Area | Actions exercised |
| --- | --- |
| Application input | Typed command after native split; Enter/Escape from all six guide modes |
| Panes | Direct and native splits, close, directional focus, rotate/move aliases, rename accept/cancel, frames, fullscreen with/without UI, float/embed, pin and visibility |
| Tabs | Create/close, tabs 1–9 through native and direct keys, directional aliases, tab movement, rename accept/cancel, break pane into new/left/right tab, prefix equivalents |
| Resize | Directional h/j/k/l and arrows, decreasing uppercase keys, +/=/−, direct modified-arrow shortcuts |
| Scroll/search | Line/page/half-page aliases, query editing, entry cancel, actual case/whole-word highlight changes, wrapping in both directions, return to application input |
| Shell integration | OSC 133 previous/next prompt, command selection, command-output copy to a private clipboard, scrollback editor opening/input/closing |
| Session helpers | Prefix C/R/P/N/K, Alt+Up/Down, help pager and exit, prefix/native detach, native quit |
| Grouped panes | Escape cancel, Tab relocation, stack, float, embed, break out/left/right, close selected panes |
| Layout Manager | Navigation, search/completion/Backspace, options, actual edit/rename/delete/save/import, open layout as a tab, apply layout to the test session |
| Session Manager | Search/completion, switching, rename/cancel, layout/directory selection/reset, creation in the chosen directory, save/resurrect, live/exited deletion, kill-all confirm/cancel, disconnect another client |
| Configuration | Key capture/cancel/reset, all secondary modifiers, rebind apply/save distinction, both presets with session-only apply and disk save, actual resulting shortcut/input behavior |
| About | All seven detail pages, twelve tips, tip opt-out saved to config, missing-keybinding update/cancel/confirm |
| Plugin Manager | Search/editing, expand/collapse, focus, actual reload/reset, close, configuration pair add/edit/delete, form cancel, disk picker, real plugin load, background load without focus |
| File picker | Search/Backspace, hidden-file toggle, Up/Down, Right/Tab/Enter traversal, parent navigation, selection returned to caller, Escape/Ctrl+C search clearing |
| Sharing | Private localhost server start/stop, share/unshare, token generation, named read/write and read-only tokens, navigation, rename/cancel, revoke selected/all |

Sharing checks used separate authentication/cache/runtime directories and a
random localhost port. They did not enable sharing in the main session. Token
values were not logged.

## Nonconflicting Vim menu navigation — 2026-10-22

The user chose Vim aliases only where the letters are free, and clarified that
h/l must remain pure horizontal navigation: never Enter/Escape, open/back,
confirmation, or layout application. Local About, Configuration, Layout Manager,
and Share WASMs preserve that rule, immediate search, and literal text entry.
Session Manager, Plugin Manager, and Strider retain letter-to-search keys.
Normal-mode h/j/k/l move pane focus; locked-mode letters reach applications.
Session-mode h/l also move focus; v explicitly opens Layout Manager, replacing
the former l opener. The guide lists both movement and the v tool shortcut.

A local status-bar extension preserves the two-line layout and restores the
missing action hints. It recognizes trailing SwitchToMode Locked as well as
Normal for hints and lists all six Session tools using configured aliases,
built-in URLs, or local WASM paths. Both one- and two-line menu lookups are covered.

The new `zanken-zellij-vim-menu-test.py` suite verifies real selection changes,
About detail/tip navigation, shortcut capture, presets, layout creation/opening,
token navigation and names, and unchanged search/URL input in the other menus.
Layout Manager h/l are also checked to leave the tab/layout unchanged; only
explicit Enter opens a selected layout as a new tab.
The existing Configuration, About, Sharing, and Layout Manager workflows were
rerun against the local menus, including actual apply/save, edit/import/delete,
server start/stop and token revocation. Sharing tests use private state and do
not log token values. The patches apply cleanly to the pinned upstream source,
and the six WASMs have a shared rebuild script in `config/zellij/plugins/`.

A custom Share plugin must defer synchronous token queries until its permission
grant; doing them during load can panic when access is denied. The local build
handles this first-use path and preserves the original token controls.

## Limits and expected behavior

- In the bundled file picker, Ctrl+C clears the search state but does not request
  an immediate redraw. The next key redraws it; Escape clears it immediately.
  This is an upstream display quirk, documented in the key reference.
- Host/guest focus and host fullscreen need a nested-session context. Those
  bindings were source reviewed, rather than runtime tested with a guest.
- Swap-layout actions require a layout with swap definitions. The minimal
  `zanken` layout does not provide them. Boundary navigation/resize and actions
  without the required context may legitimately do nothing.
- Tests cover the listed workflows, not every possible combination of plugin
  configuration, application, terminal emulator, remote host, or mouse gesture.
  Actual machine reboot recovery was not tested; saving and resurrecting an
  exited private session was tested.

## Repeatable checks

Run from the repository with Zellij, Fish, Neovim, gum, and a working local
control-socket environment. The native rendered-search check also needs
`pyte==0.8.2` from `test/requirements-zellij.txt`.

```bash
python3 test/zanken-zellij-input-test.py
python3 test/zanken-zellij-deep-test.py
python3 test/zanken-zellij-native-test.py
python3 test/zanken-zellij-vim-menu-test.py
```

The deep suite supports `--group`; the native suite accepts group names such as
`search`, `groups`, `helpers`, and `scroll_commands` to investigate one area.
Evidence defaults to `/tmp/zanken-zellij-deep-audit/results/`. Each case records
its passed assertions. Failed fixtures are retained for diagnosis; those files
are not themselves evidence of success.

All test sockets, layouts, configuration, cache, and data are private. Explicit
`layout_dir` is required: changing only XDG paths or `--config-dir` does not isolate
all runtime layout operations. Directory-creation tests use a temporary host
folder under `test/`, since `/tmp` is translated as a special plugin mount.
Successful fixtures and their private sessions are removed automatically.
