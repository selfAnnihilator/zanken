# Only grant sudo-less Apple Display control when the optional tool exists.
if zanken-cmd-present asdcontrol; then
  if [[ ! $USER =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "Refusing to write sudoers with invalid username: $USER" >&2
    exit 1
  fi
  echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/asdcontrol" | sudo tee /etc/sudoers.d/asdcontrol
  sudo chmod 440 /etc/sudoers.d/asdcontrol
fi
