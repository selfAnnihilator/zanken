#!/bin/bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_TMPDIR=$(mktemp -d)

pass() {
  printf 'ok - %s\n' "$1"
}

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

cleanup() {
  rm -rf "$TEST_TMPDIR"
}
trap cleanup EXIT

power_rules=(
  "$ROOT/install/config/powerprofilesctl-rules.sh"
  "$ROOT/install/config/wifi-powersave-rules.sh"
)

for rules_file in "${power_rules[@]}"; do
  rg -Fq 'sudo install -d -o root -g root -m 0755 /usr/lib/zanken' "$rules_file" || fail "power helpers use a root-owned directory"
  if rg -q '\$HOME|/home/' "$rules_file"; then
    fail "udev rules do not execute helpers from a user-writable path"
  fi
done
rg -Fq '/usr/lib/zanken/zanken-powerprofiles-set' "${power_rules[0]}" || fail "power profile rule uses its installed helper"
rg -Fq '/usr/lib/zanken/zanken-wifi-powersave' "${power_rules[1]}" || fail "Wi-Fi power-save rule uses its installed helper"
migration="$ROOT/migrations/1787061512.sh"
rg -Fq 'source "$OMARCHY_PATH/install/config/powerprofilesctl-rules.sh"' "$migration" || fail "existing installs migrate the power profile rule"
rg -Fq 'source "$OMARCHY_PATH/install/config/wifi-powersave-rules.sh"' "$migration" || fail "existing installs migrate the Wi-Fi power-save rule"
pass "udev power events execute only root-owned helper copies"

sudoers_source="$ROOT/install/preflight/first-run-mode.sh"
if rg -q 'NOPASSWD: /usr/bin/systemctl([[:space:]]|$)' "$sudoers_source"; then
  fail "first-run does not grant unrestricted systemctl"
fi
rg -Fq 'Cmnd_Alias FIRST_RUN_ENABLE_UFW = /usr/bin/systemctl enable ufw' "$sudoers_source" || fail "first-run systemctl access is argument-scoped"
rg -Fq 'Cmnd_Alias FIRST_RUN_CLEANUP = /usr/bin/rm -f /etc/sudoers.d/first-run' "$sudoers_source" || fail "first-run cleanup uses the canonical rm path"
rg -Fq 'Cmnd_Alias FIRST_RUN_REBOOT_CLEANUP = /usr/bin/rm -f /etc/sudoers.d/99-zanken-installer-reboot' "$sudoers_source" || fail "first-run can remove the installer reboot grant"
rg -Fq 'sudo /usr/bin/rm -f /etc/sudoers.d/99-zanken-installer-reboot' "$ROOT/install/first-run/cleanup-reboot-sudoers.sh" || fail "reboot grant cleanup uses its exact permitted command"
if rg -q 'sudo test' "$ROOT/install/first-run/cleanup-reboot-sudoers.sh"; then
  fail "reboot grant cleanup does not require ungranted sudo test access"
fi
rg -Fq 'trap cleanup_first_run_privileges EXIT' "$ROOT/bin/zanken-first-run" || fail "first-run registers failure-safe privilege cleanup"
cleanup_line=$(rg -n 'sudo /usr/bin/rm -f /etc/sudoers.d/first-run' "$ROOT/bin/zanken-first-run" | tail -1 | cut -d: -f1)
marker_line=$(rg -n -F 'rm -f "$FIRST_RUN_MODE"' "$ROOT/bin/zanken-first-run" | tail -1 | cut -d: -f1)
(( cleanup_line < marker_line )) || fail "first-run removes privileges before its retry marker"

first_run_bin="$TEST_TMPDIR/first-run-bin"
first_run_home="$TEST_TMPDIR/first-run-home"
sudo_log="$TEST_TMPDIR/sudo.log"
mkdir -p "$first_run_bin" "$first_run_home/.local/state/zanken"
printf '%s\n' '#!/bin/bash' 'printf "%s\n" "$*" >>"$SUDO_LOG"' >"$first_run_bin/sudo"
printf '%s\n' '#!/bin/bash' 'exit "${FAKE_BASH_STATUS:-0}"' >"$first_run_bin/bash"
printf '%s\n' '#!/bin/bash' 'exit 0' >"$first_run_bin/zanken-hook-install"
chmod +x "$first_run_bin/sudo" "$first_run_bin/bash" "$first_run_bin/zanken-hook-install"
export SUDO_LOG="$sudo_log"

