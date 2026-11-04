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

The implementation has isolated hardware/package, workflow, backup and real-Git
release tests. Physical NVIDIA/hybrid testing and fresh Arch/CachyOS installation
with screenshots remain release acceptance requirements; passing mocked hardware
tests does not establish real driver compatibility. Do not run takeover on a
working desktop to substitute for these checks.

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
