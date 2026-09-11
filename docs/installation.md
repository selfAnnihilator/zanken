# Installation

Zanken has two installation paths: full provisioning on fresh Arch, and an
opt-in [existing Niri desktop replacement](desktop-takeover.md). The current
VM-test candidate is not a published stable release.

## Prerequisites

- Fresh x86_64 Arch Linux, Btrfs root and Limine for full provisioning
- Internet connection
- A user account with sudo access

## One-line install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/selfAnnihilator/zanken/main/boot.sh)
```

## What the script does

| Phase | Action |
|-------|--------|
| 1 | Resolve and verify an exact release source |
| 2 | Reuse an existing Yay command; bootstrap only when missing |
| 3 | Install missing packages from official repositories and the AUR |
| 4 | Apply desktop and full-system configuration |
| 5 | Activate the verified Niri/Quickshell desktop generation |
| 6 | Report completion and offer an optional reboot |

## Packages installed

Full provisioning uses `install/zanken-base.packages` and additional packaging
stages. Desktop replacement uses `install/zanken-desktop.packages` only, plus
bootstrap build tools. Both include the wallpaper/rendering and browser defaults;
desktop replacement does not run bootloader or full-system configuration stages.

## After install

Log out and start a Niri session:

```bash
# From a TTY (Ctrl+Alt+F2)
niri --session
```

Or configure your display manager to launch `niri`.

## Updating desktop defaults

Zanken stores its updateable Niri and Quickshell defaults in
`~/.local/share/zanken/desktop/`. Local settings remain under
`~/.config/zanken/` and are never changed by a sync.

```bash
zanken release status         # source and installed generation details
zanken update --fetch         # update the installed mode from origin
zanken release rollback       # restore the previous desktop generation
```

To take ownership of existing Niri or Quickshell configuration, run:

```bash
zanken release switch dev --fetch --adopt
```

`--adopt` explicitly authorizes replacing conflicting entry points with preserved
backups. Stable adoption uses `stable` instead of `dev` and requires a trusted
publisher key and a signed release tag. See the [release model](releases.md).
Before an eligible release is published, bootstrap will refuse installation.
For experimental bootstrap set `ZANKEN_RELEASE_MODE=dev`; `ZANKEN_RELEASE_VERSION`
can pin a stable version. Package provisioning is not covered by desktop rollback.

## Testing in a VM

```bash
# Install quickemu
yay -S quickemu

# Create Arch VM
mkdir -p ~/VMs/archlinux && cd ~/VMs/archlinux
quickget archlinux latest
quickemu --vm archlinux-latest.conf
```

Inside the VM, run `archinstall`, then reboot and run the install script.

For the unpublished candidate, follow the guarded [fresh-VM test](fresh-vm-test.md)
instead of the stable bootstrap. For a guest with an existing custom desktop,
follow the [takeover test](desktop-takeover.md).

!!! tip
    After archinstall completes, remove the `iso=` line from the `.conf` file before relaunching — otherwise quickemu boots from the ISO again.
