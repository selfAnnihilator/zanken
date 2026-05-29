# Installation

Zanken runs on Arch Linux. The install script sets up everything from scratch.

## Prerequisites

- Fresh Arch Linux install (bare minimum: `base`, `base-devel`, `git`)
- Internet connection
- A user account with sudo access

## One-line install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/selfAnnihilator/dotfiles/main/install.sh)
```

## What the script does

| Phase | Action |
|-------|--------|
| 1 | Install `base-devel git fish` via pacman |
| 2 | Build and install `yay` AUR helper |
| 3 | Install all required packages (see below) |
| 4 | Clone `zanken` repo to `~/zanken` |
| 5 | Clone dotfiles bare repo to `~/dotfiles`, checkout configs |
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

## Updating configs

Configs live in the dotfiles bare repo:

```bash
# After editing any config file
dotfiles add ~/.config/niri/config.kdl
dotfiles commit -m "update niri config"
dotfiles push
```

The `dotfiles` alias is set automatically by fish config:
```fish
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
```

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
