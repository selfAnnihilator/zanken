# Themes

Zanken includes 21 built-in color themes. Themes update the terminal, bar colors, wallpaper palette, and all themed app configs atomically.

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
omarchy-theme-set tokyo-night
```

Or use the Quickshell palette: `Mod+D` → search "theme".

## Dynamic wallpaper colors

Zanken supports extracting a color palette from the current wallpaper using [matugen](https://github.com/InioX/matugen). When a wallpaper is set, the bar accent colors, foot terminal, and qutebrowser all update to match.

```bash
omarchy-theme-bg-set ~/Pictures/my-wallpaper.jpg
```

## Creating a custom theme

```bash
mkdir -p ~/zanken/themes/my-theme
```

Copy an existing theme as a base:
```bash
cp -r ~/zanken/themes/tokyo-night ~/zanken/themes/my-theme
```

Edit `colors.toml`:
```toml
accent = "#your-color"
foreground = "#your-fg"
background = "#your-bg"
# ... etc
```

Then apply:
```bash
omarchy-theme-set my-theme
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
