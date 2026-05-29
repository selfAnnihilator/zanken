---
name: zanken
description: >
  REQUIRED for end-user customization of Linux desktop, window manager, or system config.
  Use when editing ~/.config/hypr/, ~/.config/waybar/, ~/.config/walker/,
  ~/.config/alacritty/, ~/.config/foot/, ~/.config/kitty/, ~/.config/ghostty/, ~/.config/mako/,
  or ~/.config/zanken/. Triggers: Hyprland, window rules, animations, keybindings,
  monitors, gaps, borders, blur, opacity, waybar, walker, terminal config, themes,
  background, night light, idle, lock screen, screenshots, reminders, layer rules,
  workspace settings, display config, and user-facing zanken commands. Excludes Zanken
  source development in ~/.local/share/zanken/ and `zanken dev` workflows.
---

# Zanken Skill

Manage [Zanken](https://zanken.org/) Linux systems - a beautiful, modern, opinionated Arch Linux distribution with Hyprland.

This skill is for end-user customization on installed systems.
It is not for contributing to Zanken source code.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for end-user requests involving ANY of these:**

- Editing ANY file in `~/.config/hypr/` (window rules, animations, keybindings, monitors, etc.)
- Editing ANY file in `~/.config/waybar/`, `~/.config/walker/`, `~/.config/mako/`
- Editing terminal configs (alacritty, foot, kitty, ghostty)
- Editing ANY file in `~/.config/zanken/`
- Window behavior, animations, opacity, blur, gaps, borders
- Layer rules, workspace settings, display/monitor configuration
- Themes, backgrounds, fonts, appearance changes
- User-facing `zanken` commands (`zanken theme ...`, `zanken refresh ...`, `zanken restart ...`, etc.)
- Screenshots, screen recording, reminders, night light, idle behavior, lock screen

**If you're about to edit a config file in ~/.config/ on this system, STOP and use this skill first.**

**Do NOT use this skill for Zanken development tasks** (editing files in `~/.local/share/zanken/`, creating migrations, or running `zanken dev ...` workflows).

## Critical Safety Rules

**For end-user customization tasks, NEVER modify anything in `~/.local/share/zanken/`** - but READING is safe and encouraged.

This directory contains Zanken's source files managed by git. Any changes will be:
- Lost on next `zanken update`
- Cause conflicts with upstream
- Break the system's update mechanism

```
~/.local/share/zanken/     # READ-ONLY - NEVER EDIT (reading is OK)
├── bin/                    # Source scripts (symlinked to PATH)
├── config/                 # Default config templates
├── themes/                 # Stock themes
├── default/                # System defaults
├── migrations/             # Update migrations
└── install/                # Installation scripts
```

**Reading `~/.local/share/zanken/` is SAFE and useful** - do it freely to:
- Understand how zanken commands work: `zanken theme set --help` or `cat $(which zanken-theme-set)`
- See default configs before customizing: `cat ~/.local/share/zanken/config/waybar/config.jsonc`
- Check stock theme files to copy for customization
- Reference default hyprland settings: `cat ~/.local/share/zanken/default/hypr/*`

**Always use these safe locations instead:**
- `~/.config/` - User configuration (safe to edit)
- `~/.config/zanken/themes/<custom-name>/` - Custom themes (must be real directories)
- `~/.config/zanken/hooks/` - Custom automation hooks

If the request is to develop Zanken itself, this skill is out of scope. Follow repository development instructions instead of this skill.

## System Architecture

Zanken is built on:

| Component | Purpose | Config Location |
|-----------|---------|-----------------|
| **Arch Linux** | Base OS | `/etc/`, `~/.config/` |
| **Hyprland** | Wayland compositor/WM | `~/.config/hypr/` |
| **Waybar** | Status bar | `~/.config/waybar/` |
| **Walker** | App launcher | `~/.config/walker/` |
| **Alacritty/Foot/Kitty/Ghostty** | Terminals | `~/.config/<terminal>/` |
| **Mako** | Notifications | `~/.config/mako/` |
| **SwayOSD** | On-screen display | `~/.config/swayosd/` |

## Command Discovery

Zanken ships a single `zanken` CLI that dispatches to all `zanken-*` binaries via `zanken <group> <action>`. Always prefer this form — it is self-documenting and stable. The underlying `zanken-*` binaries still exist on `PATH` and remain safe to read for source.

```bash
# List every documented command and its summary
zanken commands

# Show the commands inside a group
zanken theme --help
zanken refresh --help
zanken restart --help

# Show help for a specific command (does not execute it)
zanken theme set --help

# Machine-readable listing (binary, route, summary, args, aliases)
zanken commands --json

# Read a command's source to understand it
cat $(which zanken-theme-set)
```

### Command Groups

Run `zanken --help` for the full list. The most common groups:

| Group | Purpose | Example |
|-------|---------|---------|
| `zanken refresh` | Reset config to defaults (backs up first) | `zanken refresh waybar` |
| `zanken restart` | Restart a service/app | `zanken restart waybar` |
| `zanken toggle` | Toggle feature on/off | `zanken toggle nightlight` |
| `zanken theme` | Theme management | `zanken theme set <name>` |
| `zanken install` | Install optional software / packages | `zanken install docker dbs` |
| `zanken launch` | Launch apps | `zanken launch browser` |
| `zanken capture` | Screenshots and recordings | `zanken capture screenshot` |
| `zanken reminder` | Desktop notification reminders | `zanken reminder 15 "Pickup Jack"` |
| `zanken pkg` | Package management | `zanken pkg install <pkg>` |
| `zanken setup` | Initial setup tasks | `zanken setup fingerprint` |
| `zanken update` | System updates | `zanken update` |

## Configuration Locations

### Hyprland (Window Manager)

```
~/.config/hypr/
├── hyprland.conf      # Main config (sources others)
├── bindings.conf      # Keybindings
├── monitors.conf      # Display configuration
├── input.conf         # Keyboard/mouse settings
├── looknfeel.conf     # Appearance (gaps, borders, animations)
├── envs.conf          # Environment variables
├── autostart.conf     # Startup applications
├── hypridle.conf      # Idle behavior (screen off, lock, suspend)
├── hyprlock.conf      # Lock screen appearance
└── hyprsunset.conf    # Night light / blue light filter
```

**Key behaviors:**
- Hyprland auto-reloads on config save (no restart needed for most changes)
- Use `hyprctl reload` to force reload
- After ANY Hyprland config change, validate with `hyprctl reload` followed by `hyprctl configerrors`
- If `hyprctl configerrors` reports errors, address them and rerun validation until clean or until a real blocker is identified
- Use `zanken refresh hyprland` to reset to defaults

### Waybar (Status Bar)

```
~/.config/waybar/
├── config.jsonc       # Bar layout and modules (JSONC format)
└── style.css          # Styling
```

**Waybar does NOT auto-reload.** You MUST run `zanken restart waybar` after any config changes.

**Commands:** `zanken restart waybar`, `zanken refresh waybar`, `zanken toggle waybar`

### Terminals

```
~/.config/alacritty/alacritty.toml
~/.config/foot/foot.ini
~/.config/kitty/kitty.conf
~/.config/ghostty/config
```

**Command:** `zanken restart terminal`

### Other Configs

| App | Location |
|-----|----------|
| btop | `~/.config/btop/btop.conf` |
| fastfetch | `~/.config/fastfetch/config.jsonc` |
| lazygit | `~/.config/lazygit/config.yml` |
| starship | `~/.config/starship.toml` |
| git | `~/.config/git/config` |
| walker | `~/.config/walker/config.toml` |

## Safe Customization Patterns

### Pattern 1: Edit User Config Directly

For simple changes, edit files in `~/.config/`:

```bash
# 1. Read current config
cat ~/.config/hypr/bindings.conf

# 2. Backup before changes
cp ~/.config/hypr/bindings.conf ~/.config/hypr/bindings.conf.bak.$(date +%s)

# 3. Make changes with Edit tool

# 4. Apply changes
# - Hyprland: auto-reloads on save, but MUST validate with `hyprctl reload` and `hyprctl configerrors`
# - Waybar: MUST restart with `zanken restart waybar`
# - Walker: MUST restart with `zanken restart walker`
# - Terminals: MUST restart with `zanken restart terminal`
```

### Pattern 2: Make a new theme

1. Create a directory under ~/.config/zanken/themes.
2. See how an existing theme is done via ~/.local/share/zanken/themes/catppuccin.
3. Download a matching background (or several) from the internet and put them in ~/.config/zanken/themes/[name-of-new-theme]
4. When done with the theme, run `zanken theme set "Name of new theme"`

### Pattern 3: Use Hooks for Automation

Create scripts in `~/.config/zanken/hooks/` to run automatically on events:

```bash
# Available hooks (see samples in ~/.config/zanken/hooks/):
~/.config/zanken/hooks/
├── theme-set        # Runs after theme change (receives theme name as $1)
├── font-set         # Runs after font change
└── post-update      # Runs after `zanken update`
```

Example hook (`~/.config/zanken/hooks/theme-set`):
```bash
#!/bin/bash
THEME_NAME=$1
echo "Theme changed to: $THEME_NAME"
# Add custom actions here
```

### Pattern 4: Reset to Defaults -- ALWAYS SEEK USER CONFIRMATION BEFORE RUNNING

When customizations go wrong:

```bash
# Reset specific config (creates backup automatically)
zanken refresh waybar
zanken refresh hyprland

# The refresh command:
# 1. Backs up current config with timestamp
# 2. Copies default from ~/.local/share/zanken/config/
# 3. Restarts the component
```

## Common Tasks

### Themes

```bash
zanken theme list              # Show available themes
zanken theme current           # Show current theme
zanken theme set <name>        # Apply theme (use "Tokyo Night" not "tokyo-night")
zanken theme bg next           # Cycle background
zanken theme install <url>     # Install from git repo
```

### Keybindings

Edit `~/.config/hypr/bindings.conf`. Format:
```
bind = SUPER, Return, exec, xdg-terminal-exec
bind = SUPER, Q, killactive
bind = SUPER SHIFT, E, exit
```

View current bindings: `zanken menu keybindings --print`

**IMPORTANT: When re-binding an existing key:**

1. First check existing bindings: `zanken menu keybindings --print`
2. If the key is already bound, you MUST add an `unbind` directive BEFORE your new `bind`
3. Inform the user what the key was previously bound to

Example - rebinding SUPER+F (which is bound to fullscreen by default):
```
# Unbind existing SUPER+F (was: fullscreen)
unbind = SUPER, F
# New binding for file manager
bind = SUPER, F, exec, nautilus
```

Always tell the user: "Note: SUPER+F was previously bound to fullscreen. I've added an unbind directive to override it."

### Display/Monitors

Edit `~/.config/hypr/monitors.conf`. Format:
```
monitor = eDP-1, 1920x1080@60, 0x0, 1
monitor = HDMI-A-1, 2560x1440@144, 1920x0, 1
```

List monitors: `hyprctl monitors`

### Window Rules

**CRITICAL: Hyprland window rules syntax changes frequently between versions.**

Before writing ANY window rules, you MUST fetch the current documentation from the official Hyprland wiki:
- https://github.com/hyprwm/hyprland-wiki/blob/main/content/Configuring/Window-Rules.md

DO NOT rely on cached or memorized window rule syntax. The format has changed multiple times and using outdated syntax will cause errors or unexpected behavior.

Window rules go in `~/.config/hypr/hyprland.conf` or a sourced file. Always verify the current syntax from the wiki first.

### Fonts

```bash
zanken font list               # Available fonts
zanken font current            # Current font
zanken font set <name>         # Change font
```

### System

```bash
zanken update                  # Full system update
zanken version                 # Show Zanken version
zanken debug --no-sudo --print # Debug info (ALWAYS use these flags)
zanken system lock             # Lock screen
zanken system shutdown         # Shutdown
zanken system reboot           # Reboot
```

**IMPORTANT:** Always run `zanken debug` with `--no-sudo --print` flags to avoid interactive sudo prompts that will hang the terminal.

## Troubleshooting

```bash
# Get debug information (ALWAYS use these flags to avoid interactive prompts)
zanken debug --no-sudo --print

# Upload logs for support
zanken upload log

# Reset specific config to defaults
zanken refresh <app>

# Refresh specific config file
# config-file path is relative to ~/.config/
# eg. `zanken refresh config hypr/hyprlock.conf` will refresh ~/.config/hypr/hyprlock.conf
zanken refresh config <config-file>

# Full reinstall of configs (nuclear option)
zanken reinstall
```

## Decision Framework

When user requests system changes:

1. **Is it a stock zanken command?** Use it directly
2. **Is it a config edit?** Edit in `~/.config/`, never `~/.local/share/zanken/`
3. **Is it a theme customization?** Create a NEW custom theme directory
4. **Is it automation?** Use hooks in `~/.config/zanken/hooks/`
5. **Is it a package install?** Use `zanken pkg add <pkgs...>` (or `zanken pkg aur add <pkgs...>` for AUR-only packages)
6. **Unsure if command exists?** Run `zanken commands` (or `zanken <group> --help` for one group)

### Reminder Requests

When the user asks to set a reminder, use `zanken reminder <minutes> [message]` directly. Convert natural language durations to minutes and title-case short reminder labels when appropriate.

```bash
zanken reminder 15 "Pickup Jack"
zanken reminder 60 "Check laundry"
zanken reminder show
zanken reminder clear
```

## Out of Scope

This skill intentionally does not cover Zanken source development. Do not use this skill for:
- Editing files in `~/.local/share/zanken/` (`bin/`, `config/`, `default/`, `themes/`, `migrations/`, etc.)
- Creating or editing migrations
- Running `zanken dev ...` commands

## Example Requests

- "Change my theme to catppuccin" -> `zanken theme set catppuccin`
- "Add a keybinding for Super+E to open file manager" -> Check existing bindings first, add `unbind` if needed, then add `bind` in `~/.config/hypr/bindings.conf`
- "Configure my external monitor" -> Edit `~/.config/hypr/monitors.conf`
- "Make the window gaps smaller" -> Edit `~/.config/hypr/looknfeel.conf`
- "Set up night light to turn on at sunset" -> `zanken toggle nightlight` or edit `~/.config/hypr/hyprsunset.conf`
- "Set a reminder to pickup jack in 15 minutes" -> `zanken reminder 15 "Pickup Jack"`
- "Show my reminders" -> `zanken reminder show`
- "Clear all reminders" -> `zanken reminder clear`
- "Customize the catppuccin theme colors" -> Create `~/.config/zanken/themes/catppuccin-custom/` by copying from stock, then edit
- "Run a script every time I change themes" -> Create `~/.config/zanken/hooks/theme-set`
- "Reset waybar to defaults" -> `zanken refresh waybar`
