#!/bin/bash
set -euo pipefail
mode=${1:---check}
(( $# <= 1 )) && [[ $mode == "--check" || $mode == "--install" ]] || {
  echo 'Usage: bash test/install-existing-niri-vm.sh [--check|--install]'; exit 2;
}
fail() { echo "$*" >&2; exit 2; }
(( EUID != 0 )) || fail 'Use a regular user.'
vm_type=$(systemd-detect-virt --vm 2>/dev/null || true)
[[ $vm_type == "qemu" || $vm_type == "kvm" ]] || fail 'Only a disposable QEMU/KVM guest is allowed.'
[[ -f /etc/arch-release ]] || fail 'An Arch-based guest is required.'
[[ -z ${WAYLAND_DISPLAY:-} && -z ${NIRI_SOCKET:-} ]] || fail 'Log out and use a TTY.'
command -v niri >/dev/null || fail 'Install and configure Niri before testing takeover.'
[[ -f $HOME/.config/niri/config.kdl ]] || fail 'Create a custom Niri configuration first.'
[[ ! -f $HOME/.local/state/zanken/releases/installed.json ]] || fail 'Use an unmanaged custom desktop, not an existing Zanken release.'
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ -z $(git -C "$repo" status --porcelain) ]] || fail 'The candidate checkout must be clean.'
commit=$(git -C "$repo" rev-parse HEAD)
echo "Existing-Niri VM preflight passed: $commit"
[[ $mode == "--install" ]] || exit 0
run_dir=$(mktemp -d "$HOME/zanken-takeover-test.XXXXXX")
git init --bare "$run_dir/origin.git"
git -C "$run_dir/origin.git" fetch "$repo" "$commit:refs/heads/dev"
export ZANKEN_REPOSITORY="$run_dir/repository"
git clone --branch dev "$run_dir/origin.git" "$ZANKEN_REPOSITORY"
export ZANKEN_RELEASE_MODE=dev
unset ZANKEN_RELEASE_VERSION ZANKEN_REF
echo "Candidate retained at $run_dir"
bash "$ZANKEN_REPOSITORY/boot.sh" --replace-niri
