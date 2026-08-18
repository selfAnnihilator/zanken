echo "Keep Bluetooth off at boot unless toggled on manually"

# Bluez AutoEnable defaults to true, so adapters power on at every boot and
# override the last saved power state. Setting it explicitly to false makes
# the bluetooth.service enabled-but-cold: bluetoothctl power on stays the
# only way to start the radio. Replace a present AutoEnable line (commented
# or not) or insert one under [General] when the option is absent.
if sudo grep -q '^[#[:space:]]*AutoEnable=' /etc/bluetooth/main.conf 2>/dev/null; then
  sudo sed -i 's/^[#[:space:]]*AutoEnable=.*/AutoEnable=false/' /etc/bluetooth/main.conf
else
  sudo sed -i '/^\[General\]/a AutoEnable=false' /etc/bluetooth/main.conf
fi