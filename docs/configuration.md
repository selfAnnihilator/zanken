# Configuration

## File locations

| Config | Path |
|--------|------|
| Niri compositor | `~/.config/niri/config.kdl` |
| Quickshell bar | `~/.config/quickshell/desktop/` |
| Foot terminal | `~/.config/foot/foot.ini` |
| Fish shell | `~/.config/fish/config.fish` |
| Qutebrowser | `~/.config/qutebrowser/config.py` |
| Zanken scripts | `~/zanken/bin/` |
| User scripts | `~/.config/zanken/bin/` |
| Current theme | `~/.config/zanken/current/` |

## PATH architecture

Scripts are resolved in this order:

1. `~/.config/zanken/bin/` — your personal overrides (highest priority)
2. `~/zanken/bin/` — base zanken scripts (308 scripts)
3. `~/.local/share/omarchy/bin/` — install cache (fallback)

Add personal scripts or override base scripts by placing them in `~/.config/zanken/bin/`.

## Zanken current directory

`~/.config/zanken/current/` holds symlinks to the active theme:

```
current/
├── theme/          # Active theme directory (colors.toml, foot.ini, etc.)
├── background      # Path to current wallpaper
└── mono-font       # Active monospace font name
```

These are updated automatically when you run `omarchy-theme-set <theme>`.

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

The Niri config is at `~/.config/niri/config.kdl`. Key sections:

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

The bar source is at `~/.config/quickshell/desktop/`. Key files:

| File | Purpose |
|------|---------|
| `Navbar.qml` | Main bar layout, all popup state |
| `Theme.qml` | Color bindings from `~/.config/zanken/current/theme/colors.toml` |
| `MusicPopup.qml` | Music player with Cava visualizer |
| `SystemPopup.qml` | CPU/RAM/disk stats |

Restart the bar after edits:
```bash
omarchy-restart-quickshell
```
