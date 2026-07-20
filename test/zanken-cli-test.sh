#!/bin/bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CLI="$ROOT/bin/zanken"

pass() {
  printf 'ok - %s\n' "$1"
}

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

assert_output_contains() {
  local description="$1"
  local output="$2"
  local expected="$3"

  [[ $output == *"$expected"* ]] || fail "$description"
  pass "$description"
}

export PATH="$ROOT/bin:$PATH"

quick_browser_home=$(mktemp -d)
trap 'rm -rf "$quick_browser_home"' EXIT
HOME="$quick_browser_home" "$CLI" default quick browser qutebrowser
[[ $(HOME="$quick_browser_home" "$CLI" default quick browser) == "qutebrowser" ]] || fail "quick browser preference persists independently"
pass "quick browser preference persists independently"

"$CLI" commands --check >/dev/null
pass "command metadata and fast-path aliases are valid"

"$ROOT/bin/zanken-dev-generate-command-docs" --check
pass "generated command reference matches CLI metadata"

rg -Fq 'git -C "$ZANKEN_PATH" pull --ff-only' "$ROOT/bin/zanken-update" || fail "Zanken updates use fast-forward-only pulls"
rg -Fq 'zanken-config-desktop sync' "$ROOT/bin/zanken-update" || fail "Zanken updates sync managed desktop defaults"
rg -Fq 'zanken-config-desktop rollback' "$ROOT/bin/zanken-update" || fail "Zanken updates roll back a failed Quickshell restart"
pass "Zanken updates synchronize and protect managed desktop defaults"

rg -Fq 'quickshell/zanken/shell.qml' "$ROOT/bin/zanken-restart-quickshell" || fail "Quickshell restart detects the managed config"
rg -Fq 'config_name=desktop' "$ROOT/bin/zanken-restart-quickshell" || fail "Quickshell restart falls back to the legacy config during migration"
rg -Fq 'qs -c zanken ipc call zanken reload' "$ROOT/bin/zanken-restart-quickshell" || fail "Quickshell restart uses an in-process reload for the managed config"
if rg -q 'playerctl|zanken-paused-media' "$ROOT/bin/zanken-restart-quickshell"; then
  fail "Quickshell soft reload does not manipulate media players"
fi
rg -Fq 'Quickshell.reload(false);' "$ROOT/default/desktop/quickshell/shell.qml" || fail "managed Quickshell config provides a soft reload IPC target"
pass "Quickshell restart preserves browser media and supports legacy configs"

if rg -n '\[omarchy\]|pkgs\.omarchy\.org|TrustAll' "$ROOT/default/pacman" "$ROOT/install/preflight/pacman.sh"; then
  fail "fresh installs do not configure the retired Omarchy package repository"
fi
rg -Fq 'zanken-pkg-aur-add "${aur_packages[@]}"' "$ROOT/bin/zanken-pkg-add" || fail "package helper falls back to the AUR"
pass "fresh installs use official repositories and the AUR"

if rg -n 'zanken-keyring|pkgs\.omarchy\.org|stable-mirror\.omarchy\.org|Syyuu' \
  "$ROOT/bin/zanken-update-keyring" \
  "$ROOT/bin/zanken-version-channel" \
  "$ROOT/bin/zanken-refresh-pacman" \
  "$ROOT/bin/zanken-reinstall-pkgs"; then
  fail "package maintenance does not depend on retired Omarchy infrastructure"
fi
rg -Fq 'zanken-branch-set "main"' "$ROOT/bin/zanken-channel-set" || fail "stable channel tracks the main branch"
pass "package maintenance is independent of retired infrastructure"

rg -Fq 'MANAGED_NIRI_CONFIG=' "$ROOT/bin/zanken-theme-bg-colors-apply" || fail "wallpaper colors detect the managed Niri config"
rg -Fq 'NIRI_CONFIG="$MANAGED_NIRI_CONFIG"' "$ROOT/bin/zanken-theme-bg-colors-apply" || fail "wallpaper colors update the adopted Niri config"
pass "wallpaper colors update the managed Niri config after adoption"

