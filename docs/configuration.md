# Configuration

## File locations

| Config | Path |
|--------|------|
| Niri entry point | `~/.config/niri/config.kdl` |
| Niri local override | `~/.config/zanken/niri.kdl` |
| Quickshell bar | `~/.config/quickshell/zanken/` |
| Managed desktop defaults | `~/.local/share/zanken/desktop/` |
| Local settings | `~/.config/zanken/settings.json` |
| Foot terminal | `~/.config/foot/foot.ini` |
| Fish shell | `~/.config/fish/config.fish` |
| Zellij workspace | `~/.config/zellij/config.kdl` and `~/.config/zellij/layouts/zanken.kdl` |
| Qutebrowser | `~/.config/qutebrowser/config.py` |
| Zanken scripts | `~/.local/share/zanken/current-release/source/bin/` after adoption |
| User scripts | `~/.config/zanken/bin/` |
| Current theme | `~/.config/zanken/current/` |

Zanken owns the portable Niri and Quickshell defaults. Release activation moves
matching commands and desktop configuration together; `~/.local/share/zanken/desktop`
points into the active generation. Local settings and the Niri override stay
outside that directory. See the [release model](releases.md) for adoption and rollback.

## PATH architecture

Scripts are resolved in this order:

1. `~/.config/zanken/bin/` — your personal overrides (highest priority)
2. `~/.local/share/zanken/current-release/source/bin/` — active release commands
3. `~/zanken/bin/` — development checkout or an installation not yet adopted

Add personal scripts or override base scripts by placing them in `~/.config/zanken/bin/`.
Normal `zanken` invocations follow the active generation. Developers can explicitly
inspect source CLI behavior with `ZANKEN_SOURCE_MODE=1`.

## Zanken current directory

`~/.config/zanken/current/` holds symlinks to the active theme:

```
current/
├── theme/          # Active theme directory (colors.toml, foot.ini, etc.)
├── background      # Path to current wallpaper
└── mono-font       # Active monospace font name
```

These are updated automatically when you run `zanken-theme-set <theme>`.

## Terminal workspace

`Super+Enter` resumes or focuses the most recent Zellij workspace in Foot.
`Super+Alt+Enter` creates a separate session; `Super+T` opens plain Foot.
`Super+S` opens the searchable session picker.

See [Zellij workflow and keybinds](zellij.md) for panes, tabs, sessions,
scrollback, detaching and reboot recovery. The installed reference is also
available with `Ctrl+Space`, release, then `?`.

## Weather location

```bash
# Set your city or coordinates
mkdir -p ~/.config/zanken/weather
echo "Oslo" > ~/.config/zanken/weather/location
# or: echo "59.9139,10.7522" > ~/.config/zanken/weather/location
```

The Quickshell bar reads this file for the weather popup. Leave empty to use IP geolocation.

## Hooks

Zanken supports hooks that run at specific lifecycle events:

```bash
# Location: ~/.config/zanken/hooks/<event>.d/<script>
# Examples: theme-set, font-set, post-update
```

Example — run a script after every theme change:
```bash
mkdir -p ~/.config/zanken/hooks/theme-set.d
cat > ~/.config/zanken/hooks/theme-set.d/my-hook << 'EOF'
#!/bin/bash
# Refresh my custom app colors
my-app --reload-colors
EOF
chmod +x ~/.config/zanken/hooks/theme-set.d/my-hook
```

## Niri config

`~/.config/niri/config.kdl` is a small Zanken-managed entry point. It includes
the base configuration and then the optional `~/.config/zanken/niri.kdl` local
override. Put monitor rules, extra bindings, and other machine-specific Niri
changes in that override file.

Key base sections include:

```kdl
// Gaps between windows
layout {
    gaps 10
    struts { left 8; right 8; top 8; bottom 8; }
}

// Focus ring color (updates with theme)
focus-ring {
    width 2
    active-color "#396385"
}
```

