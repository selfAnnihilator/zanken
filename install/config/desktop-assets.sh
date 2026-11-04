# Keep user files and the previous Hornet theme; ship the full wallpaper library.
mkdir -p "$HOME/Pictures/wallpaper" "$HOME/.local/share/icons/Brushbuddy"
cp -an "$ZANKEN_PATH/default/wallpapers/." "$HOME/Pictures/wallpaper/"
cp -an "$ZANKEN_PATH/default/cursors/Brushbuddy/." "$HOME/.local/share/icons/Brushbuddy/"

mkdir -p "$HOME/.icons/default" "$HOME/.config/zanken/current"
ln -sfn "$HOME/.local/share/icons/Brushbuddy" "$HOME/.icons/Brushbuddy"
printf '[Icon Theme]\nName=Default\nInherits=Brushbuddy\n' > "$HOME/.icons/default/index.theme"

for gtk in gtk-3.0 gtk-4.0; do
  settings="$HOME/.config/$gtk/settings.ini"
  mkdir -p "$(dirname "$settings")"
  [[ -f $settings ]] || printf '[Settings]\n' > "$settings"
  for setting in 'gtk-cursor-theme-name=Brushbuddy' 'gtk-cursor-theme-size=40'; do
    key=${setting%%=*}
    if grep -q "^$key=" "$settings"; then
      sed -i "s/^$key=.*/$setting/" "$settings"
    else
      sed -i "/^\[Settings\]/a $setting" "$settings"
    fi
  done
done

background="$HOME/.config/zanken/current/background"
if [[ ! -e $background && ! -L $background ]]; then
  ln -s "$HOME/Pictures/wallpaper/wallhaven-lydzk2_3840x2160.png" "$background"
elif [[ -L $background && ! -e $background ]]; then
  # Keep the broken target for diagnosis instead of discarding user state.
  mv "$background" "$background.broken.$(date +%s%N)"
  ln -s "$HOME/Pictures/wallpaper/wallhaven-lydzk2_3840x2160.png" "$background"
fi
