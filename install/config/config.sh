# Copy over Omarchy configs
mkdir -p ~/.config
cp -R "$ZANKEN_PATH"/config/* ~/.config/

# Use default bashrc from Omarchy
cp "$ZANKEN_PATH/default/bashrc" ~/.bashrc
