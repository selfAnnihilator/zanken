if zanken-battery-present; then
  sudo install -d -o root -g root -m 0755 /usr/lib/zanken
  sudo install -o root -g root -m 0755 \
    "$ZANKEN_PATH/bin/zanken-wifi-powersave" \
    /usr/lib/zanken/zanken-wifi-powersave

  cat <<EOF | sudo tee "/etc/udev/rules.d/99-wifi-powersave.rules"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="/usr/bin/systemd-run --no-block --collect --unit=zanken-wifi-powersave-on /usr/lib/zanken/zanken-wifi-powersave on"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="/usr/bin/systemd-run --no-block --collect --unit=zanken-wifi-powersave-off /usr/lib/zanken/zanken-wifi-powersave off"
EOF

  sudo udevadm control --reload
  sudo udevadm trigger --subsystem-match=power_supply
fi
