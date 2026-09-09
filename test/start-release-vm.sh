#!/bin/bash
# Disposable release acceptance VM; never attaches host disks or shared folders.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
vm_dir="$repo/.release-vm"
iso="$vm_dir/archlinux-latest/archlinux-2026.09.01-x86_64.iso"
firmware="/usr/share/edk2/x64"

if [[ ${1:-} != "--iso" && ${1:-} != "--disk" ]]; then
  echo "Usage: bash test/start-release-vm.sh --iso|--disk" >&2
  exit 2
fi
if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
  echo "KVM is unavailable in this execution context; run from the host desktop." >&2
  exit 1
fi
if [[ ! -f $vm_dir/ISO.SHA256 ]]; then
  echo "Missing verified ISO receipt: .release-vm/ISO.SHA256" >&2
  exit 1
fi
(cd "$vm_dir" && sha256sum --check ISO.SHA256)
[[ -r $firmware/OVMF_CODE.4m.fd && -r $firmware/OVMF_VARS.4m.fd ]]

# Hold the lock for the QEMU lifetime; never open one writable disk twice.
exec 9>"$vm_dir/vm.lock"
flock --nonblock 9 || { echo "Acceptance VM is already running." >&2; exit 1; }
if [[ ! -e $vm_dir/system.qcow2 ]]; then
  qemu-img create -f qcow2 "$vm_dir/system.qcow2" 40G
fi
if [[ ! -e $vm_dir/OVMF_VARS.fd ]]; then
  cp "$firmware/OVMF_VARS.4m.fd" "$vm_dir/OVMF_VARS.fd"
fi
boot_args=(-boot order=c)
if [[ $1 == "--iso" ]]; then
  boot_args=(-cdrom "$iso" -boot order=d)
fi

# No microphone, clipboard, USB passthrough, shared filesystem or public listener.
exec qemu-system-x86_64 \
  -name zanken-release-acceptance \
  -machine q35,accel=kvm -cpu host -smp 2 -m 3072 \
  -drive "if=pflash,format=raw,readonly=on,file=$firmware/OVMF_CODE.4m.fd" \
  -drive "if=pflash,format=raw,file=$vm_dir/OVMF_VARS.fd" \
  -drive "if=virtio,format=qcow2,file=$vm_dir/system.qcow2" \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:22220-:22 \
  -device virtio-net-pci,netdev=net0 \
  -device virtio-vga -display gtk \
  -monitor "unix:$vm_dir/monitor.sock,server=on,wait=off" \
  -serial "file:$vm_dir/serial.log" \
  "${boot_args[@]}"