HOME="$first_run_home" USER=tester PATH="$first_run_bin:$PATH" /bin/bash "$sudoers_source"
touch "$first_run_home/.local/state/zanken/first-run.mode"
if HOME="$first_run_home" ZANKEN_PATH="$ROOT" PATH="$first_run_bin:$PATH" FAKE_BASH_STATUS=1 \
  /bin/bash "$ROOT/bin/zanken-first-run" >/dev/null 2>&1; then
  fail "failed first-run work remains retryable"
fi
[[ -f $first_run_home/.local/state/zanken/first-run.mode ]] || fail "failed first-run keeps its retry marker"
rg -Fxq '/usr/bin/rm -f /etc/sudoers.d/first-run' "$sudo_log" || fail "failed first-run attempts privilege cleanup"

: >"$sudo_log"
HOME="$first_run_home" ZANKEN_PATH="$ROOT" PATH="$first_run_bin:$PATH" FAKE_BASH_STATUS=0 \
  /bin/bash "$ROOT/bin/zanken-first-run"
[[ ! -e $first_run_home/.local/state/zanken/first-run.mode ]] || fail "successful first-run clears its retry marker"
rg -Fxq '/usr/bin/rm -f /etc/sudoers.d/first-run' "$sudo_log" || fail "successful first-run removes its privilege file"
pass "first-run privileges are narrow and failure-safe"

navbar="$ROOT/default/desktop/quickshell/Navbar.qml"
rg -Fq 'const command = ["nmcli", "device", "wifi", "connect", ssid];' "$navbar" || fail "Wi-Fi connect uses direct argv"
rg -Fq 'wifiForgetProc.command = ["nmcli", "connection", "delete", ssid];' "$navbar" || fail "Wi-Fi forget uses direct argv"
if rg -q 'safeSsid|safePass' "$navbar"; then
  fail "Wi-Fi credentials are not manually shell-escaped"
fi
pass "Wi-Fi metadata remains literal argv data"

fake_bin="$TEST_TMPDIR/bin"
test_home="$TEST_TMPDIR/home"
qmk_log="$TEST_TMPDIR/qmk.log"
asus_log="$TEST_TMPDIR/asus.log"
mkdir -p "$fake_bin" "$test_home/.config/zanken/current/theme"

printf '%s\n' '#!/bin/bash' 'printf "%s\n" "$*" >>"$QMK_LOG"' >"$fake_bin/qmk_hid"
printf '%s\n' '#!/bin/bash' 'printf "%s\n" "$*" >>"$ASUS_LOG"' >"$fake_bin/asusctl"
chmod +x "$fake_bin/qmk_hid" "$fake_bin/asusctl"
export QMK_LOG="$qmk_log" ASUS_LOG="$asus_log"

printf '%s\n' '#A1b2C3' >"$test_home/.config/zanken/current/theme/keyboard.rgb"
HOME="$test_home" PATH="$fake_bin:$ROOT/bin:$PATH" "$ROOT/bin/zanken-theme-set-keyboard-f16"
HOME="$test_home" PATH="$fake_bin:$ROOT/bin:$PATH" "$ROOT/bin/zanken-theme-set-keyboard-asus-rog"
rg -Fq 'via --save' "$qmk_log" || fail "valid RGB still reaches the Framework keyboard"
rg -Fxq 'aura effect static -c A1b2C3' "$asus_log" || fail "valid RGB remains one ASUS color argument"

qmk_lines=$(wc -l <"$qmk_log")
asus_lines=$(wc -l <"$asus_log")
marker="$TEST_TMPDIR/injected"
printf "%s\n" "ff00ff'); __import__('os').system('touch $marker'); #" >"$test_home/.config/zanken/current/theme/keyboard.rgb"
if HOME="$test_home" PATH="$fake_bin:$ROOT/bin:$PATH" "$ROOT/bin/zanken-theme-set-keyboard-f16" >/dev/null 2>&1; then
  fail "Framework keyboard rejects executable theme data"
fi
if HOME="$test_home" PATH="$fake_bin:$ROOT/bin:$PATH" "$ROOT/bin/zanken-theme-set-keyboard-asus-rog" >/dev/null 2>&1; then
  fail "ASUS keyboard rejects non-color theme data"
fi
[[ ! -e $marker ]] || fail "malicious theme data is not executed"
(( $(wc -l <"$qmk_log") == qmk_lines )) || fail "invalid theme data does not reach qmk_hid"
(( $(wc -l <"$asus_log") == asus_lines )) || fail "invalid theme data does not reach asusctl"
pass "keyboard theme colors are validated and passed as data"

printf 'all Zanken security regression tests passed\n'
