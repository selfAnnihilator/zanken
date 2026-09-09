# Installation

Zanken runs on Arch Linux. The install script sets up everything from scratch.

## Prerequisites

- Fresh Arch Linux install (bare minimum: `base`, `base-devel`, `git`)
- Internet connection
- A user account with sudo access

## One-line install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/selfAnnihilator/zanken/main/boot.sh)
```

## What the script does

| Phase | Action |
|-------|--------|
| 1 | Install `base-devel git fish` via pacman |
| 2 | Build and install `yay` AUR helper |
| 3 | Install all required packages (see below) |
| 4 | Clone `zanken` repo to `~/zanken` |
| 5 | Install managed Niri and Quickshell defaults from Zanken itself |
| 6 | Set fish as default shell |
| 7 | Enable pipewire, wireplumber, NetworkManager, bluetooth services |

## Packages installed

```
niri              quickshell        cava              swayosd
elephant          playerctl         brightnessctl     wireplumber
pipewire          pipewire-pulse    pipewire-audio    xdg-desktop-portal-gnome
hypridle          swaybg            foot              fuzzel
jq                polkit-gnome      grim              slurp
wl-clipboard      fastfetch         ripgrep           curl
networkmanager    bluez             bluez-utils       ttf-jetbrains-mono-nerd
qutebrowser       python-adblock
```

## After install

Log out and start a Niri session:

```bash
# From a TTY (Ctrl+Alt+F2)
niri --session niri
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

!!! tip
    After archinstall completes, remove the `iso=` line from the `.conf` file before relaunching — otherwise quickemu boots from the ISO again.
