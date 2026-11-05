# Installation

Zanken has two installation paths: full provisioning on fresh Arch, and an
opt-in [existing Niri desktop replacement](desktop-takeover.md). There is no published stable release yet; use the dev channel.

## Prerequisites

- Fresh x86_64 Arch Linux, Btrfs root and Limine for full provisioning
- Internet connection
- A user account with sudo access

## One-line install

There is no stable release yet, so select the `dev` channel:

```bash
ZANKEN_RELEASE_MODE=dev bash <(curl -fsSL https://raw.githubusercontent.com/selfAnnihilator/zanken/main/boot.sh)
```

For the tested desktop path on an existing Arch system, run as a regular
sudo-enabled user from a logged-out TTY:

```bash
sudo pacman -Syu --needed git python jq
ZANKEN_RELEASE_MODE=dev bash <(curl -fsSL https://raw.githubusercontent.com/selfAnnihilator/zanken/main/boot.sh) --desktop
```

This backs up and replaces desktop configuration. Full provisioning above also
configures the bootloader and snapshots; the desktop path preserves partitions
and the bootloader.

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
stages. Desktop installation uses `install/zanken-desktop.packages` and
`install/zanken-workflow.packages`, plus detected graphics dependencies and bootstrap build tools. Both include the wallpaper/rendering and browser defaults;
desktop replacement does not run bootloader or full-system configuration stages.

## Portable desktop and workflow

Use `boot.sh --desktop` from a TTY on x86_64 Arch or an Arch-based distribution,
including CachyOS. `--replace-niri` remains an alias. An existing Niri installation
is optional. Bootstrap requires Git, Python and jq already installed; if missing,
install them with `sudo pacman -Syu git python jq`. The verified release must
contain the portable workflow implementation; local uncommitted changes are not
included in release archives.

Desktop installation now also installs `install/zanken-workflow.packages`:
Zellij/Fish, Starship, zoxide, shell navigation and completion, Git/lazygit,
Neovim, tmux, mise, system tools, OCR, recording and hardware-control frontends.
It does not install language runtimes, Docker services, account-based tools or
personal application inventories. Fish is Zellij's shell; the login shell stays
unchanged. Managed Bash integration is appended without replacing existing lines.

Super+Enter resumes/focuses a workspace, Super+Alt+Enter starts a fresh one,
Super+S opens the session picker, and Super+T opens a plain Foot terminal.
The snapshot timer retains last-good layouts for recovery. It uses the active
release path, so the source repository need not live at `~/zanken`.

Workflow defaults are explicitly allowlisted in `lib/zanken/workflow.py` and
follow the active release, including rollback. Backups cover replaced defaults,
shell integration and user-service activation. Existing local state remains on
the target; no source-machine histories, sessions, credentials, identities,
browser data, project paths or network profiles are exported. Edit local shell
settings outside the managed fragments. Managed workflow files are release
defaults and are replaced by release updates.

Bundled Zellij plugins currently require **0.45.1**. Preflight checks the repository
version and SHA256 validation runs before activation. Other versions are rejected
until the plugins are rebuilt and tested; the installer does not downgrade or
pin distribution packages. Rebuilding either plugin set regenerates `SHA256SUMS`.

### Hardware policy

Preflight inventories display-class PCI devices, distribution, kernels and drivers
before package changes. NVIDIA classification uses the explicit device and
subsystem table from NVIDIA's
[590.48.01 supported-product list](https://download.nvidia.com/XFree86/Linux-x86_64/590.48.01/README/supportedchips.html).
Unknown devices and mixed NVIDIA driver generations stop with repair guidance.

| Target | Behavior |
| --- | --- |
| Intel / AMD | Install missing Mesa and matching Vulkan packages |
| Virtual graphics | Install Mesa; actual compositor support still requires VM validation |
| Existing NVIDIA | Preserve consistent module/userspace versions across every installed kernel |
| Existing Nouveau | Preserve the active driver and provide Mesa |
| Missing NVIDIA driver | Select open or 580 legacy DKMS packages, preferring enabled repositories; legacy packages may use AUR |
| Hybrid laptop | Include integrated-GPU dependencies; do not force NVIDIA globally |

Automatic NVIDIA provisioning currently supports existing mkinitcpio presets.
It requires exact kernel-header file metadata, checks every DKMS build and rebuilds
initramfs. Dracut, ambiguous initramfs setups, conflicting drivers and unresolved
headers require distribution-specific setup first. Synchronize file databases
with `sudo pacman -Fy` if header metadata is missing, then rerun preflight.
New NVIDIA installations require a reboot; modules are never forcibly reloaded.

Wi-Fi launchers use nmtui on NetworkManager and Impala on iwd. Wi-Fi hardware with
neither service active stops preflight. The installer does not replace networking
services. Bluetooth controls explain when the existing service is unavailable.
Firmware power-key synchronization is enabled only with the supported firmware
interface and an active power-profiles-daemon, without TLP/auto-cpufreq conflicts.
No charger-triggered profile switching is installed.

The hardware/package plan is logged in `/var/log/zanken-install.log` and retained
after success at `~/.local/state/zanken/install/hardware.json`. Configuration restore
does **not** reverse package upgrades, driver installations or initramfs changes.

### Acceptance status

The desktop install command was confirmed end to end from GitHub on a fresh
minimal Arch VM on 2026-11-04. This does not establish full-provisioning,
physical NVIDIA/hybrid, disk-encryption or fresh CachyOS acceptance. Individual
features and rollback still need their acceptance checks. Isolated tests cover
hardware/package planning, workflow, backup and release behavior.

## After install

Reboot after installation. At the Pixel Sakura login screen, choose
**Zanken (Niri)**. The boot animation is installed, but is not confirmed working
on every setup. See [desktop takeover](desktop-takeover.md) for login recovery.

See [Zellij workflow](zellij.md) for the terminal workspace shortcuts.

## Updating desktop defaults

Zanken stores its updateable Niri and Quickshell defaults in
`~/.local/share/zanken/desktop/`. Local settings remain under
`~/.config/zanken/` and are never changed by a sync.

```bash
zanken release status         # source and installed generation details
zanken update --fetch         # update the installed mode from origin
zanken release rollback       # restore the previous desktop generation
```

Updates that touch `install/` or `migrations/` are refused. Desktop rollback
does not reverse packages or system setup. An already managed installation is
also refused by the desktop installer; do not rerun it as an upgrade workaround.
Use a documented component setup command where available, or wait for an upgrade
path covering the required system changes.

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

For developer testing of full provisioning, use the guarded
[fresh-VM test](fresh-vm-test.md). For a guest with an existing custom desktop,
follow the [takeover test](desktop-takeover.md).

!!! tip
    After archinstall completes, remove the `iso=` line from the `.conf` file before relaunching — otherwise quickemu boots from the ISO again.