"$CLI" commands --all --json | jq -e '.ok == true and (.commands | length >= 280)' >/dev/null
pass "command listing JSON covers the command surface"

output=$("$CLI" screenshot --help)
assert_output_contains "screenshot alias resolves to its canonical command" "$output" "zanken-capture-screenshot"

output=$("$CLI" capture screenshot --help)
assert_output_contains "canonical screenshot route resolves" "$output" "zanken-capture-screenshot"

output=$("$CLI" dev benchmark --repeat=1)
assert_output_contains "CLI benchmark runs" "$output" "Zanken CLI benchmark"

output=$("$CLI" restart quickshell --help)
assert_output_contains "Quickshell restart route is documented" "$output" "zanken-restart-quickshell"

if rg -q 'zanken (restart|toggle) waybar' "$ROOT/default/zanken-skill/SKILL.md"; then
  fail "bundled skill does not reference removed Waybar commands"
fi
pass "bundled skill does not reference removed Waybar commands"

if rg -q '\.config/omarchy' "$ROOT/default/quickshell/select-by-image.qml"; then
  fail "image selector uses Zanken-owned theme paths"
fi
pass "image selector uses Zanken-owned theme paths"

if [[ -e $ROOT/bin/zanken-windows-vm ]] || rg -q 'zanken-windows-vm' "$ROOT/bin" "$ROOT/docs"; then
  fail "Windows VM launcher is fully removed"
fi
pass "Windows VM launcher is fully removed"

rg -Fq 'ZANKEN_MIGRATION_BASELINE=1780164860' "$ROOT/bin/zanken-migrate" || fail "migration runner declares the Zanken fork baseline"
rg -Fq '(( migration_id < ZANKEN_MIGRATION_BASELINE )) && continue' "$ROOT/bin/zanken-migrate" || fail "migration runner skips inherited migration history"
rg -Fq 'migration_id=${BASH_REMATCH[1]}' "$ROOT/bin/zanken-migrate" || fail "migration runner parses numeric migration prefixes"
rg -Fq 'ZANKEN_MIGRATIONS_STATE_PATH=~/.local/state/zanken/migrations' "$ROOT/install/preflight/migrations.sh" || fail "fresh installs record migrations in Zanken state"
rg -Fq 'migration_id=${BASH_REMATCH[1]}' "$ROOT/install/preflight/migrations.sh" || fail "installer migration baseline parses numeric migration prefixes"
if rg -q 'OMARCHY_PATH' "$ROOT/migrations/1780164860.sh"; then
  fail "Zanken migrations do not depend on Omarchy paths"
fi
pass "migrations use the Zanken baseline and state"

rg -Fq 'Remove retired Omarchy package, Walker, and Elephant integration' "$ROOT/migrations/1784273404.sh" || fail "Walker retirement migration is present"
rg -Fq 'walker-restart.hook' "$ROOT/migrations/1784273404.sh" || fail "Walker retirement migration removes the old update hook"
rg -Fq "'^\\[omarchy\\]$'" "$ROOT/migrations/1784273404.sh" || fail "retirement migration removes the legacy package repository"
pass "Walker retirement is applied to existing installations"

if rg -q '\.config/hypr' \
  "$ROOT/bin/zanken-setup-security-fingerprint" \
  "$ROOT/bin/zanken-remove-security-fingerprint" \
  "$ROOT/bin/zanken-install-service-sunshine" \
  "$ROOT/bin/zanken-remove-service-sunshine"; then
  fail "migrated commands do not write Hyprland configuration"
fi
pass "migrated commands do not write Hyprland configuration"

stale_documented_commands=$(comm -23 \
  <(rg -No 'zanken-[a-z0-9-]+' "$ROOT/docs/commands" | sed 's|.*:||' | sort -u) \
  <(find "$ROOT/bin" -maxdepth 1 -type f -executable -printf '%f\n' | sort -u))
[[ -z $stale_documented_commands ]] || fail "command documentation references only executable binaries"
pass "command documentation references only executable binaries"

printf 'all Zanken CLI tests passed\n'
