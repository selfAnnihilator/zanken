echo "Install root-owned helpers for power-supply udev events"

if zanken-battery-present; then
  source "$OMARCHY_PATH/install/config/powerprofilesctl-rules.sh"
  source "$OMARCHY_PATH/install/config/wifi-powersave-rules.sh"
else
  sudo rm -f \
    /etc/udev/rules.d/99-power-profile.rules \
    /etc/udev/rules.d/99-wifi-powersave.rules
fi
