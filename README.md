# Zanken

A Niri-based Linux workspace derived from [omarchy](https://omarchy.org).

Replaces Hyprland with the [Niri](https://github.com/YaLTeR/niri) scrolling compositor and Waybar with [Quickshell](https://quickshell.outfoxxed.me/), while keeping omarchy's 300+ script layer intact.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/selfAnnihilator/dotfiles/main/install.sh)
```

## What's included

- **[Niri](https://github.com/YaLTeR/niri)** — scrolling tiling Wayland compositor
- **[Quickshell](https://quickshell.outfoxxed.me/)** — QML bar with audio, wifi, bluetooth, music, weather popups
- **308 scripts** — `omarchy-*` commands for everything from themes to hardware detection
- **21 built-in themes** — tokyo-night, catppuccin, kanagawa, gruvbox, nord, and more
- **Dynamic wallpaper colors** — palette extracted from wallpaper via matugen

## Documentation

**[selfAnnihilator.github.io/zanken](https://selfAnnihilator.github.io/zanken)**

- [Installation](https://selfAnnihilator.github.io/zanken/installation)
- [Keybinds](https://selfAnnihilator.github.io/zanken/keybinds)
- [Themes](https://selfAnnihilator.github.io/zanken/themes)
- [Commands](https://selfAnnihilator.github.io/zanken/commands)
- [Configuration](https://selfAnnihilator.github.io/zanken/configuration)

## Quick reference

```bash
omarchy-theme-set tokyo-night    # switch theme
omarchy-theme-bg-set wall.jpg    # set wallpaper + extract palette
omarchy-audio-input-mute         # toggle microphone
omarchy-capture-screenshot       # take screenshot
omarchy-default-terminal kitty   # change default terminal
```

## Structure

```
zanken/
├── bin/          # 308 omarchy-* scripts (on $PATH)
├── config/       # Base configs
├── default/      # Default app configs
├── themes/       # 21 built-in color themes
├── install/      # Install phase scripts
└── migrations/   # Version migration scripts
```

## Differences from omarchy

| Feature | omarchy | zanken |
|---------|---------|--------|
| Compositor | Hyprland | Niri |
| Bar | Waybar | Quickshell |
| Notifications | Mako | Elephant |
| Focus model | Tiling (manual) | Scrolling columns |
| Config format | Hyprland DSL | KDL |

## License

[MIT](LICENSE)
