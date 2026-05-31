#!/usr/bin/env bash
set -e
THEME_SRC="${OMARCHY_PATH:-$HOME/zanken}/install/config/plymouth-zanken"
THEME_DEST="/usr/share/plymouth/themes/zanken"

sudo mkdir -p "$THEME_DEST"
sudo cp "$THEME_SRC"/*.png "$THEME_DEST/"
sudo cp "$THEME_SRC"/zanken.script "$THEME_DEST/"
sudo cp "$THEME_SRC"/zanken.plymouth "$THEME_DEST/"

sudo plymouth-set-default-theme zanken
sudo mkinitcpio -P

echo "zanken Plymouth theme installed and initramfs rebuilt"
