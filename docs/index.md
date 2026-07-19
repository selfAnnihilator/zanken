# Zanken

**Zanken** is a standalone Arch Linux desktop environment built around the [Niri](https://github.com/YaLTeR/niri) scrolling compositor and [Quickshell](https://quickshell.outfoxxed.me/).

## What it is

- **Compositor**: [Niri](https://github.com/YaLTeR/niri) — a scrolling tiling Wayland compositor
- **Bar**: [Quickshell](https://quickshell.outfoxxed.me/) — QML-based desktop shell with popups for audio, wifi, bluetooth, music, weather
- **Notifications**: [Mako](https://github.com/emersion/mako)
- **Terminal**: [Foot](https://codeberg.org/dnkl/foot)
- **Launcher**: OmniMenu — built-in Quickshell search (`Mod+Space`)
- **Scripts**: 280+ `zanken-*` shell scripts covering everything from theming to hardware detection
- **Themes**: 21 built-in color themes, dynamic wallpaper-based palette generation via zanken-wallpaper-colors

## What it is not

Zanken is not a distro. It is a dotfiles + script layer that runs on top of Arch Linux. It assumes you have already installed Arch.

## Quickstart

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/selfAnnihilator/zanken/main/boot.sh) --clean
```

See [Installation](installation.md) for full details.

## Structure

```
zanken/
├── bin/          # 280+ zanken-* scripts
├── config/       # Base app configs
├── default/      # Default app and managed desktop configs
├── themes/       # 21 built-in color themes
├── install/      # Install phase scripts
└── migrations/   # Version migration scripts
```
