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

"$CLI" commands --check >/dev/null
pass "command metadata and fast-path aliases are valid"

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
