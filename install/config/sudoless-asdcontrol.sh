# Only grant sudo-less Apple Display control when the optional tool exists.
if zanken-cmd-present asdcontrol; then
  echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/asdcontrol" | sudo tee /etc/sudoers.d/asdcontrol
  sudo chmod 440 /etc/sudoers.d/asdcontrol
fi
