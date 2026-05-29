# Commands

Zanken ships 308 `omarchy-*` scripts. All are on `$PATH` via `~/zanken/bin/`.

## Usage

```bash
omarchy <group>           # List commands in a group
omarchy <command>         # Run a command
omarchy audio             # e.g. list audio commands
omarchy-audio-input-mute  # e.g. run directly
```

## Command groups

| Prefix | Description |
|--------|-------------|
| `ac-` | AC power detection |
| `audio-` | Audio output switching and mic mute |
| `battery-` | Battery status helpers |
| `brightness-` | Display and keyboard brightness |
| `capture-` | Screenshots, screen recording, OCR |
| `cmd-` | Command presence checks |
| `config-` | System configuration helpers |
| `debug-` | Diagnostics and support logs |
| `default-` | Default application selection |
| `dev-` | Development and benchmarking tools |
| `drive-` | Drive selection and encryption |
| `font-` | Font management |
| `games-` | Game launchers and RetroArch helpers |
| `hibernation-` | Hibernation setup and removal |
| `hook-` | User hook runner |
| `hw-` | Hardware detection (return exit codes) |
| `install-` | Optional software installers |
| `launch-` | Application launchers |
| `menu-` | Quickshell palette commands |
| `notification-` | Notification helpers |
| `pkg-` | Package management helpers |
| `refresh-` | Reset config to defaults |
| `reinstall-` | Reinstall and reset workflows |
| `reminder-` | Desktop notification reminders |
| `remove-` | Remove optional software |
| `restart-` | Restart a component |
| `setup-` | Interactive setup wizards |
| `snapshot-` | Btrfs snapshot management |
| `style-` | UI style controls (corners, etc.) |
| `system-` | Lock, logout, shutdown, reboot |
| `theme-` | Theme management |
| `toggle-` | Toggle features on/off |
| `transcode-` | Media transcoding helpers |
| `tui-` | TUI app install/remove |
| `update-` | System and package update helpers |

See [All Commands](all.md) for the full alphabetical list.
