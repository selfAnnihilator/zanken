set -e
THEME_SRC="${ZANKEN_PATH:-$HOME/zanken}/install/config/plymouth-zanken"
THEME_DEST="/usr/share/plymouth/themes/zanken"

sudo mkdir -p "$THEME_DEST"
sudo cp "$THEME_SRC"/*.png "$THEME_DEST/"
sudo cp "$THEME_SRC"/zanken.script "$THEME_DEST/"
sudo cp "$THEME_SRC"/zanken.plymouth "$THEME_DEST/"

sudo plymouth-set-default-theme zanken

# Hook, kernel command line (Limine, GRUB, systemd-boot, UKI) and initramfs rebuild, with rollback
sudo python3 -B "${ZANKEN_PATH:-$HOME/zanken}/lib/zanken/boot.py" apply "${ZANKEN_PATH:-$HOME/zanken}"

echo "zanken Plymouth theme installed and initramfs rebuilt"
