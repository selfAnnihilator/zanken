#!/bin/bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMPDIR=""

pass() {
  printf 'ok - %s\n' "$1"
}

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

cleanup() {
  [[ -n $TMPDIR && -d $TMPDIR ]] && rm -rf "$TMPDIR"
}
trap cleanup EXIT

assert_file_contains() {
  local description="$1"
  local file="$2"
  local expected="$3"

  grep -Fqx "$expected" "$file" || fail "$description"
  pass "$description"
}

assert_command() {
  local command="$1"
  [[ -x $ROOT/bin/$command ]] || fail "command is executable: $command"
  pass "command is executable: $command"
}

TMPDIR=$(mktemp -d)
work_tree="$TMPDIR/home"
NIRI_CONFIG="$work_tree/.config/niri/config.kdl"

mkdir -p "$work_tree"
ln -s "$ROOT" "$work_tree/zanken"

HOME="$work_tree" \
  ZANKEN_PATH="$work_tree/zanken" \
  "$ROOT/bin/zanken-config-desktop" adopt

assert_file_contains "Niri entry point includes managed Zanken defaults" "$NIRI_CONFIG" "include \"$work_tree/.local/share/zanken/desktop/niri/config.kdl\""
[[ -L $work_tree/.config/quickshell/zanken ]] || fail "Quickshell entry point is a managed Zanken link"
[[ $(readlink "$work_tree/.config/quickshell/zanken") == "$work_tree/.local/share/zanken/desktop/quickshell" ]] || fail "Quickshell entry point targets managed Zanken defaults"
[[ -f $work_tree/.config/zanken/niri.kdl ]] || fail "desktop adoption creates a local Niri override"
[[ -f $work_tree/.config/zanken/settings.json ]] || fail "desktop adoption creates local Zanken settings"
rg -q '^run_logged \$ZANKEN_INSTALL/config/desktop\.sh$' "$ROOT/install/config/all.sh" || fail "managed desktop stage is wired into installer"
[[ ! -e $ROOT/install/config/dotfiles.sh ]] || fail "installer does not depend on a separate dotfiles repository"
pass "installer adopts self-contained managed desktop defaults"

legacy_hook="$work_tree/.config/zanken/hooks/post-boot.d/quickshell-desktop"
mkdir -p "$(dirname "$legacy_hook")"
printf '%s\n' '#!/bin/bash' 'qs -n -d -c desktop' >"$legacy_hook"
HOME="$work_tree" ZANKEN_PATH="$work_tree/zanken" \
  bash "$ROOT/migrations/1784442589_remove_legacy_quickshell_hook.sh"
[[ ! -e $legacy_hook ]] || fail "legacy Quickshell post-boot hook is disabled"
[[ -f $work_tree/.config/zanken/hooks/post-boot.d/disabled/quickshell-desktop ]] || fail "legacy Quickshell hook is preserved outside the hook runner"
pass "managed desktop migration prevents duplicate Quickshell bars"

mkdir -p "$work_tree/.config/zanken/current/theme"
printf '%s\n' 'color1 = "#123456"' >"$work_tree/.config/zanken/current/theme/colors.toml"
HOME="$work_tree" ZANKEN_PATH="$work_tree/zanken" "$ROOT/bin/zanken-config-desktop" sync
assert_file_contains "desktop sync preserves the wallpaper-derived Niri accent" \
  "$work_tree/.local/share/zanken/desktop/niri/config.kdl" '        active-color "#123456"'

conflict_home="$TMPDIR/conflict-home"
mkdir -p "$conflict_home/.config/niri"
printf '%s\n' '// existing user configuration' >"$conflict_home/.config/niri/config.kdl"
if HOME="$conflict_home" ZANKEN_PATH="$ROOT" "$ROOT/bin/zanken-config-desktop" adopt >/dev/null 2>&1; then
  fail "desktop adoption requires confirmation before replacing a config"
fi
assert_file_contains "desktop adoption preserves an unapproved Niri config" "$conflict_home/.config/niri/config.kdl" "// existing user configuration"

HOME="$work_tree" ZANKEN_PATH="$work_tree/zanken" "$ROOT/bin/zanken-config-desktop" sync
HOME="$work_tree" ZANKEN_PATH="$work_tree/zanken" "$ROOT/bin/zanken-config-desktop" rollback
niri validate --config "$NIRI_CONFIG" >/dev/null
pass "managed desktop defaults can roll back safely"

rg -Fq 'QsMenuOpener {' "$ROOT/default/desktop/quickshell/TrayPopup.qml" || fail "tray context menus use the Zanken renderer"
rg -Fq 'menuEntry.trigger();' "$ROOT/default/desktop/quickshell/TrayPopup.qml" || fail "tray context menu actions trigger their provider entries"
if rg -q 'item\.display\(' "$ROOT/default/desktop/quickshell/TrayPopup.qml"; then
  fail "tray context menus do not use the unthemed platform menu"
