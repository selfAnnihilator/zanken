# Themes

Zanken includes 21 built-in color themes. Themes update the terminal, bar colors, wallpaper palette, and supported app configurations.

## Built-in themes

| Theme | Style |
|-------|-------|
| `catppuccin` | Pastel dark (Mocha) |
| `catppuccin-latte` | Pastel light |
| `ethereal` | Soft purple |
| `everforest` | Green earth tones |
| `flexoki-light` | Warm light ink |
| `gruvbox` | Retro amber/brown |
| `hackerman` | Green-on-black terminal |
| `kanagawa` | Japanese ink (dark) |
| `last-horizon` | Dark sci-fi blue |
| `lumon` | Clean corporate white |
| `matte-black` | Pure dark minimal |
| `miasma` | Muted dark greens |
| `nord` | Arctic blue-grey |
| `osaka-jade` | Dark teal/jade |
| `retro-82` | CRT amber nostalgia |
| `ristretto` | Espresso browns |
| `rose-pine` | Muted rose/pine |
| `solitude` | Cool grey-blue |
| `tokyo-night` | Dark blue/purple |
| `vantablack` | Maximum contrast dark |
| `white` | Pure white light |

## Switching themes

```bash
zanken-theme-set tokyo-night
```

Or use the Quickshell palette: `Mod+D` → search "theme".

## Dynamic wallpaper colors

`zanken-wallpaper-colors` extracts an accent with ImageMagick. Setting a wallpaper
applies the accent to Niri, GTK and Quickshell.

```bash
zanken-theme-bg-set ~/Pictures/my-wallpaper.jpg
```

## Creating a custom theme

```bash
mkdir -p ~/.config/zanken/themes
```

Copy an existing theme as a base:
```bash
cp -r ~/.local/share/zanken/current-release/source/themes/tokyo-night ~/.config/zanken/themes/my-theme
```

Edit `~/.config/zanken/themes/my-theme/colors.toml`:
```toml
accent = "#your-color"
foreground = "#your-fg"
background = "#your-bg"
# ... etc
```

Then apply:
```bash
zanken-theme-set my-theme
```

## Theme hooks

Run custom scripts after a theme change:

```bash
mkdir -p ~/.config/zanken/hooks/theme-set.d
cat > ~/.config/zanken/hooks/theme-set.d/my-app << 'EOF'
#!/bin/bash
my-app --reload-theme
EOF
chmod +x ~/.config/zanken/hooks/theme-set.d/my-app
```
