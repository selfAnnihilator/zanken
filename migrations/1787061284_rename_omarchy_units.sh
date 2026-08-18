echo "Rename Omarchy-branded user systemd units to Zanken names"

UNITS_DIR=~/.config/systemd/user
mkdir -p "$UNITS_DIR"

for old in omarchy-battery-monitor.service omarchy-battery-monitor.timer omarchy-recover-internal-monitor.service; do
  if [[ -f $UNITS_DIR/$old ]]; then
    systemctl --user disable --now "$old" 2>/dev/null || true
    new="zanken-${old#omarchy-}"
    cp "$UNITS_DIR/$old" "$UNITS_DIR/$new"
    sed -i -e 's/Omarchy/Zanken/g' -e 's/omarchy-/zanken-/g' -e 's|\.local/state/omarchy/|.local/state/zanken/|' "$UNITS_DIR/$new"
    rm -f "$UNITS_DIR/$old"
  fi
done

systemctl --user daemon-reload
systemctl --user enable zanken-battery-monitor.timer 2>/dev/null || true
systemctl --user enable zanken-recover-internal-monitor.service 2>/dev/null || true