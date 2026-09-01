if zanken-battery-present; then
  sudo install -d -o root -g root -m 0755 /usr/lib/zanken
  sudo install -o root -g root -m 0755 \
    "$ZANKEN_PATH/bin/zanken-powerprofiles-set" \
    /usr/lib/zanken/zanken-powerprofiles-set

  cat <<EOF | sudo tee "/etc/udev/rules.d/99-power-profile.rules"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="/usr/bin/systemd-run --no-block --collect --unit=zanken-power-profile --property=After=power-profiles-daemon.service /usr/lib/zanken/zanken-powerprofiles-set"
SUBSYSTEM=="power_supply", ATTR{type}=="USB", RUN+="/usr/bin/systemd-run --no-block --collect --unit=zanken-power-profile --property=After=power-profiles-daemon.service /usr/lib/zanken/zanken-powerprofiles-set"
EOF

  sudo systemctl enable power-profiles-daemon

  sudo udevadm control --reload 2>/dev/null
  sudo udevadm trigger --subsystem-match=power_supply 2>/dev/null
fi
