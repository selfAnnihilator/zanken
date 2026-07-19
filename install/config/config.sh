# Copy over Zanken configs
mkdir -p ~/.config
cp -R "$ZANKEN_PATH"/config/* ~/.config/

# Use default bashrc from Zanken
cp "$ZANKEN_PATH/default/bashrc" ~/.bashrc
