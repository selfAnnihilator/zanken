# Turn on bluetooth by default
chrootable_systemctl_enable bluetooth.service

# Persist last power state across reboots (default AutoEnable=true overrides
# it). Replace a present AutoEnable line (commented or not) or insert one
# under [General] when the option is absent.
if sudo grep -q '^[#[:space:]]*AutoEnable=' /etc/bluetooth/main.conf; then
  sudo sed -i 's/^[#[:space:]]*AutoEnable=.*/AutoEnable=false/' /etc/bluetooth/main.conf
else
  sudo sed -i '/^\[General\]/a AutoEnable=false' /etc/bluetooth/main.conf
fi

mkdir -p ~/.config/wireplumber/wireplumber.conf.d/
cp "$ZANKEN_PATH/default/wireplumber/wireplumber.conf.d/bluetooth-a2dp-autoconnect.conf" ~/.config/wireplumber/wireplumber.conf.d/