fi
pass "tray context menus use the Zanken theme"

HOME="$work_tree" ZANKEN_PATH="$work_tree/zanken" "$ROOT/bin/zanken-refresh-config" uwsm/env
cmp -s "$ROOT/config/uwsm/env" "$work_tree/.config/uwsm/env" || fail "refresh config uses the Zanken checkout"
pass "refresh config uses the Zanken checkout"

HOME="$work_tree" ZANKEN_PATH="$work_tree/zanken" \
  bash --noprofile --rcfile "$ROOT/default/bashrc" -ic '[[ $ZANKEN_PATH == "$HOME/zanken" ]]' >/dev/null 2>&1 || fail "interactive Bash uses the Zanken checkout"
pass "interactive Bash uses the Zanken checkout"

rg -Fq 'include=~/.local/state/zanken/toggles/mako.ini' "$ROOT/default/themed/mako.ini.tpl" || fail "Mako toggle include uses Zanken state"
if rg -q '\.local/state/omarchy' "$ROOT/default/themed/mako.ini.tpl"; then
  fail "Mako template does not use retired Omarchy state"
fi
rg -Fq 'touch ~/.local/state/zanken/toggles/mako.ini' "$ROOT/install/config/toggles.sh" || fail "installer creates the Mako toggle include"
pass "Mako toggle include uses Zanken state"

rg -Fq 'touch ~/.local/state/zanken/first-run.mode' "$ROOT/install/preflight/first-run-mode.sh" || fail "installer creates the Zanken first-run marker"
rg -Fq 'zanken-welcome' "$ROOT/install/first-run/welcome.sh" || fail "first run opens the Zanken welcome tour"
pass "first run uses the Zanken state and welcome tour"

rg -Fq 'complete -o default -F _zanken_complete zanken' "$ROOT/default/bash/completions" || fail "Bash completion targets Zanken"
if rg -q 'complete -o default -F _omarchy_complete omarchy' "$ROOT/default/bash/completions"; then
  fail "Bash completion does not target retired Omarchy command"
fi
pass "Bash completion targets Zanken"

rg -Fq '.config/zanken/current' "$ROOT/default/pi/agent/extensions/zanken-system-theme.ts" || fail "Pi theme extension reads Zanken state"
if rg -q 'setInterval' "$ROOT/default/pi/agent/extensions/zanken-system-theme.ts"; then
  fail "Pi theme extension does not poll for theme changes"
fi
rg -Fq 'zanken-system-theme.ts' "$ROOT/install/config/pi.sh" || fail "installer installs the Zanken Pi extension"
pass "Pi theme extension follows Zanken state without polling"

[[ -f $NIRI_CONFIG ]] || fail "Niri config exists: $NIRI_CONFIG"
command -v niri >/dev/null || fail "niri is installed"
niri validate --config "$NIRI_CONFIG" >/dev/null
pass "Niri config validates"

if rg -q '/home/[A-Za-z0-9_.-]+|eDP-[0-9]+|com\.jarvis' "$ROOT/default/desktop"; then
  fail "managed desktop defaults do not contain machine-specific paths or devices"
fi
pass "managed desktop defaults are portable"

rg -Fq 'Mod+Shift+Space { spawn "zanken-restart-quickshell"; }' "$ROOT/default/desktop/niri/config.kdl" || fail "Quickshell restart hotkey uses Mod+Shift+Space"
pass "Quickshell restart hotkey uses Mod+Shift+Space"

rg -Fq 'Mod+B { spawn "zanken-launch-browser" "--quick"; }' "$ROOT/default/desktop/niri/config.kdl" || fail "quick-browser hotkey uses the configurable Zanken launcher"
rg -Fq 'Mod+Shift+B { spawn "zanken-launch-browser"; }' "$ROOT/default/desktop/niri/config.kdl" || fail "preferred-browser hotkey uses the Zanken browser launcher"
pass "browser hotkeys use their configurable Zanken launchers"

rg -Fq 'Mod+Ctrl+Print { spawn "zanken-capture-text-extraction"; }' "$ROOT/default/desktop/niri/config.kdl" || fail "text extraction uses the Mod+Ctrl+Print hotkey"
pass "text extraction uses the Mod+Ctrl+Print hotkey"

rg -Fq 'readonly property bool hasTrackTimeline: Number.isFinite(trackLen) && trackLen >= 1' "$ROOT/default/desktop/quickshell/MusicPopup.qml" || fail "music progress waits for a valid MPRIS timeline"
rg -Fq 'property real displayRatio: Number.isFinite(rawRatio) ? Math.max(0, Math.min(1, rawRatio)) : 0' "$ROOT/default/desktop/quickshell/MusicPopup.qml" || fail "music progress clamps transient MPRIS ratios"
pass "music progress stays within its popup during transient MPRIS timelines"

