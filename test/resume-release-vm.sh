#!/bin/bash

# One-off recovery for the 7f8feaa3 VM install stopped at limine-snapper.sh.
# Not a general installer resume API. Never run this on a physical host.
set -eEo pipefail

if [[ ${1:-} != "--confirm-vm-recovery" ]] || (( EUID == 0 )); then
  echo "Run as the VM's regular user with --confirm-vm-recovery." >&2
  exit 2
fi
vm_type=$(systemd-detect-virt --vm || true)
if [[ $vm_type != "qemu" && $vm_type != "kvm" ]]; then
  echo "This recovery requires a QEMU/KVM test guest (detected: $vm_type)." >&2
  exit 2
fi

export ZANKEN_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export ZANKEN_INSTALL="$ZANKEN_PATH/install"
export ZANKEN_REPOSITORY="$ZANKEN_PATH"
export ZANKEN_INSTALL_COMMIT="$(git -C "$ZANKEN_PATH" rev-parse HEAD)"
export ZANKEN_RELEASE_MODE=dev
export ZANKEN_RELEASE_INSTALL=1
export PATH="$ZANKEN_PATH/bin:$PATH"
unset ZANKEN_RELEASE_VERSION ZANKEN_CHROOT_INSTALL

if [[ -n $(git -C "$ZANKEN_PATH" status --porcelain) ]]; then
  echo "Recovery requires a clean candidate checkout." >&2
  exit 1
fi
if [[ $(git -C "$ZANKEN_PATH" rev-parse refs/remotes/origin/dev) != "$ZANKEN_INSTALL_COMMIT" ]]; then
  echo "Local origin/dev must match the recovery candidate." >&2
  exit 1
fi
if ! grep -q 'Error: Limine config not found' /var/log/zanken-install.log; then
  echo "Expected failed installation log not found; stop for diagnosis." >&2
  exit 1
fi
if ! grep -q 'Completed: .*/install/login/hibernation.sh' /var/log/zanken-install.log; then
  echo "Previous login stages are not confirmed complete." >&2
  exit 1
fi

sudo -v
sudo test -f /boot/EFI/BOOT/limine.conf
sudo grep -q '^[[:space:]]*cmdline:' /boot/EFI/BOOT/limine.conf
backup_dir=$(sudo mktemp -d /var/tmp/zanken-boot-recovery.XXXXXX)
sudo tar -C / -cf "$backup_dir/boot-before.tar" boot
sudo cp /etc/fstab "$backup_dir/fstab-before"
echo "Boot files backed up to $backup_dir (keep this path)."

source "$ZANKEN_INSTALL/helpers/chroot.sh"
recovery_log=$(mktemp "$HOME/zanken-recovery.XXXXXX.log")
echo "Recovery log: $recovery_log"
for stage in login/limine-snapper.sh post-install/pacman.sh post-install/release.sh; do
  echo "Running $stage"
  bash -eE -c 'source "$1"' bash "$ZANKEN_INSTALL/$stage" 2>&1 | tee -a "$recovery_log"
done

# Remove temporary installer privileges normally cleaned by finished.sh.
for policy in /etc/sudoers.d/99-zanken-installer /etc/sudoers.d/99-zanken-installer-reboot; do
  if sudo test -f "$policy"; then
    sudo cp "$policy" "$backup_dir/"
    sudo rm "$policy"
  fi
done
"$ZANKEN_PATH/bin/zanken-release" status
echo "Recovery stages completed. No reboot was performed; review the output first."
