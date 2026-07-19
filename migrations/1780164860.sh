echo "Fix swayosd-server: remove duplicate niri spawn, add startup delay to service"

# Remove duplicate spawn-at-startup (systemd service is the sole manager now)
if [[ -f ~/.config/niri/config.kdl ]]; then
  sed -i '/^spawn-at-startup "swayosd-server"$/d' ~/.config/niri/config.kdl
fi

# Update service file with ExecStartPre delay and on-failure restart policy
cp "$ZANKEN_PATH/config/systemd/user/swayosd-server.service" \
   ~/.config/systemd/user/swayosd-server.service

systemctl --user daemon-reload
systemctl --user reset-failed swayosd-server.service 2>/dev/null || true
systemctl --user restart swayosd-server.service