rg -Fq 'actionsSupported: true' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "notification server advertises notification actions"
rg -Fq 'inlineReplySupported: true' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "notification server advertises inline replies"
rg -Fq 'function invokeDefaultNotificationAction(notification)' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "notification default actions can be invoked"
rg -Fq 'function sendNotificationReply(notification, replyText)' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "notification inline replies can be sent"
rg -Fq 'root.notificationActions(notification)' "$ROOT/default/desktop/quickshell/NotificationsPopup.qml" || fail "notification panel renders sender-provided actions"
rg -Fq 'root.sendNotificationReply(notification, replyInput.text)' "$ROOT/default/desktop/quickshell/NotificationsPopup.qml" || fail "notification panel submits inline replies"
rg -Fq 'function notificationGroups()' "$ROOT/default/desktop/quickshell/NotificationsPopup.qml" || fail "notification panel groups updates by source"
rg -Fq 'function relativeTime(timestamp)' "$ROOT/default/desktop/quickshell/NotificationsPopup.qml" || fail "notification panel uses compact timestamps"
rg -Fq 'function setSourceCollapsed(key, collapsed)' "$ROOT/default/desktop/quickshell/NotificationsPopup.qml" || fail "notification panel can collapse a source group"
rg -Fq 'root.notificationDefaultAction(notification)' "$ROOT/default/desktop/quickshell/NotificationsPopup.qml" || fail "notification panel promotes real default actions"
rg -Fq 'toastPanel.root.invokeDefaultNotificationAction(notif)' "$ROOT/default/desktop/quickshell/NotificationToast.qml" || fail "notification toasts invoke default actions"
rg -Fxq 'import Quickshell.Io' "$ROOT/default/desktop/quickshell/shell.qml" || fail "Quickshell restart IPC imports its handler type"
pass "notification triage, actions, replies, and default opens are wired to their sender"

rg -Fq 'text: "CONNECTED"' "$ROOT/default/desktop/quickshell/BluetoothPopup.qml" || fail "Bluetooth panel separates connected devices"
rg -Fq 'text: "SAVED DEVICES"' "$ROOT/default/desktop/quickshell/BluetoothPopup.qml" || fail "Bluetooth panel separates saved devices"
rg -Fq 'text: "DISCOVERING…"' "$ROOT/default/desktop/quickshell/BluetoothPopup.qml" || fail "Bluetooth panel shows a discovery state while scanning"
rg -Fq 'text: "DISCOVER DEVICES"' "$ROOT/default/desktop/quickshell/BluetoothPopup.qml" || fail "Bluetooth panel gives its empty state a primary discovery action"
rg -Fq 'Scan for headphones, controllers, keyboards, and nearby devices.' "$ROOT/default/desktop/quickshell/BluetoothPopup.qml" || fail "Bluetooth panel explains what discovery finds"
rg -Fq 'function btPairAndConnect(mac)' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "Bluetooth panel pairs before connecting new devices"
rg -Fq 'target: "bluetooth"' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "Bluetooth panel can be opened through Quickshell IPC"
pass "Bluetooth panel groups device states and pairs new devices before connecting"

rg -Fq 'property bool detailsExpanded: false' "$ROOT/default/desktop/quickshell/WifiPopup.qml" || fail "Wi-Fi panel can reveal active connection details"
rg -Fq 'text: "CONNECTED"' "$ROOT/default/desktop/quickshell/WifiPopup.qml" || fail "Wi-Fi panel presents one dedicated connected-network state"
rg -Fq 'text: "SAVED NEARBY"' "$ROOT/default/desktop/quickshell/WifiPopup.qml" || fail "Wi-Fi panel separates saved nearby networks"
rg -Fq '"NEARBY · SCANNING…" : "NEARBY"' "$ROOT/default/desktop/quickshell/WifiPopup.qml" || fail "Wi-Fi panel separates new nearby networks"
rg -Fq 'function refreshWifiDetails()' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "Wi-Fi panel can read active connection diagnostics"
rg -Fq 'target: "wifi"' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "Wi-Fi panel can be opened through Quickshell IPC"
pass "Wi-Fi panel keeps the connected network singular and diagnostics on demand"

rg -Fq 'readonly property string icoCharging: String.fromCodePoint(0xf0084)' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "battery telemetry defines a charging glyph"
rg -Fq 'return root.batPower >= 0.05 ? root.icoCharging : root.icoPlug;' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "battery telemetry uses the charging glyph while gaining charge"
rg -Fq 'if (root.batState === "Full" || root.batState === "Not charging") return root.icoPlug;' "$ROOT/default/desktop/quickshell/Navbar.qml" || fail "battery telemetry uses the plug glyph when charging has stopped"
pass "battery telemetry distinguishes charging from plugged in"