Full reference: [Niri configuration docs](https://github.com/YaLTeR/niri/wiki/Configuration)

## Quickshell bar

The managed bar is named `zanken`, so it can coexist with other Quickshell
configs. Its source is at `~/.local/share/zanken/desktop/quickshell/`, exposed
through `~/.config/quickshell/zanken/`. Use `settings.json` for supported local
preferences rather than editing managed QML files.

| File | Purpose |
|------|---------|
| `Navbar.qml` | Main bar layout, all popup state |
| `Theme.qml` | Color bindings from `~/.config/zanken/current/theme/colors.toml` |
| `MusicPopup.qml` | Music player with Cava visualizer |
| `SystemPopup.qml` | CPU/RAM/disk stats |

Restart the bar after edits:
```bash
zanken-restart-quickshell
```

## Wi-Fi card

The Wi-Fi card follows NetworkManager changes while it is open. Connecting,
disconnecting and radio changes update the connected row without reopening it.
Cached signal and connection details refresh every three seconds; nearby
discovery scans run every fifteen seconds while the card is open. The refresh
button requests an additional scan.

Saved networks use their actual SSIDs, even when their connection profiles have
been renamed. The card tracks Wi-Fi independently of a wired or USB uplink.

Run the isolated regression check without changing real network connections:

```bash
dbus-run-session -- python3 test/check_wifi_live.py
```

## Hardware power-mode keys

Some laptops change their firmware mode with Fn+Q while `powerprofilesctl get`
continues to report the previous profile. The optional
`zanken-powerprofiles-sync.service` follows firmware changes and updates the power
service, including its CPU policy and the battery panel. It preserves manual
panel selections and leaves custom firmware profiles alone.

The desktop installer enables this service when supported firmware and an active
power-profiles-daemon are present and no conflicting power manager is detected.
The unit runs the helper from the active release, so it does not require a
checkout at `~/zanken`. Inspect it with:

```bash
systemctl --user status zanken-powerprofiles-sync.service
```

It requires Python 3, `powerprofilesctl`, and
`/sys/firmware/acpi/platform_profile`. Disable it with
`systemctl --user disable --now zanken-powerprofiles-sync.service`.
The portable installer does not install charger-triggered profile switching.

## Notifications

Quickshell owns the Zanken notification server. The notification panel keeps
the sender's capabilities intact:

* Click a notification with a default action to open its originating message,
  video, or application.
* Sender-provided buttons, including media controls, appear beneath that
  notification only when they are supported.
* Reply-capable notifications, such as KDE Connect messages, show an inline
  reply field. Press Enter or select **SEND** to reply.
* Completing an action or reply dismisses that notification. Notifications
  without an action remain readable and manually dismissible.

Notifications restored from a previous shell session are intentionally
display-only because their originating sender action is no longer available.

## Optional VPN status on the network icon

Configure `~/.config/zanken/vpn-status.json` to attach a local VPN controller:

```json
{
  "statusCommand": ["/absolute/path/controller", "--bar-status"],
  "verifyCommand": ["/absolute/path/controller", "--status-json"],
  "openCommand": ["/absolute/path/controller"]
}
```

Commands are argv arrays. The status command returns JSON containing `state`
and optional `uplink_kind` (`wifi`, `eth`, `usb`, `none`). Supported states are
`connected`, `disconnected`, `paused`, `checking`, `unverified`, `unprotected`,
and `unavailable`. The controller must report `connected` only after verifying
its protection. Status runs every two seconds; an optional separate verifier
runs every twenty seconds and should update the controller's proof cache.

A green lock marks verified protection, a pause badge marks blocked internet,
and a warning marks uncertain or incomplete protection. Stale/failed local
status removes the lock. Hover for status; right-click to open VPN controls.
Left-click still opens the network menu. Missing configuration disables this
integration. Keep provider output free of credentials and unnecessary addresses.

The background-apps dropdown includes a VPN entry while its monitor is active.
Left-click opens controls. To support its right-click **Close completely** action,
add `closeCommand` (an argv array) and `backgroundStatePath` (an absolute path to a
controller-owned session JSON file). The close command should stop the VPN and
its guard, restore ordinary internet, and close its controls before atomically
writing `{"closed": true}`. The bar then hides the entry and stops its status and
verification processes and timers. Opening the controller should write
`{"closed": false}` to resume monitoring; it can leave connecting to the user.
On cleanup failure, leave the closed marker unset so recovery remains accessible.
