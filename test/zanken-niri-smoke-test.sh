#!/bin/bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
NIRI_CONFIG="${ZANKEN_NIRI_CONFIG:-$HOME/.config/niri/config.kdl}"
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
source_repo="$TMPDIR/dotfiles-source"
work_tree="$TMPDIR/home"
bare_repo="$TMPDIR/dotfiles.git"

git init -q -b main "$source_repo"
git -C "$source_repo" config user.name "Zanken smoke test"
git -C "$source_repo" config user.email "smoke@example.invalid"
mkdir -p "$source_repo/.config/niri" "$source_repo/.config/quickshell/desktop" "$work_tree"
printf '%s\n' '// managed by dotfiles' >"$source_repo/.config/niri/config.kdl"
printf '%s\n' '// managed by dotfiles' >"$source_repo/.config/quickshell/desktop/Bar.qml"
git -C "$source_repo" add .config
git -C "$source_repo" commit -qm "fixture"

HOME="$work_tree" \
  ZANKEN_DOTFILES_REPO="$source_repo" \
  ZANKEN_DOTFILES_DIR="$bare_repo" \
  ZANKEN_DOTFILES_BRANCH=main \
  bash "$ROOT/install/config/dotfiles.sh"

assert_file_contains "installer checks out Niri config from dotfiles" "$work_tree/.config/niri/config.kdl" "// managed by dotfiles"
assert_file_contains "installer checks out Quickshell config from dotfiles" "$work_tree/.config/quickshell/desktop/Bar.qml" "// managed by dotfiles"
rg -q '^run_logged \$OMARCHY_INSTALL/config/dotfiles\.sh$' "$ROOT/install/config/all.sh" || fail "dotfiles stage is wired into installer"
pass "dotfiles stage is wired into installer"

ln -s "$ROOT" "$work_tree/zanken"
HOME="$work_tree" ZANKEN_PATH="$work_tree/zanken" "$ROOT/bin/zanken-refresh-config" uwsm/env
cmp -s "$ROOT/config/uwsm/env" "$work_tree/.config/uwsm/env" || fail "refresh config uses the Zanken checkout"
pass "refresh config uses the Zanken checkout"

HOME="$work_tree" ZANKEN_PATH="$work_tree/zanken" \
  bash --noprofile --rcfile "$ROOT/default/bashrc" -ic '[[ $OMARCHY_PATH == "$HOME/zanken" ]]' >/dev/null 2>&1 || fail "interactive Bash uses the Zanken checkout"
pass "interactive Bash uses the Zanken checkout"

[[ -f $NIRI_CONFIG ]] || fail "Niri config exists: $NIRI_CONFIG"
command -v niri >/dev/null || fail "niri is installed"
niri validate --config "$NIRI_CONFIG" >/dev/null
pass "Niri config validates"

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
  zanken-restart-quickshell; do
  assert_command "$command"
done

PATH="$ROOT/bin:$PATH" "$ROOT/bin/zanken" commands --check >/dev/null
pass "Zanken command metadata is complete"

desktop_file="$ROOT/default/wayland-sessions/zanken.desktop"
desktop-file-validate "$desktop_file"
assert_file_contains "SDDM session launches Niri" "$desktop_file" "Exec=niri-session"
assert_file_contains "SDDM session checks for Niri" "$desktop_file" "TryExec=niri"

rg -q '^xdg-desktop-portal-gnome$' "$ROOT/install/omarchy-base.packages" || fail "GNOME portal is installed"
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

printf 'all Zanken/Niri smoke tests passed\n'
