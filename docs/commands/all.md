# All Commands

263 public commands generated from CLI metadata.

| Command | Description |
|---------|-------------|
| `zanken-ac-present` | Returns true if AC power is connected. |
| `zanken-audio-input-mute` | Toggle microphone mute. Drives the hardware mic-mute LED on laptops that expose one. |
| `zanken-audio-output-switch` | Switch between audio outputs while preserving the mute status. By default mapped to Super + Mute. |
| `zanken-battery-capacity` | Returns the battery full capacity in Wh (rounded to whole number). |
| `zanken-battery-present` | Returns true if a battery is present on the system. |
| `zanken-battery-remaining` | Returns the battery percentage remaining as an integer. |
| `zanken-battery-remaining-time` | Returns the battery time remaining (to empty or full) in a compact format. |
| `zanken-battery-status` | Returns a formatted battery status string with percentage and power draw/charge. |
| `zanken-branch-set` | Set the branch for Zanken's git repository. |
| `zanken-branding-about` | Edit, set, or reset About branding |
| `zanken-branding-screensaver` | Edit, set, or reset screensaver branding |
| `zanken-brightness-display` | Adjust brightness on the most likely display device. |
| `zanken-brightness-display-apple` | Adjust the brightness on Apple Studio Displays and Apple XDR Displays using asdcontrol. |
| `zanken-brightness-keyboard` | Adjust keyboard backlight brightness using available steps. |
| `zanken-brightness-keyboard-mute` | Set the mic-mute indicator LED on laptops that expose a platform::micmute LED node. |
| `zanken-capture-colorpicker` | Pick a screen color and copy its hex value |
| `zanken-capture-screenrecording` | Start or stop screen recording |
| `zanken-capture-screenshot` | Take a screenshot |
| `zanken-capture-text-extraction` | Extract text from a selected screen region |
| `zanken-channel-set` | Set the Zanken git release channel |
| `zanken-paste` | Paste with terminal-aware keyboard shortcuts |
| `zanken-cmd-missing` | Check whether any required commands are missing |
| `zanken-cmd-present` | Check whether all required commands are available |
| `zanken-config-desktop` | Sync or adopt the managed Zanken desktop configuration |
| `zanken-config-direct-boot` | Add or remove an EFI boot entry for the Zanken UKI, allowing the system to boot directly |
| `zanken-debug` | Print debugging information |
| `zanken-default-browser` | Set the default browser for Zanken and XDG handlers |
| `zanken-default-editor` | Set the default editor for $EDITOR |
| `zanken-default-terminal` | Set the default terminal used by xdg-terminal-exec |
| `zanken-dev-add-migration` | Creates a new Zanken migration named after the unix timestamp of the last commit. |
| `zanken-dev-benchmark` | Measure Zanken CLI response times |
| `zanken-dev-benchmark-theme-switcher` | Measure theme switcher cache and selector prep times |
| `zanken-dev-bin-metadata` | Show Zanken bin metadata fields and defaults |
| `zanken-dev-generate-command-docs` | Generate the public command reference from CLI metadata |
| `zanken-drive-info` | Print drive information such as size, model, and mount details |
| `zanken-drive-password` | Set a new encryption password for a drive selected. |
| `zanken-drive-select` | Select a drive from a list with info that includes space and brand. Used by zanken-drive-password. |
| `zanken-first-run` | Finish the installation of Zanken with items that can only be done after logging in. |
| `zanken-font-current` | Show current monospace font |
| `zanken-font-list` | List available monospace fonts |
| `zanken-font-pick` | Pick and apply a monospace font via fzf |
| `zanken-font-set` | Set the system monospace font |
| `zanken-games-retro-cores` | List installed RetroArch core names |
| `zanken-games-retro-install` | Create a desktop launcher for a RetroArch game |
| `zanken-hibernation-available` | Check if hibernation is supported |
| `zanken-hibernation-remove` | Remove hibernation setup including swap and boot resume settings |
| `zanken-hibernation-setup` | Set up hibernation with swap and boot resume configuration |
| `zanken-hook` | Run a named hook from ~/.config/zanken/hooks/<name> and ~/.config/zanken/hooks/<name>.d/. |
| `zanken-hook-install` | Install a hook into ~/.config/zanken/hooks/<type>.d/ |
| `zanken-hw-asus-expertbook-b9406` | Detect ASUS ExpertBook B9406 series laptops on Intel Panther Lake. |
| `zanken-hw-asus-rog` | Detect whether the computer is an Asus ROG machine. |
| `zanken-hw-asus-zenbook-ux5406aa` | Detect ASUS Zenbook UX5406AA series laptops on Intel Panther Lake. |
| `zanken-hw-dell-xps-haptic-touchpad` | Match Dell XPS systems with the Synaptics haptic touchpad. |
| `zanken-hw-dell-xps-oled` | Match Dell XPS systems with LG OLED panel on Intel Panther Lake (Xe3) GPU. |
| `zanken-hw-external-monitors` | Returns true when an external monitor is physically connected. |
| `zanken-hw-framework16` | Detect whether the computer is a Framework Laptop 16. |
| `zanken-hw-hybrid-gpu` | Detect whether the system has an active hybrid GPU configuration |
| `zanken-hw-intel` | Detect whether the computer has an Intel CPU. |
| `zanken-hw-intel-ptl` | Detect whether the computer has an Intel Panther Lake GPU. |
| `zanken-hw-match` | Match against the computer's DMI product name or product family (case-insensitive). |
| `zanken-hw-nvidia-gsp` | Detect whether the computer has an NVIDIA GPU with GSP firmware (Turing or newer). |
| `zanken-hw-nvidia-without-gsp` | Detect whether the computer has an NVIDIA GPU without GSP firmware (Maxwell/Pascal/Volta). |
| `zanken-hw-recover-internal-monitor` | Clear the internal-monitor-disable toggle if no external display is connected. |
| `zanken-hw-surface` | Detect whether the computer is a Microsoft Surface device. |
| `zanken-hw-vulkan` | Detect whether Vulkan is available. |
| `zanken-install-browser` | Install a supported browser |
| `zanken-install-chromium-google-account` | Allow Chromium to sign in to Google accounts by adding the required OAuth credentials |
| `zanken-install-dev-env` | Install a supported development environment |
| `zanken-install-docker-dbs` | Install one of the supported databases in a Docker container with the suitable development options. |
| `zanken-install-dropbox` | Install and start the Dropbox service. Must then be authenticated via the web. |
| `zanken-install-gaming-geforce-now` | Install and launch Geforce Now. |
| `zanken-install-gaming-gpu-lib32` | Install lib32 graphics drivers (Vulkan + NVIDIA) for any detected GPUs. |
| `zanken-install-gaming-heroic` | Install Heroic Games Launcher (Epic, GOG, Amazon Prime Gaming) with graphics drivers. |
| `zanken-install-gaming-lutris` | Install Lutris with Wine + DXVK for running Windows games (Battle.net, EA, Ubisoft Connect, etc.) |
| `zanken-install-gaming-moonlight` | Install Moonlight (NVIDIA GameStream / Sunshine client) for streaming games to this PC. |
| `zanken-install-gaming-retroarch` | Install RetroArch with the full libretro core set plus FBNeo and a ~/Games ROM directory. |
| `zanken-install-gaming-steam` | Install Steam and graphics drivers selected for this system |
| `zanken-install-gaming-xbox-cloud` | Install Xbox Cloud Gaming as a web app and launch it. |
| `zanken-install-gaming-xbox-controllers` | Install support for using Xbox controllers with Steam/RetroArch/etc. |
| `zanken-install-helix` | Install Helix and configure it to use the current Zanken theme |
| `zanken-install-nordvpn` | Install the NordVPN service with optional GUI. |
| `zanken-install-once` | Install the ONCE service, enable its background service, and launch the TUI. |
| `zanken-install-service-sunshine` | Install Sunshine and open Moonlight streaming ports for LAN and Tailscale. |
| `zanken-install-tailscale` | Install the Tailscale mesh VPN service and a web app for the Tailscale Admin Console. |
| `zanken-install-terminal` | Install one of the approved terminals and set it as the default for Zanken (Super + Return etc). |
| `zanken-install-vscode` | Install VS Code and configure Zanken defaults for secrets, updates, and theme |
| `zanken-install-zed` | Install Zed Editor and configure it with the current Zanken theme |
| `zanken-launch-about` | Launch the fastfetch TUI that gives information about the current system. |
| `zanken-launch-audio` | Launch the Zanken audio controls TUI (provided by wiremix). |
| `zanken-launch-bluetooth` | Launch the Zanken bluetooth controls TUI (provided by bluetui). |
| `zanken-launch-browser` | Launch the default browser as determined by xdg-settings. |
| `zanken-launch-editor` | Launch the default editor as determined by $EDITOR (set via ~/.config/uwsm/default) (or nvim if missing). |
| `zanken-launch-floating-terminal-with-presentation` | Launch a floating terminal with the Zanken presentation wrapper |
| `zanken-launch-or-focus` | Launch an app or focus an existing window matching a pattern |
| `zanken-launch-or-focus-tui` | Launch a TUI or focus an existing terminal window for it |
| `zanken-launch-or-focus-webapp` | Launch or focus on a given web app identified by the window-pattern. |
| `zanken-launch-screensaver` | Lock the session from the screensaver action |
| `zanken-launch-terminal` | Launch a terminal in the active terminal's current directory |
| `zanken-launch-terminal-tmux` | Launch or attach to the Work tmux session in a terminal |
| `zanken-launch-tui` | Launch a TUI command in the default terminal with Zanken styling |
| `zanken-launch-webapp` | Launch a URL as a web app in the default supported browser |
| `zanken-launch-wifi` | Launch the Zanken wifi controls (provided by the Impala TUI). |
| `zanken-menu` | Launch the Zanken menu or jump straight to a submenu |
| `zanken-menu-file` | Pick a file with Walker |
| `zanken-menu-images` | Open a generic image selector menu |
| `zanken-menu-input` | Prompt for text input with Walker |
| `zanken-menu-select` | Pick one option with Walker |
| `zanken-menu-tmux-keybindings` | Display Tmux keybindings defined in your configuration using walker for an interactive search menu. |
| `zanken-migrate` | Run all pending migrations to bring the system in line with the installed version. |
| `zanken-niri-keybindings` | Display niri keybindings from config.kdl using fzf or stdout |
| `zanken-niri-launch-or-focus` | Launch an app or focus an existing Niri window matching a pattern |
| `zanken-notification-battery` | Show the current battery status notification |
| `zanken-notification-dismiss` | Dismiss a mako notification on the basis of its summary. Used by the first-run notifications to dismiss them after clicking for action. |
| `zanken-notification-send` | Send a desktop notification with Zanken glyph and body spacing |
| `zanken-notification-time` | Show the current time and date notification |
| `zanken-notification-weather` | Show the current weather notification |
| `zanken-npm-install` | Install a pnpm dlx wrapper for a given npm package. |
| `zanken-pkg-add` | Install Arch packages if they are missing |
| `zanken-pkg-aur-accessible` | Returns true if the AUR is up and available. |
| `zanken-pkg-aur-add` | Add the named packages to the system from the AUR if they're missing. Returns false if it couldn't be done. |
| `zanken-pkg-aur-install` | Show a fuzzy-finder TUI for picking new AUR packages to install. |
| `zanken-pkg-drop` | Remove all the named packages from the system if they're installed (otherwise ignore). |
| `zanken-pkg-install` | Show a fuzzy-finder TUI for picking new Arch and OPR packages to install. |
| `zanken-pkg-missing` | Returns true if any of the named packages are missing from the system (or false if they're all there). |
| `zanken-pkg-present` | Returns true if all of the named packages are installed on the system (or false if any of them are missing). |
| `zanken-pkg-remove` | Show a fuzzy-finder TUI for picking packages installed on the system to be removed. |
| `zanken-plymouth-preview` | Preview a Plymouth boot screen with custom colors and logo |
| `zanken-plymouth-reset` | Restore the default Zanken Plymouth boot theme and SDDM login screen |
| `zanken-plymouth-set` | Set the Plymouth boot theme colors and logo |
| `zanken-plymouth-set-by-theme` | Set the Plymouth boot theme from an Zanken theme |
| `zanken-powerprofiles-init` | Set the correct power profile on boot based on current AC/battery state. |
| `zanken-powerprofiles-list` | Returns a list of all the available power profiles on the system. |
| `zanken-powerprofiles-set` | Set the power profile to the requested level, falling back to balanced |
| `zanken-refresh-applications` | Ensure all default .desktop, web apps, TUIs, and npm wrappers are installed. |
| `zanken-refresh-chromium` | Refresh the ~/.config/chromium-flags.conf file from the Zanken defaults. |
| `zanken-refresh-config` | Copies the named config from ~/zanken/config/X/Y/Z -> ~/.config/X/Y/Z. |
| `zanken-refresh-fastfetch` | Overwrite the user config for fastfetch with the Zanken default. |
| `zanken-refresh-limine` | Overwrite the user config for the Limine bootloader and rebuild it. |
| `zanken-refresh-pacman` | Update packages using the current pacman configuration |
| `zanken-refresh-plymouth` | Overwrite the user config for the Plymouth drive decryption and boot sequence with the Zanken default and rebuild it. |
| `zanken-refresh-sddm` | Refresh the SDDM theme from default |
| `zanken-refresh-swayosd` | Overwrite the user configs for swayosd (controls on-screen feedback for changing volume/songs etc) with the Zanken defaults and restart the service. |
| `zanken-refresh-tmux` | Overwrite the user tmux config with the Zanken default and reload tmux. |
| `zanken-reinstall` | Reinstall Zanken packages and reset default configs |
| `zanken-reinstall-configs` | Reset all Zanken user configs to the defaults |
| `zanken-reinstall-git` | Reinstall the stable Zanken source directory from git |
| `zanken-reinstall-pkgs` | Install all default Zanken packages |
| `zanken-reminder` | Set and show lightweight desktop notification reminders |
| `zanken-reminder-set` | Set a reminder via fzf (no walker required) |
| `zanken-remove-browser` | Remove a supported browser and clean up Zanken browser defaults |
| `zanken-remove-dev-env` | Remove a development environment that was previously installed via zanken-install-dev-env. |
| `zanken-remove-gaming-geforce-now` | Remove the GeForce NOW Flatpak app and its data. |
| `zanken-remove-gaming-heroic` | Remove Heroic Games Launcher and its game libraries, configs, and caches. |
| `zanken-remove-gaming-lutris` | Remove Lutris, Wine, umu-launcher, and all their configs and caches. |
| `zanken-remove-gaming-minecraft` | Remove the Minecraft launcher along with its worlds, mods, and caches. |
| `zanken-remove-gaming-moonlight` | Remove Moonlight and its configs and caches. |
| `zanken-remove-gaming-retroarch` | Remove RetroArch, all libretro cores, and its config/saves. Leaves ~/Games/roms and ~/Games/bios alone. |
| `zanken-remove-gaming-steam` | Remove Steam and all of its game libraries, configs, and caches. |
| `zanken-remove-gaming-xbox-cloud` | Remove the Xbox Cloud Gaming web app. |
| `zanken-remove-gaming-xbox-controllers` | Remove the xpadneo Xbox controller driver and undo its module/blacklist config. |
| `zanken-remove-preinstalls` | Remove preinstalled Zanken applications (web apps, TUIs, and selected packages). |
| `zanken-remove-security-fido2` | Remove FIDO2 authentication from sudo and polkit |
| `zanken-remove-security-fingerprint` | Remove fingerprint authentication from sudo and polkit |
| `zanken-remove-service-sunshine` | Remove Sunshine and close Zanken-managed Moonlight streaming ports. |
| `zanken-restart-app` | Restart an application |
| `zanken-restart-bluetooth` | Unblock and restart the bluetooth service. |
| `zanken-restart-btop` | Reload btop configuration (used by the Zanken theme switching). |
| `zanken-restart-helix` | Reload Helix configuration |
| `zanken-restart-opencode` | Reload opencode configuration (used by the Zanken theme switching). |
| `zanken-restart-pipewire` | Restart the PipeWire audio service to fix audio issues or apply new configuration. |
| `zanken-restart-quickshell` | Restart the Quickshell desktop |
| `zanken-restart-swayosd` | Restart the SwayOSD server |
| `zanken-restart-terminal` | Reload supported terminal emulators after config changes |
| `zanken-restart-tmux` | Restart tmux if running with the latest configuration |
| `zanken-restart-trackpad` | Reset the trackpad by unbinding and rebinding its driver. |
| `zanken-restart-wifi` | Unblock and restart the Wi-Fi service. |
| `zanken-restart-xcompose` | Restart the XCompose input method service (fcitx5) to apply new compose key settings. |
| `zanken-setup-dns` | Configure the system DNS provider |
| `zanken-setup-security-fido2` | Set up FIDO2 authentication for sudo and polkit |
| `zanken-setup-security-fingerprint` | Set up fingerprint authentication for sudo and polkit |
| `zanken-menu-share` | Share clipboard, files, or folders with LocalSend |
| `zanken-show-done` | Display a "Done!" message with a spinner and wait for user to press any key. |
| `zanken-show-logo` | Display the Zanken logo in the terminal using green color. |
| `zanken-snapshot` | Create or restore system snapshots with snapper |
| `zanken-style-corners` | Set corners to sharp or round |
| `zanken-qylock-theme-set` | Set the qylock lockscreen and SDDM theme |
| `zanken-sudo-keepalive` | Prompt for sudo once and keep the credential alive in the background. |
| `zanken-sudo-passwordless` | Toggle passwordless sudo for the current user. |
| `zanken-sudo-reset` | Reset the sudo lockout/faillock for the current user. |
| `zanken-swayosd-brightness` | Display brightness level using SwayOSD on the current monitor. |
| `zanken-swayosd-client` | Wrapper for swayosd-client that targets the currently focused monitor. |
| `zanken-swayosd-kbd-brightness` | Display keyboard brightness level using SwayOSD on the current monitor. |
| `zanken-system-lock` | Lock the computer and turn off the display |
| `zanken-system-logout` | Log out after closing application windows |
| `zanken-system-reboot` | Reboot after closing application windows |
| `zanken-system-shutdown` | Shut down after closing application windows |
| `zanken-system-wake` | Wake displays and restore brightness after idle |
| `zanken-theme-bg-cache` | Cache background switcher thumbnails for the current theme |
| `zanken-theme-bg-colors-apply` | Apply a wallpaper-extracted accent color to niri, GTK, and quickshell |
| `zanken-theme-bg-install` | Open the current theme's user background folder |
| `zanken-theme-bg-next` | Cycle to the next background for the current theme |
| `zanken-theme-bg-set` | Set the current background image |
| `zanken-theme-bg-switcher` | Open the Zanken background switcher |
| `zanken-theme-current` | Show current theme |
| `zanken-theme-install` | Install a theme from a git repository |
| `zanken-theme-list` | List available themes |
| `zanken-theme-refresh` | Refresh the current theme from its templates. |
| `zanken-theme-remove` | Remove a user-installed theme |
| `zanken-theme-set` | Apply an Zanken theme |
| `zanken-theme-switcher` | Open the Zanken theme switcher |
| `zanken-theme-update` | Update user-installed git themes |
| `zanken-theme-videobg-switcher` | Open video wallpaper picker |
| `zanken-theme-we-set` | Apply a Wallpaper Engine wallpaper |
| `zanken-theme-we-switcher` | Open the Wallpaper Engine wallpaper picker |
| `zanken-toggle` | Toggle Zanken features between enabled and disabled |
| `zanken-toggle-enabled` | Check if a toggle is enabled (flag file exists) |
| `zanken-toggle-hybrid-gpu` | Toggle dedicated vs integrated GPU mode via supergfxd (for hybrid gpu laptops, like Asus G14). |
| `zanken-toggle-idle` | Toggle hypridle idle locking |
| `zanken-toggle-nightlight` | Toggle nightlight screen temperature on Niri |
| `zanken-toggle-screensaver` | Toggle screensaver availability |
| `zanken-toggle-suspend` | Toggle suspend availability in the system menu |
| `zanken-toggle-touchpad` | Enable, disable, or toggle the Niri touchpad |
| `zanken-transcode` | Transcode pictures and videos for sharing |
| `zanken-transcode-ascii` | Transcode an image into ASCII/Unicode art text |
| `zanken-tui-install` | Create a desktop launcher for a terminal UI app |
| `zanken-tui-remove` | Remove terminal UI desktop launchers |
| `zanken-tui-remove-all` | Remove all TUIs installed via zanken-tui-install. |
| `zanken-tz-select` | Select and set the system timezone |
| `zanken-update` | Update the Zanken repository |
| `zanken-update-analyze-logs` | Check the update log for known failure conditions |
| `zanken-update-aur-pkgs` | Update AUR packages if any are installed |
| `zanken-update-available-reset` | Clear the available-update indicator state |
| `zanken-update-confirm` | Prompt for confirmation before starting an update |
| `zanken-update-firmware` | Update system firmware using fwupd. Ensures the fwupd EFI binary is installed |
| `zanken-update-keyring` | Update Arch Linux signing keys |
| `zanken-update-orphan-pkgs` | Remove orphaned system packages after updates |
| `zanken-update-perform` | Run the full Zanken update pipeline |
| `zanken-update-qylock` | Update qylock from its upstream repository |
| `zanken-update-restart` | Prompt for required reboot or service restarts after updates |
| `zanken-zanken-sync` | Sync zanken shell with remote |
| `zanken-update-system-pkgs` | Update system packages with pacman |
| `zanken-update-time` | Restart system time synchronization |
| `zanken-version` | Print the installed Zanken version |
| `zanken-version-branch` | Print the current Zanken git branch |
| `zanken-version-channel` | Print the active Zanken git release channel |
| `zanken-version-pkgs` | Print when system packages were last upgraded |
| `zanken-voxtype-config` | Open the Voxtype configuration file |
| `zanken-voxtype-install` | Install and configure Voxtype dictation |
| `zanken-voxtype-model` | Open Voxtype AI model setup |
| `zanken-voxtype-remove` | Remove Voxtype dictation and its configuration |
| `zanken-voxtype-status` | Clean up the Voxtype status child process |
| `zanken-wallpaper-colors` | Extract the most vibrant accent color from a wallpaper image |
| `zanken-wallpaper-engine-picker` | Scan WE library and open grid picker |
| `zanken-wallpaper-start` | Start the correct wallpaper renderer based on current background type |
| `zanken-weather-icon` | Returns a weather condition icon, adjusted for live sunrise and sunset. |
| `zanken-weather-status` | Returns a formatted weather status string with temperature and wind speed. |
| `zanken-webapp-handler-hey` | Open HEY webmail and translate mailto links |
| `zanken-webapp-handler-zoom` | Open Zoom web meetings from browser protocol links |
| `zanken-webapp-install` | Create a desktop launcher for a web app |
| `zanken-webapp-remove` | Remove web app desktop launchers |
| `zanken-webapp-remove-all` | Remove all web apps installed via zanken-webapp-install. |
| `zanken-welcome` | Show the Zanken welcome tour |
| `zanken-wifi-powersave` | Set Wi-Fi power save mode on wireless interfaces |
