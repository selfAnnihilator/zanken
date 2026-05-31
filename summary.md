# Zanken Project — Session Summary

**Period:** May 29–31, 2026 · 28 commits

Zanken is a personal Niri/Wayland dotfiles system forked from Omarchy and fully rebased for a custom aesthetic and tooling setup.

---

## 1. Foundation & Rebrand

- **Forked from Omarchy** — removed all upstream ties, renamed every `omarchy` reference to `zanken` throughout bin scripts, configs, and comments
- **Removed unused scripts** — cleaned up inherited Omarchy tooling that had no zanken equivalent
- **Gitignore** — wallpapers excluded from tracking; moved to `~/Pictures/wallpaper/` with symlink convention
- **ZANKEN_PATH fallback** — fixed stale env var references across all bin scripts so they resolve correctly regardless of shell init order

---

## 2. Wallpaper System

### Normal & Video Wallpapers
- **Walker picker** — fixed socket name so image selector opens correctly on Niri
- **Lazy thumbnails** (`--lazy-thumbnails`) — picker opens immediately, loads thumbs in background
- **Video wallpaper support** (phase 1) — `mpvpaper` backend, `~/Videos/wallpaper/` convention
- **Video accent extraction** — `ffmpeg` grabs a frame at 3s, `zanken-wallpaper-colors` extracts dominant color, applies to theme
- **Unified tabbed picker** — single QML window with Images and Videos tabs (previously two separate pickers)

### Steam Wallpaper Engine Integration
- **`zanken-theme-we-set`** — new script to apply Wallpaper Engine scene wallpapers via `linux-wallpaperengine`
- **Auto-detect Steam path** — parses `libraryfolders.vdf` to find the WE workshop directory automatically; no hardcoded paths
- **WE scaling fix** — switched to `--bg <id> --scaling fill --clamp border` to prevent stretching/cropping
- **WE audio flag fix** — removed nonexistent `--audio-device` flag that prevented startup
- **Preview-based accent** — extracts wallpaper accent color from `preview.jpg` and applies to theme

---

## 3. Visual / Theme System

### GTK4 Transparency
- Overrode `:root` CSS custom properties to kill Adwaita's default background
- Killed shade overlays; added `!important` on background rules to prevent libadwaita override
- Added `:focus` and `:focus-within` selectors to suppress accent tint on focused windows
- Added themed CSS template for file manager (Nautilus) transparency

### Quickshell Bar & Popups
- **Zanken icon** — redesigned from scratch as block pixel art spelling the full word `ZANKEN`
- **CJK font** — added CJK serif font to workspace bar for correct Japanese/Chinese glyph rendering
- **Popup card borders** — all bar popup cards (WiFi, Bluetooth, Audio, Battery, etc.) now use the wallpaper-derived `seal` accent color at 45% opacity, matching the music pill and window borders *(live config — `~/.config/quickshell/desktop/CardWindow.qml`)*

### Terminal & Audio OSD
- **Foot terminal** — fixed `omarchy→zanken` include path and font name in config
- **SwayOSD style** — updated import path from omarchy theme dir to zanken theme dir

---

## 4. System / Daemon Fixes

### SwayOSD Keybinds (audio, brightness, mic mute, media)
**Problem:** keybinds broke on session start. Root causes:
1. `swayosd-server` launched twice — both `spawn-at-startup "swayosd-server"` in niri config AND the systemd service. GTK GApplication single-instance conflict caused the systemd unit to crash-loop.
2. Service started before niri ran `systemctl --user import-environment WAYLAND_DISPLAY`, inheriting a stale `WAYLAND_DISPLAY=wayland-2` from a previous session (actual socket is `wayland-1`).

**Fix:**
- Removed `spawn-at-startup "swayosd-server"` from `~/.config/niri/config.kdl` — systemd is the sole manager
- Added `ExecStartPre=/bin/sleep 3` to the service so the `import-environment` step runs before GTK initializes
- Changed `Restart=always` → `Restart=on-failure` to prevent aggressive crash looping
- Migration `1780164860.sh` applies both changes to existing installs

---

## 5. Migrations Added

| Migration | Change |
|-----------|--------|
| (initial install) `install/first-run/swayosd.sh` | Enable swayosd systemd service |
| `1780164860.sh` | Fix swayosd duplicate launch + service startup delay |

---

## Files Changed (live, not in zanken git)

| File | Change |
|------|--------|
| `~/.config/niri/config.kdl` | Removed `spawn-at-startup "swayosd-server"` |
| `~/.config/quickshell/desktop/CardWindow.qml` | Popup border color → `seal` accent |
