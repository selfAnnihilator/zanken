# Zanken

**Zanken** is a Niri-based Linux workspace derived from [zanken](https://github.com/selfAnnihilator/zanken) by DHH. It replaces Hyprland with the [Niri](https://github.com/YaLTeR/niri) scrolling compositor and Waybar with [Quickshell](https://quickshell.outfoxxed.me/), while keeping zanken's 300+ script layer intact.

## What it is

- **Compositor**: [Niri](https://github.com/YaLTeR/niri) — a scrolling tiling Wayland compositor
- **Bar**: [Quickshell](https://quickshell.outfoxxed.me/) — QML-based desktop shell with popups for audio, wifi, bluetooth, music, weather
- **Notifications**: [Elephant](https://github.com/nickel-org/elephant)
- **Terminal**: [Foot](https://codeberg.org/dnkl/foot)
- **Launcher**: [Fuzzel](https://codeberg.org/dnkl/fuzzel)
- **Scripts**: 308 `zanken-*` shell scripts covering everything from theming to hardware detection
- **Themes**: 21 built-in color themes, dynamic wallpaper-based palette generation via matugen

## What it is not

Zanken is not a distro. It is a dotfiles + script layer that runs on top of Arch Linux. It assumes you have already installed Arch.

## Quickstart

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/selfAnnihilator/dotfiles/main/install.sh)
```

See [Installation](installation.md) for full details.

## Structure

```
zanken/
├── bin/          # 308 zanken-* scripts
├── config/       # Base configs (sourced by dotfiles)
├── default/      # Default app configs (foot, alacritty, waybar, etc.)
├── themes/       # 21 built-in color themes
├── install/      # Install phase scripts
└── migrations/   # Version migration scripts
```

## Differences from zanken

| Feature | zanken | zanken |
|---------|---------|--------|
| Compositor | Hyprland | Niri |
| Bar | Waybar | Quickshell |
| Notifications | Mako | Elephant |
| Focus model | Tiling (manual) | Scrolling columns |
| Config format | Hyprland DSL | KDL |
