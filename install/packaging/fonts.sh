# Zanken logo in a font for Waybar use
mkdir -p ~/.local/share/fonts
cp "$ZANKEN_PATH/config/zanken.ttf" ~/.local/share/fonts/
fc-cache
