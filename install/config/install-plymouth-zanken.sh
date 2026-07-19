#!/usr/bin/env bash
set -e
THEME_SRC="${ZANKEN_PATH:-$HOME/zanken}/install/config/plymouth-zanken"
THEME_DEST="/usr/share/plymouth/themes/zanken"

sudo mkdir -p "$THEME_DEST"
sudo cp "$THEME_SRC"/*.png "$THEME_DEST/"
sudo cp "$THEME_SRC"/zanken.script "$THEME_DEST/"
sudo cp "$THEME_SRC"/zanken.plymouth "$THEME_DEST/"

# Ensure plymouth hook is in mkinitcpio HOOKS (required for splash to appear)
if ! grep -q 'plymouth' /etc/mkinitcpio.conf; then
    # Insert plymouth after kms if present, else after udev/systemd
    sudo sed -i \
        's/\(HOOKS=([^)]*\)\(kms\)\([^)]*)\)/\1\2 plymouth\3/' \
        /etc/mkinitcpio.conf
    # Fallback: if kms not found, insert before filesystems
    grep -q 'plymouth' /etc/mkinitcpio.conf || \
        sudo sed -i 's/filesystems/plymouth filesystems/' /etc/mkinitcpio.conf
fi

sudo plymouth-set-default-theme zanken
sudo mkinitcpio -P

echo "zanken Plymouth theme installed and initramfs rebuilt"
