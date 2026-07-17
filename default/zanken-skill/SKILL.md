---
name: zanken
description: Configure and troubleshoot the Zanken Niri desktop, Quickshell bar, themes, and Zanken commands.
---

# Zanken desktop

Use this skill when changing the Zanken desktop or helping a user configure it.
Zanken uses Niri as its compositor and Quickshell as its bar and desktop shell.

## Source of truth

- Niri configuration: `~/.config/niri/config.kdl`
- Quickshell desktop shell: `~/.config/quickshell/desktop/`
- Zanken theme state: `~/.config/zanken/current/theme/`
- Zanken defaults: `~/.local/share/zanken/config/`

The Niri and Quickshell configuration is managed in the user's dotfiles
repository. Do not overwrite either directory with a generic refresh command.
Use the dotfiles workflow when reverting or updating it:

```bash
git --git-dir=$HOME/dotfiles --work-tree=$HOME checkout --force main -- .config/niri .config/quickshell
```

## Safe workflow

1. Read the relevant configuration before editing it.
2. Back up a user-owned configuration file before a material manual change.
3. Validate Niri after editing its configuration:

   ```bash
   niri validate --config ~/.config/niri/config.kdl
   niri msg action load-config-file
   ```

4. Restart Quickshell after changing its QML:

   ```bash
   zanken restart quickshell
   ```

5. For visual changes, take a fullscreen screenshot and inspect it:

   ```bash
   zanken capture screenshot fullscreen save
   ```

## Useful commands

| Intent | Command |
| --- | --- |
| Discover commands | `zanken commands` |
| Check command metadata | `zanken commands --check` |
| Restart the desktop shell | `zanken restart quickshell` |
| Choose a theme | `zanken theme set <name>` |
| Set a background | `zanken background` |
| Restart an app | `zanken restart app <app-id>` |
| View Niri keybindings | `zanken niri keybindings` |

## Terminology

- Say **Niri**, not Hyprland, for compositor configuration and window actions.
- Say **Quickshell**, not Waybar, for the status bar and popups.
- Use paths under `~/.config/zanken/`, not legacy Omarchy paths, for Zanken-owned theme state.

## Guardrails

- Do not recommend retired Waybar commands; they no longer exist.
- Do not edit `~/.config/hypr/` or `~/.config/waybar/` for Zanken desktop changes.
- Avoid restarting Niri as the first response to a configuration change; validate and reload its config first.