nvidia_config="$TMPDIR/nvidia-config.kdl"
printf '%s\n' \
  'environment {' \
  '  NVD_BACKEND "direct"' \
  '  LIBVA_DRIVER_NAME "nvidia"' \
  '  __GLX_VENDOR_LIBRARY_NAME "nvidia"' \
  '}' >"$nvidia_config"
niri validate --config "$nvidia_config" >/dev/null
pass "Niri validates NVIDIA environment settings"

rg -q 'NIRI_CONFIG=' "$ROOT/install/config/hardware/nvidia.sh" || fail "NVIDIA installer targets Niri config"
if rg -q '\.config/hypr' "$ROOT/install/config/hardware/nvidia.sh"; then
  fail "NVIDIA installer does not write Hyprland config"
fi
pass "NVIDIA installer writes Niri config"

for command in \
  zanken \
  zanken-capture-screenshot \
  zanken-capture-screenrecording \
  zanken-capture-text-extraction \
  zanken-capture-colorpicker \
  zanken-niri-window-close-all \
  zanken-restart-quickshell \
  zanken-config-desktop \
  zanken-default-quick-browser \
  zanken-welcome; do
  assert_command "$command"
done

PATH="$ROOT/bin:$PATH" "$ROOT/bin/zanken" commands --check >/dev/null
pass "Zanken command metadata is complete"

desktop_file="$ROOT/default/wayland-sessions/zanken.desktop"
desktop-file-validate "$desktop_file"
assert_file_contains "SDDM session launches Niri" "$desktop_file" "Exec=niri-session"
assert_file_contains "SDDM session checks for Niri" "$desktop_file" "TryExec=niri"

rg -q '^xdg-desktop-portal-gnome$' "$ROOT/install/zanken-base.packages" || fail "GNOME portal is installed"
rg -Uq 'local target="portal"\n[[:space:]]*capture_args=\(-w portal\)' "$ROOT/bin/zanken-capture-screenrecording" || fail "Niri recording selects the portal backend"
pass "Niri recording selects the GNOME portal backend"

rg -q '^STATE_FILE=' "$ROOT/bin/zanken-capture-screenrecording" || fail "recording state file is configured"
rg -q 'write_recording_state "\$pid"' "$ROOT/bin/zanken-capture-screenrecording" || fail "recording publishes active state"
rg -q 'clear_recording_state' "$ROOT/bin/zanken-capture-screenrecording" || fail "recording clears active state"
pass "recording state is exposed to Quickshell"

rg -Fq 'pid=$(recording_pid)' "$ROOT/bin/zanken-capture-screenrecording" || fail "recording stop reads its own process state"
if rg -q '(p|k)grep.*gpu-screen-recorder' "$ROOT/bin/zanken-capture-screenrecording"; then
  fail "recording stop does not target unrelated recorders"
fi
pass "recording stop is scoped to the Zanken recorder"

rg -q 'pacman -Syu --noconfirm' "$ROOT/bin/zanken-update-system-pkgs" || fail "updates use a single package database refresh"
if rg -q 'pacman -Syyu' "$ROOT/bin/zanken-update-system-pkgs"; then
  fail "updates do not force a second package database refresh"
fi
pass "updates avoid redundant package database refreshes"

rg -q '^zanken-update-qylock || true$' "$ROOT/bin/zanken-update-perform" || fail "full updates include the qylock updater"
rg -Fq 'git -C "$QYLOCK_DIR" pull --ff-only' "$ROOT/bin/zanken-update-qylock" || fail "qylock updater pulls from its upstream checkout"
pass "full updates include the upstream qylock updater"

rg -Fq 'battery_info=$(upower -i' "$ROOT/bin/zanken-battery-monitor" || fail "battery monitor reads battery details once"
if rg -q 'zanken-battery-remaining' "$ROOT/bin/zanken-battery-monitor"; then
  fail "battery monitor does not repeat the battery query"
fi
pass "battery monitor avoids duplicate power queries"

if rg -n '^# zanken:(summary|examples)=.*\bomarchy\b' "$ROOT/bin"; then
  fail "command metadata uses the Zanken command and branding"
fi
pass "command metadata uses Zanken branding"

for command in \
  zanken-launch-walker \
  zanken-refresh-walker \
  zanken-restart-walker \
  zanken-style-corners-walker \
  zanken-refresh-waybar \
  zanken-style-waybar-position; do
  rg -q '^# zanken:hidden=true$' "$ROOT/bin/$command" || fail "deprecated command is hidden: $command"
done
pass "deprecated Walker and Waybar commands are hidden"

printf 'all Zanken/Niri smoke tests passed\n'
