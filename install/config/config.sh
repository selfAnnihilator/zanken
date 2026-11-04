# Copy over Zanken configs
mkdir -p ~/.config
cp -Rn "$ZANKEN_PATH"/config/* ~/.config/

# Use default bashrc from Zanken
if [[ ! -e ~/.bashrc ]]; then
  cp "$ZANKEN_PATH/default/bashrc" ~/.bashrc
fi
