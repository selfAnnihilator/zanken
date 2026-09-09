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

## Weather location

```bash
# Set your city or coordinates
echo "Oslo" > ~/.config/zanken/weather/location
# or: echo "59.9139,10.7522" > ~/.config/zanken/weather/location
```

The Quickshell bar reads this file for the weather popup. Leave empty to use IP geolocation.

## Hooks

Zanken supports hooks that run at specific lifecycle events:

```bash
# Location: ~/.config/zanken/hooks/<event>.d/<script>
# Events: theme-set, post-boot, pre-shutdown
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
