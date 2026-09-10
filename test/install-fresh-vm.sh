#!/bin/bash
set -euo pipefail

# This entry point is deliberately limited to a fresh QEMU/KVM test guest.
mode=${1:---check}
if (( $# > 1 )) || [[ $mode != "--check" && $mode != "--install" ]]; then
  echo "Usage: bash test/install-fresh-vm.sh [--check|--install]" >&2
  exit 2
fi
fail() { echo "Preflight: $*" >&2; exit 1; }
(( EUID != 0 )) || fail "Log in as your regular sudo-enabled user."
vm_type=$(systemd-detect-virt --vm 2>/dev/null || true)
[[ $vm_type == "qemu" || $vm_type == "kvm" ]] || fail "Use a fresh QEMU/KVM guest, not the host."
[[ -f /etc/arch-release ]] || fail "Vanilla Arch is required."
for marker in cachyos eos garuda manjaro; do
  [[ ! -f /etc/$marker-release ]] || fail "Use vanilla Arch."
done
[[ $(uname -m) == "x86_64" ]] || fail "x86_64 is required."
[[ $(findmnt -n -o FSTYPE /) == "btrfs" ]] || fail "Choose Btrfs for the root filesystem."
command -v limine >/dev/null || fail "Install Arch with Limine first."
[[ -d /sys/firmware/efi ]] || fail "Boot the test guest in UEFI mode."
[[ ! -e $HOME/.local/share/zanken && ! -L $HOME/.local/share/zanken ]] || fail "Zanken already exists; preserve this guest and create a fresh one."
[[ ! -e $HOME/.config/zanken ]] || fail "Existing Zanken configuration found; use a fresh guest."
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ -z $(git -C "$repo" status --porcelain) ]] || fail "Commit or discard checkout changes before testing."
commit=$(git -C "$repo" rev-parse HEAD)
available=$(df -Pk / | awk 'NR==2 {print $4}')
(( available >= 15 * 1024 * 1024 )) || fail "At least 15 GiB of root free space is required."
echo "Zanken fresh-VM preflight passed. Candidate: $commit"
[[ $mode == "--install" ]] || exit 0

echo "This will download/build packages and install Zanken in this guest."
read -r -p "Type INSTALL to continue: " answer
[[ $answer == "INSTALL" ]] || exit 0
sudo -v
run_dir=$(mktemp -d "$HOME/zanken-fresh-install.XXXXXX")
echo "Builds, source and logs retained at $run_dir"
exec > >(tee -a "$run_dir/runner.log") 2>&1
trap 'echo "Stopped at line $LINENO. Keep $run_dir and inspect runner.log; do not blindly rerun the installer."' ERR

echo "[1/3] Prepare boot packages (no boot-package installation yet)"
sudo pacman -Syu --needed base-devel git python jq less
export ZANKEN_LIMINE_PACKAGE_DIR="$run_dir/packages"
mkdir -p "$ZANKEN_LIMINE_PACKAGE_DIR"
for package in limine-snapper-sync limine-mkinitcpio-hook; do
  git clone "https://aur.archlinux.org/$package.git" "$ZANKEN_LIMINE_PACKAGE_DIR/$package"
  echo "Review $package recipe and any .install files before building."
  less "$ZANKEN_LIMINE_PACKAGE_DIR/$package/PKGBUILD"
  for hook in "$ZANKEN_LIMINE_PACKAGE_DIR/$package/"*.install; do
    [[ ! -f $hook ]] || less "$hook"
  done
  read -r -p "Build $package? [y/N] " answer
  [[ $answer == "y" || $answer == "Y" ]] || exit 1
  (cd "$ZANKEN_LIMINE_PACKAGE_DIR/$package" && makepkg --syncdeps)
done
source "$repo/install/helpers/limine-packages.sh"
prepare_limine_packages

echo "[2/3] Pin the tested checkout as an isolated local dev origin"
git init --bare "$run_dir/origin.git"
git -C "$run_dir/origin.git" fetch "$repo" "$commit:refs/heads/dev"
export ZANKEN_REPOSITORY="$run_dir/repository"
git clone --branch dev "$run_dir/origin.git" "$ZANKEN_REPOSITORY"
export ZANKEN_RELEASE_MODE=dev
unset ZANKEN_RELEASE_VERSION ZANKEN_REF

echo "[3/3] Install pinned Zanken candidate"
sudo tar -cf "$run_dir/boot-before.tar" -C / boot etc/fstab
echo "Boot files backed up to $run_dir/boot-before.tar (not a full system rollback)."
bash "$ZANKEN_REPOSITORY/boot.sh"
