echo "Enable Zellij last-good layout snapshot timer"

mkdir -p ~/.config/systemd/user
cp "$OMARCHY_PATH"/config/systemd/user/zanken-zellij-snapshot.* ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now zanken-zellij-snapshot.timer
