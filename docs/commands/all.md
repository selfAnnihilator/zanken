# All Commands

308 commands organized alphabetically. Each command is a standalone script in `~/zanken/bin/`.

| Command | Description |
|---------|-------------|
| `omarchy-ac-present` | Returns true if AC power is connected. |
| `omarchy-audio-input-mute` | Toggle microphone mute. Drives the hardware mic-mute LED on laptops that expose one. |
| `omarchy-audio-output-switch` | Switch between audio outputs while preserving the mute status. By default mapped to Super + Mute. |
| `omarchy-battery-capacity` | Returns the battery full capacity in Wh (rounded to whole number). |
| `omarchy-battery-monitor` | Designed to be run by systemd timer every 30 seconds and alerts if battery is low |
| `omarchy-battery-present` | Returns true if a battery is present on the system. |
| `omarchy-battery-remaining` | Returns the battery percentage remaining as an integer. |
| `omarchy-battery-remaining-time` | Returns the battery time remaining (to empty or full) in a compact format. |
| `omarchy-battery-status` | Returns a formatted battery status string with percentage and power draw/charge. |
| `omarchy-branch-set` | Set the branch for Omarchy's git repository. |
| `omarchy-branding-about` | Edit, set, or reset About branding |
| `omarchy-branding-screensaver` | Edit, set, or reset screensaver branding |
| `omarchy-brightness-display` | Adjust brightness on the most likely display device. |
| `omarchy-brightness-display-apple` | Adjust the brightness on Apple Studio Displays and Apple XDR Displays using asdcontrol. |
| `omarchy-brightness-keyboard` | Adjust keyboard backlight brightness using available steps. |
| `omarchy-brightness-keyboard-mute` | Set the mic-mute indicator LED on laptops that expose a platform::micmute LED node. |
| `omarchy-capture-screenrecording` | Start or stop screen recording |
| `omarchy-capture-screenshot` | Take a screenshot |
| `omarchy-capture-text-extraction` | Extract text from a screenshot region with OCR |
| `omarchy-channel-set` | Set the Omarchy channel, which dictates what git branch and package repository is used. |
| `omarchy-cmd-missing` | Check whether any required commands are missing |
| `omarchy-cmd-present` | Check whether all required commands are available |
| `omarchy-cmd-terminal-cwd` | Print the current working directory of the active terminal window |
| `omarchy-config-direct-boot` | Add or remove an EFI boot entry for the Omarchy UKI, allowing the system to boot directly |
| `omarchy-debug` | Print debugging information |
| `omarchy-default-browser` | Set the default browser for Omarchy and XDG handlers |
| `omarchy-default-editor` | Set the default editor for $EDITOR |
| `omarchy-default-terminal` | Set the default terminal used by xdg-terminal-exec |
| `omarchy-dev-add-migration` | Creates a new Omarchy migration named after the unix timestamp of the last commit. |
| `omarchy-dev-benchmark` | Measure Omarchy CLI response times |
| `omarchy-dev-benchmark-theme-switcher` | Measure theme switcher cache and selector prep times |
| `omarchy-dev-bin-metadata` | Show Omarchy bin metadata fields and defaults |
| `omarchy-drive-info` | Print drive information such as size, model, and mount details |
| `omarchy-drive-password` | Set a new encryption password for a drive selected. |
| `omarchy-drive-select` | Select a drive from a list with info that includes space and brand. Used by omarchy-drive-password. |
| `omarchy-first-run` | Finish the installation of Omarchy with items that can only be done after logging in. |
| `omarchy-font-current` | Show current monospace font |
| `omarchy-font-list` | List available monospace fonts |
| `omarchy-font-set` | Set the system monospace font |
| `omarchy-games-retro-cores` | List installed RetroArch core names |
| `omarchy-games-retro-install` | Create a desktop launcher for a RetroArch game |
| `omarchy-hibernation-available` | Check if hibernation is supported |
| `omarchy-hibernation-remove` | Remove hibernation setup including swap and boot resume settings |
| `omarchy-hibernation-setup` | Set up hibernation with swap and boot resume configuration |
| `omarchy-hook` | Run a named hook from ~/.config/zanken/hooks/<name> and ~/.config/zanken/hooks/<name>.d/. |
| `omarchy-hook-install` | Install a hook into ~/.config/zanken/hooks/<type>.d/ |
| `omarchy-hw-asus-expertbook-b9406` | Detect ASUS ExpertBook B9406 series laptops on Intel Panther Lake. |
| `omarchy-hw-asus-rog` | Detect whether the computer is an Asus ROG machine. |
| `omarchy-hw-asus-zenbook-ux5406aa` | Detect ASUS Zenbook UX5406AA series laptops on Intel Panther Lake. |
| `omarchy-hw-dell-xps-haptic-touchpad` | Match Dell XPS systems with the Synaptics haptic touchpad. |
| `omarchy-hw-dell-xps-oled` | Match Dell XPS systems with LG OLED panel on Intel Panther Lake (Xe3) GPU. |
| `omarchy-hw-external-monitors` | Returns true when an external monitor is physically connected. |
| `omarchy-hw-framework16` | Detect whether the computer is a Framework Laptop 16. |
| `omarchy-hw-hybrid-gpu` | Detect whether the system has an active hybrid GPU configuration |
| `omarchy-hw-intel` | Detect whether the computer has an Intel CPU. |
| `omarchy-hw-intel-ptl` | Detect whether the computer has an Intel Panther Lake GPU. |
| `omarchy-hw-match` | Match against the computer's DMI product name or product family (case-insensitive). |
| `omarchy-hw-nvidia-gsp` | Detect whether the computer has an NVIDIA GPU with GSP firmware (Turing or newer). |
| `omarchy-hw-nvidia-without-gsp` | Detect whether the computer has an NVIDIA GPU without GSP firmware (Maxwell/Pascal/Volta). |
| `omarchy-hw-recover-internal-monitor` | Clear the internal-monitor-disable toggle if no external display is connected. |
| `omarchy-hw-surface` | Detect whether the computer is a Microsoft Surface device. |
| `omarchy-hw-touchpad` | Print the detected Hyprland touchpad or trackpad device name |
| `omarchy-hw-touchscreen` | Print the detected Hyprland touchscreen or tablet device name |
| `omarchy-hw-vulkan` | Detect whether Vulkan is available. |
| `omarchy-hyprland-monitor-focused` | Print the name of the currently focused Hyprland monitor. |
| `omarchy-hyprland-monitor-focused-apple` | Return success if the focused Hyprland monitor is an Apple display. |
| `omarchy-hyprland-monitor-internal` | Enable, disable, toggle, or recover the internal laptop display |
| `omarchy-hyprland-monitor-internal-mirror` | Enable, disable, toggle, or recover mirroring the internal display to an external monitor |
| `omarchy-hyprland-monitor-scale` | Print the monitor scale of the internal monitor or first other monitor |
| `omarchy-hyprland-monitor-scaling-cycle` | Cycle focused Hyprland monitor scaling through 1x, 1.25x, 1.6x, 2x, 3x, and 4x |
| `omarchy-hyprland-monitor-watch` | Watch Hyprland monitor events and recover monitor toggles when a monitor is removed |
| `omarchy-hyprland-toggle` | Toggle permanent Hyprland flags by copying them into a directory that's sourced entirely. |
| `omarchy-hyprland-toggle-disabled` | Check if a Hyprland toggle is currently disabled (missing). |
| `omarchy-hyprland-toggle-enabled` | Check if a Hyprland toggle is currently enabled. |
| `omarchy-hyprland-window-close-all` | Close all open windows |
| `omarchy-hyprland-window-gaps-toggle` | Toggles the window gaps globally between no gaps and the default. |
| `omarchy-hyprland-window-pop` | Toggle to pop-out a tile to stay fixed on a display basis. |
| `omarchy-hyprland-window-single-square-aspect-toggle` | Toggle single-window square aspect ratio. |
| `omarchy-hyprland-window-transparency-toggle` | Toggles transparency for the currently focused window. |
| `omarchy-hyprland-workspace-layout-toggle` | Toggle the layout on the current active workspace between dwindle and scrolling |
| `omarchy-install-browser` | Install a supported browser |
| `omarchy-install-chromium-google-account` | Allow Chromium to sign in to Google accounts by adding the required OAuth credentials |
| `omarchy-install-dev-env` | Install a supported development environment |
| `omarchy-install-docker-dbs` | Install one of the supported databases in a Docker container with the suitable development options. |
| `omarchy-install-dropbox` | Install and start the Dropbox service. Must then be authenticated via the web. |
| `omarchy-install-gaming-geforce-now` | Install and launch Geforce Now. |
| `omarchy-install-gaming-gpu-lib32` | Install lib32 graphics drivers (Vulkan + NVIDIA) for any detected GPUs. |
| `omarchy-install-gaming-heroic` | Install Heroic Games Launcher (Epic, GOG, Amazon Prime Gaming) with graphics drivers. |
| `omarchy-install-gaming-lutris` | Install Lutris with Wine + DXVK for running Windows games (Battle.net, EA, Ubisoft Connect, etc.) |
| `omarchy-install-gaming-moonlight` | Install Moonlight (NVIDIA GameStream / Sunshine client) for streaming games to this PC. |
| `omarchy-install-gaming-retroarch` | Install RetroArch with the full libretro core set plus FBNeo and a ~/Games ROM directory. |
| `omarchy-install-gaming-steam` | Install Steam and graphics drivers selected for this system |
| `omarchy-install-gaming-xbox-cloud` | Install Xbox Cloud Gaming as a web app and launch it. |
| `omarchy-install-gaming-xbox-controllers` | Install support for using Xbox controllers with Steam/RetroArch/etc. |
| `omarchy-install-helix` | Install Helix and configure it to use the current Omarchy theme |
| `omarchy-install-nordvpn` | Install the NordVPN service with optional GUI. |
| `omarchy-install-once` | Install the ONCE service, enable its background service, and launch the TUI. |
| `omarchy-install-service-sunshine` | Install Sunshine and open Moonlight streaming ports for LAN and Tailscale. |
| `omarchy-install-tailscale` | Install the Tailscale mesh VPN service and a web app for the Tailscale Admin Console. |
| `omarchy-install-terminal` | Install one of the approved terminals and set it as the default for Omarchy (Super + Return etc). |
| `omarchy-install-vscode` | Install VS Code and configure Omarchy defaults for secrets, updates, and theme |
| `omarchy-install-zed` | Install Zed Editor and configure it with the current Omarchy theme |
| `omarchy-launch-about` | Launch the fastfetch TUI that gives information about the current system. |
| `omarchy-launch-audio` | Launch the Omarchy audio controls TUI (provided by wiremix). |
| `omarchy-launch-bluetooth` | Launch the Omarchy bluetooth controls TUI (provided by bluetui). |
| `omarchy-launch-browser` | Launch the default browser as determined by xdg-settings. |
| `omarchy-launch-editor` | Launch the default editor as determined by $EDITOR (set via ~/.config/uwsm/default) (or nvim if missing). |
| `omarchy-launch-floating-terminal-with-presentation` | Launch a floating terminal with the Omarchy presentation wrapper |
| `omarchy-launch-nautilus` | Launch Files |
| `omarchy-launch-nautilus-cwd` | Launch Files in the active terminal's current directory |
| `omarchy-launch-or-focus` | Launch an app or focus an existing window matching a pattern |
| `omarchy-launch-or-focus-tui` | Launch a TUI or focus an existing terminal window for it |
| `omarchy-launch-or-focus-webapp` | Launch or focus on a given web app identified by the window-pattern. |
| `omarchy-launch-screensaver` | Launch the Omarchy screensaver in the default terminal on the system with the correct font configuration. |
| `omarchy-launch-terminal` | Launch a terminal in the active terminal's current directory |
| `omarchy-launch-terminal-tmux` | Launch or attach to the Work tmux session in a terminal |
| `omarchy-launch-tui` | Launch a TUI command in the default terminal with Omarchy styling |
| `omarchy-launch-walker` | Launch Walker and ensure its Elephant data provider is running |
| `omarchy-launch-webapp` | Launch a URL as a web app in the default supported browser |
| `omarchy-launch-wifi` | Launch the Omarchy wifi controls (provided by the Impala TUI). |
| `omarchy-menu` | Launch the Omarchy Menu or takes a parameter to jump straight to a submenu. |
| `omarchy-menu-file` | Pick a file with Walker |
| `omarchy-menu-images` | Open a generic image selector menu |
| `omarchy-menu-input` | Prompt for text input with Walker |
| `omarchy-menu-keybindings` | Display Hyprland keybindings defined in your configuration using walker for an interactive search menu. |
| `omarchy-menu-select` | Pick one option with Walker |
| `omarchy-menu-share` | Share clipboard, files, or folders with LocalSend |
| `omarchy-menu-tmux-keybindings` | Display Tmux keybindings defined in your configuration using walker for an interactive search menu. |
| `omarchy-migrate` | Run all pending migrations to bring the system in line with the installed version. |
| `omarchy-notification-battery` | Show the current battery status notification |
| `omarchy-notification-dismiss` | Dismiss a mako notification on the basis of its summary. Used by the first-run notifications to dismiss them after clicking for action. |
| `omarchy-notification-send` | Send a desktop notification with Omarchy glyph and body spacing |
| `omarchy-notification-time` | Show the current time and date notification |
| `omarchy-notification-weather` | Show the current weather notification |
| `omarchy-npm-install` | Install a pnpm dlx wrapper for a given npm package. |
| `omarchy-pkg-add` | Install Arch packages if they are missing |
| `omarchy-pkg-aur-accessible` | Returns true if the AUR is up and available. |
| `omarchy-pkg-aur-add` | Add the named packages to the system from the AUR if they're missing. Returns false if it couldn't be done. |
| `omarchy-pkg-aur-install` | Show a fuzzy-finder TUI for picking new AUR packages to install. |
| `omarchy-pkg-drop` | Remove all the named packages from the system if they're installed (otherwise ignore). |
| `omarchy-pkg-install` | Show a fuzzy-finder TUI for picking new Arch and OPR packages to install. |
| `omarchy-pkg-missing` | Returns true if any of the named packages are missing from the system (or false if they're all there). |
| `omarchy-pkg-present` | Returns true if all of the named packages are installed on the system (or false if any of them are missing). |
| `omarchy-pkg-remove` | Show a fuzzy-finder TUI for picking packages installed on the system to be removed. |
| `omarchy-plymouth-preview` | Preview a Plymouth boot screen with custom colors and logo |
| `omarchy-plymouth-reset` | Restore the default Omarchy Plymouth boot theme and SDDM login screen |
| `omarchy-plymouth-set` | Set the Plymouth boot theme colors and logo |
| `omarchy-plymouth-set-by-theme` | Set the Plymouth boot theme from an Omarchy theme |
| `omarchy-powerprofiles-init` | Set the correct power profile on boot based on current AC/battery state. |
| `omarchy-powerprofiles-list` | Returns a list of all the available power profiles on the system. |
| `omarchy-powerprofiles-set` | Set the power profile to the requested level, falling back to balanced |
| `omarchy-refresh-applications` | Ensure all default .desktop, web apps, TUIs, and npm wrappers are installed. |
| `omarchy-refresh-chromium` | Refresh the ~/.config/chromium-flags.conf file from the Omarchy defaults. |
| `omarchy-refresh-config` | Copies the named config from ~/.local/share/omarchy/config/X/Y/Z -> ~/.config/X/Y/Z. |
| `omarchy-refresh-fastfetch` | Overwrite the user config for fastfetch with the Omarchy default. |
| `omarchy-refresh-hypridle` | Overwrite the user config for hypridle with the Omarchy default and restart the service. |
| `omarchy-refresh-hyprland` | Overwrite all the user Hyprland Lua configs in ~/.config/hypr with the Omarchy defaults. |
| `omarchy-refresh-hyprlock` | Overwrite the user config for hyprlock with the Omarchy default. |
| `omarchy-refresh-hyprsunset` | Overwrite the user config for hyprsunset with the Omarchy default and restart the service. |
| `omarchy-refresh-limine` | Overwrite the user config for the Limine bootloader and rebuild it. |
| `omarchy-refresh-pacman` | Overwrite the package configuration for /etc/pacman with the Omarchy default of using its dedicated mirrors and repositories, then update all packages. |
| `omarchy-refresh-plymouth` | Overwrite the user config for the Plymouth drive decryption and boot sequence with the Omarchy default and rebuild it. |
| `omarchy-refresh-sddm` | Refresh the SDDM theme from default |
| `omarchy-refresh-swayosd` | Overwrite the user configs for swayosd (controls on-screen feedback for changing volume/songs etc) with the Omarchy defaults and restart the service. |
| `omarchy-refresh-tmux` | Overwrite the user tmux config with the Omarchy default and reload tmux. |
| `omarchy-refresh-walker` | Overwrite the user configs for the Walker application launcher (which also powers the Omarchy Menu) and restart the services. |
| `omarchy-refresh-waybar` | Reset Waybar config to Omarchy defaults |
| `omarchy-reinstall` | Reinstall Omarchy packages and reset default configs |
| `omarchy-reinstall-configs` | Reset all Omarchy user configs to the defaults |
| `omarchy-reinstall-git` | Reinstall the stable Omarchy source directory from git |
| `omarchy-reinstall-pkgs` | Reinstall all default Omarchy packages from the stable channel |
| `omarchy-reminder` | Set and show lightweight desktop notification reminders |
| `omarchy-remove-browser` | Remove a supported browser and clean up Omarchy browser defaults |
| `omarchy-remove-dev-env` | Remove a development environment that was previously installed via omarchy-install-dev-env. |
| `omarchy-remove-gaming-geforce-now` | Remove the GeForce NOW Flatpak app and its data. |
| `omarchy-remove-gaming-heroic` | Remove Heroic Games Launcher and its game libraries, configs, and caches. |
| `omarchy-remove-gaming-lutris` | Remove Lutris, Wine, umu-launcher, and all their configs and caches. |
| `omarchy-remove-gaming-minecraft` | Remove the Minecraft launcher along with its worlds, mods, and caches. |
| `omarchy-remove-gaming-moonlight` | Remove Moonlight and its configs and caches. |
| `omarchy-remove-gaming-retroarch` | Remove RetroArch, all libretro cores, and its config/saves. Leaves ~/Games/roms and ~/Games/bios alone. |
| `omarchy-remove-gaming-steam` | Remove Steam and all of its game libraries, configs, and caches. |
| `omarchy-remove-gaming-xbox-cloud` | Remove the Xbox Cloud Gaming web app. |
| `omarchy-remove-gaming-xbox-controllers` | Remove the xpadneo Xbox controller driver and undo its module/blacklist config. |
| `omarchy-remove-preinstalls` | Remove preinstalled Omarchy applications (web apps, TUIs, and selected packages). |
| `omarchy-remove-security-fido2` | Remove FIDO2 authentication from sudo and polkit |
| `omarchy-remove-security-fingerprint` | Remove fingerprint authentication from sudo, polkit, and lock screen |
| `omarchy-remove-service-sunshine` | Remove Sunshine and close Omarchy-managed Moonlight streaming ports. |
| `omarchy-restart-app` | Restart an application by killing it and relaunching via uwsm. |
| `omarchy-restart-bluetooth` | Unblock and restart the bluetooth service. |
| `omarchy-restart-btop` | Reload btop configuration (used by the Omarchy theme switching). |
| `omarchy-restart-helix` | Reload Helix configuration |
| `omarchy-restart-hyprctl` | Reload hyprland configuration (used by the Omarchy theme switching). |
| `omarchy-restart-hypridle` | Restart the hypridle service (used for idle detection and auto-lock). |
| `omarchy-restart-hyprsunset` | Restart the hyprsunset service (used for blue light filtering/night light). |
| `omarchy-restart-mako` | Reload mako configuration (used by the Omarchy theme switching). |
| `omarchy-restart-opencode` | Reload opencode configuration (used by the Omarchy theme switching). |
| `omarchy-restart-pipewire` | Restart the PipeWire audio service to fix audio issues or apply new configuration. |
| `omarchy-restart-swayosd` | Restart the SwayOSD server |
| `omarchy-restart-terminal` | Reload supported terminal emulators after config changes |
| `omarchy-restart-tmux` | Restart tmux if running with the latest configuration |
| `omarchy-restart-trackpad` | Reset the trackpad by unbinding and rebinding its driver. |
| `omarchy-restart-walker` | Restart Walker and related user services |
| `omarchy-restart-waybar` | Restart Waybar |
| `omarchy-restart-wifi` | Unblock and restart the Wi-Fi service. |
| `omarchy-restart-xcompose` | Restart the XCompose input method service (fcitx5) to apply new compose key settings. |
| `omarchy-screensaver` | Run the Omarchy screensaver using random effects from TTE. |
| `omarchy-setup-dns` | Configure the system DNS provider |
| `omarchy-setup-security-fido2` | Set up FIDO2 authentication for sudo and polkit |
| `omarchy-setup-security-fingerprint` | Set up fingerprint authentication for sudo, polkit, and lock screen |
| `omarchy-show-done` | Display a "Done!" message with a spinner and wait for user to press any key. |
| `omarchy-show-logo` | Display the Omarchy logo in the terminal using green color. |
| `omarchy-snapshot` | Create or restore system snapshots with snapper |
| `omarchy-state` | Manage persistent state files for Omarchy toggles and settings. |
| `omarchy-style-corners` | Set Hyprland, Hyprlock, Mako, and Walker corners to sharp or round |
| `omarchy-style-corners-hyprland` | Set or toggle shape of Hyprland window corners |
| `omarchy-style-corners-hyprlock` | Set or toggle rounded Hyprlock input field corners |
| `omarchy-style-corners-mako` | Set or toggle rounded Mako notification corners |
| `omarchy-style-corners-walker` | Set or toggle rounded Walker corners |
| `omarchy-style-waybar-position` | Set Waybar position |
| `omarchy-sudo-keepalive` | Prompt for sudo once and keep the credential alive in the background. |
| `omarchy-sudo-passwordless` | Toggle passwordless sudo for the current user. |
| `omarchy-sudo-reset` | Reset the sudo lockout/faillock for the current user. |
| `omarchy-swayosd-brightness` | Display brightness level using SwayOSD on the current monitor. |
| `omarchy-swayosd-client` | Wrapper for swayosd-client that targets the currently focused monitor. |
| `omarchy-swayosd-kbd-brightness` | Display keyboard brightness level using SwayOSD on the current monitor. |
| `omarchy-system-lock` | Lock the computer and turn off the display |
| `omarchy-system-logout` | Log out after closing application windows |
| `omarchy-system-reboot` | Reboot after closing application windows |
| `omarchy-system-shutdown` | Shut down after closing application windows |
| `omarchy-system-wake` | Wake displays and restore brightness after idle |
| `omarchy-theme-bg-cache` | Cache background switcher thumbnails for the current theme |
| `omarchy-theme-bg-colors-apply` | Apply a wallpaper-extracted accent color to niri, GTK, and quickshell |
| `omarchy-theme-bg-install` | Open the current theme's user background folder |
| `omarchy-theme-bg-next` | Cycle to the next background for the current theme |
| `omarchy-theme-bg-set` | Set the current background image |
| `omarchy-theme-bg-switcher` | Open the Omarchy background switcher |
| `omarchy-theme-colors-from-alacritty` | Generate a theme's colors.toml from its alacritty.toml palette |
| `omarchy-theme-current` | Show current theme |
| `omarchy-theme-install` | Install a theme from a git repository |
| `omarchy-theme-list` | List available themes |
| `omarchy-theme-refresh` | Refresh the current theme from its templates. |
| `omarchy-theme-remove` | Remove a user-installed theme |
| `omarchy-theme-set` | Apply an Omarchy theme |
| `omarchy-theme-set-browser` | Apply the current theme color to Chromium, Chrome, Edge, and Brave |
| `omarchy-theme-set-foot` | Apply current Omarchy theme colors to running Foot terminals |
| `omarchy-theme-set-gnome` | Apply the current theme to GNOME color mode and icon settings |
| `omarchy-theme-set-keyboard` | Apply the current theme keyboard color to supported keyboards |
| `omarchy-theme-set-keyboard-asus-rog` | Apply the current theme keyboard color to ASUS ROG keyboards |
| `omarchy-theme-set-keyboard-f16` | Apply the current theme keyboard color to Framework Laptop 16 keyboards |
| `omarchy-theme-set-obsidian` | Sync Omarchy theme to all Obsidian vaults |
| `omarchy-theme-set-templates` | Generate themed config files from Omarchy templates |
| `omarchy-theme-set-vscode` | Sync Omarchy theme to VS Code, VSCodium, and Cursor |
| `omarchy-theme-switcher` | Open the Omarchy theme switcher |
| `omarchy-theme-update` | Update user-installed git themes |
| `omarchy-toggle` | Toggle Omarchy features between enabled and disabled |
| `omarchy-toggle-enabled` | Check if a toggle is enabled (flag file exists) |
| `omarchy-toggle-hybrid-gpu` | Toggle dedicated vs integrated GPU mode via supergfxd (for hybrid gpu laptops, like Asus G14). |
| `omarchy-toggle-idle` | Toggle hypridle idle locking |
| `omarchy-toggle-nightlight` | Toggle nightlight screen temperature |
| `omarchy-toggle-notification-silencing` | Toggle notification do-not-disturb mode |
| `omarchy-toggle-screensaver` | Toggle screensaver availability |
| `omarchy-toggle-suspend` | Toggle suspend availability in the system menu |
| `omarchy-toggle-touchpad` | Enable, disable, or toggle the touchpad |
| `omarchy-toggle-touchscreen` | Enable, disable, or toggle the touch functionality of the screen |
| `omarchy-toggle-waybar` | Toggle Waybar visibility |
| `omarchy-transcode` | Transcode pictures and videos for sharing |
| `omarchy-transcode-ascii` | Transcode an image into ASCII/Unicode art text |
| `omarchy-tui-install` | Create a desktop launcher for a terminal UI app |
| `omarchy-tui-remove` | Remove terminal UI desktop launchers |
| `omarchy-tui-remove-all` | Remove all TUIs installed via omarchy-tui-install. |
| `omarchy-tz-select` | Select and set the system timezone |
| `omarchy-update` | Update Omarchy and system packages |
| `omarchy-update-analyze-logs` | Check the update log for known failure conditions |
| `omarchy-update-aur-pkgs` | Update AUR packages if any are installed |
| `omarchy-update-available` | Get remote tag |
| `omarchy-update-available-reset` | Ensure Waybar icon offering the available update is removed |
| `omarchy-update-branch` | Switch Omarchy branches and update from the selected branch |
| `omarchy-update-confirm` | Prompt for confirmation before starting an update |
| `omarchy-update-firmware` | Update system firmware using fwupd. Ensures the fwupd EFI binary is installed |
| `omarchy-update-git` | Pull the latest Omarchy git changes |
| `omarchy-update-keyring` | Ensure the Omarchy and Arch keyring packages are installed and populated |
| `omarchy-update-orphan-pkgs` | Remove orphaned system packages after updates |
| `omarchy-update-perform` | Run the full Omarchy update pipeline |
| `omarchy-update-restart` | Prompt for required reboot or service restarts after updates |
| `omarchy-update-system-pkgs` | Update system packages with pacman |
| `omarchy-update-time` | Restart system time synchronization |
| `omarchy-update-without-idle` | No-op now that omarchy-update-perform is responsible for idle management. |
| `omarchy-upload-log` | Upload logs to 0x0.st |
| `omarchy-version` | Print the installed Omarchy version |
| `omarchy-version-branch` | Print the current Omarchy git branch |
| `omarchy-version-channel` | Print the active Omarchy mirror and package channel |
| `omarchy-version-pkgs` | Print when system packages were last upgraded |
| `omarchy-voxtype-config` | Open the Voxtype configuration file |
| `omarchy-voxtype-install` | Install and configure Voxtype dictation |
| `omarchy-voxtype-model` | Open Voxtype AI model setup |
| `omarchy-voxtype-remove` | Remove Voxtype dictation and its configuration |
| `omarchy-voxtype-status` | Clean up the voxtype --follow child when Waybar reloads |
| `omarchy-wallpaper-colors` | Extract the most vibrant accent color from a wallpaper image |
| `omarchy-weather-icon` | Returns a weather condition icon, adjusted for live sunrise and sunset. |
| `omarchy-weather-status` | Returns a formatted weather status string with temperature and wind speed. |
| `omarchy-webapp-handler-hey` | Open HEY webmail and translate mailto links |
| `omarchy-webapp-handler-zoom` | Open Zoom web meetings from browser protocol links |
| `omarchy-webapp-install` | Create a desktop launcher for a web app |
| `omarchy-webapp-remove` | Remove web app desktop launchers |
| `omarchy-webapp-remove-all` | Remove all web apps installed via omarchy-webapp-install. |
| `omarchy-wifi-powersave` | Set Wi-Fi power save mode on wireless interfaces |
| `omarchy-windows-vm` | Install, launch, stop, inspect, or remove the Windows VM |
