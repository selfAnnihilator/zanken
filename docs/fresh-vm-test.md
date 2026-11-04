# Fresh Arch VM test

Keep the working VM. Create a separate UEFI QEMU/KVM guest with 4 GiB RAM,
40 GiB disk, vanilla Arch, Btrfs root, Limine, networking, and a regular user
with sudo. This runner does not partition disks or install Arch itself.

Run downloads yourself inside the new guest:

```bash
sudo pacman -Syu --needed git
git clone --single-branch --branch codex/release-vm-test https://github.com/selfAnnihilator/zanken.git
cd zanken
bash test/install-fresh-vm.sh --check
bash test/install-fresh-vm.sh --install
```

The check is non-mutating. Installation asks for confirmation, prepares both
Limine AUR packages before changing boot configuration, and pins the checkout
through an isolated local dev origin. Review AUR recipes before approving their
builds. A boot-files/fstab backup is retained before installation; it is not a
full system rollback. The upstream dev branch is not modified. Allow time and disk space for
the wallpaper library and package builds. Do not run this on the existing guest
or host. Failed installs are not automatically retried; retain the printed
run directory and logs for diagnosis.

After successful installation and reboot, check the terminal, wallpaper,
Mod+B (qutebrowser), Mod+Shift+B (Zen), Brushbuddy cursor, and retained Hornet
theme. Capture a guest screenshot for visual verification. The fresh-install
test is not complete until these checks pass. This is a VM-test runner, not a
published stable installer; its local dev origin is intentionally pinned.
