# Set first-run mode marker so we can install stuff post-installation
mkdir -p ~/.local/state/zanken
touch ~/.local/state/zanken/first-run.mode

# Reject usernames that would corrupt or broaden the sudoers grant
if [[ ! $USER =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Refusing to write sudoers with invalid username: $USER" >&2
  exit 1
fi

# Setup sudo-less access for first-run
FIRST_RUN_SUDOERS=$(mktemp)
cat >"$FIRST_RUN_SUDOERS" <<EOF
Cmnd_Alias FIRST_RUN_CLEANUP = /usr/bin/rm -f /etc/sudoers.d/first-run
Cmnd_Alias FIRST_RUN_REBOOT_CLEANUP = /usr/bin/rm -f /etc/sudoers.d/99-zanken-installer-reboot
Cmnd_Alias SYMLINK_RESOLVED = /usr/bin/ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
Cmnd_Alias FIRST_RUN_ENABLE_UFW = /usr/bin/systemctl enable ufw
Cmnd_Alias FIRST_RUN_UFW = /usr/bin/ufw default deny incoming, /usr/bin/ufw default allow outgoing, /usr/bin/ufw allow 53317/udp, /usr/bin/ufw allow 53317/tcp, /usr/bin/ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment allow-docker-dns, /usr/bin/ufw allow in proto udp from 192.168.0.0/16 to 172.17.0.1 port 53 comment allow-docker-dns, /usr/bin/ufw --force enable, /usr/bin/ufw reload
Cmnd_Alias FIRST_RUN_UFW_DOCKER = /usr/bin/ufw-docker install
Cmnd_Alias FIRST_RUN_ICON_CACHE = /usr/bin/gtk-update-icon-cache /usr/share/icons/Yaru
$USER ALL=(root) NOPASSWD: FIRST_RUN_CLEANUP, FIRST_RUN_REBOOT_CLEANUP, SYMLINK_RESOLVED, FIRST_RUN_ENABLE_UFW, FIRST_RUN_UFW, FIRST_RUN_UFW_DOCKER, FIRST_RUN_ICON_CACHE
EOF

if ! visudo -cf "$FIRST_RUN_SUDOERS"; then
  rm -f "$FIRST_RUN_SUDOERS"
  exit 1
fi

sudo install -o root -g root -m 0440 "$FIRST_RUN_SUDOERS" /etc/sudoers.d/first-run
rm -f "$FIRST_RUN_SUDOERS"
