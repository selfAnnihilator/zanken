set -eE
source "$ZANKEN_INSTALL/helpers/desktop-backup.sh"
desktop_backup
trap 'status=$?; trap - EXIT; if (( status != 0 )); then desktop_restore; fi; exit "$status"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Keep original trees intact in the backup; move aside the replaced entry trees.
for target in .config/niri .config/foot .config/zanken .config/quickshell/zanken .config/hypr/hypridle.conf .icons/Brushbuddy .icons/Hornet; do
  if [[ -e $HOME/$target || -L $HOME/$target ]]; then
    mkdir -p "$DESKTOP_BACKUP/displaced/$(dirname "$target")"
    mv "$HOME/$target" "$DESKTOP_BACKUP/displaced/$target"
  fi
done
mkdir -p "$HOME/.config/foot" "$HOME/.config/zanken/current/next-theme"
cp -a "$ZANKEN_PATH/config/foot/." "$HOME/.config/foot/"
mkdir -p "$HOME/.config/hypr"
cp "$ZANKEN_PATH/config/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
cp "$ZANKEN_PATH/themes/tokyo-night/colors.toml" "$HOME/.config/zanken/current/next-theme/"
zanken-theme-set-templates
mv "$HOME/.config/zanken/current/next-theme" "$HOME/.config/zanken/current/theme"
if [[ ! -d $HOME/.local/share/icons/Hornet ]]; then
  source "$ZANKEN_INSTALL/config/cursor-hornet.sh"
fi
mkdir -p "$HOME/.icons"
ln -sfn "$HOME/.local/share/icons/Hornet" "$HOME/.icons/Hornet"
source "$ZANKEN_INSTALL/config/desktop-assets.sh"
xdg-mime default zen.desktop x-scheme-handler/http
xdg-mime default zen.desktop x-scheme-handler/https
xdg-mime default zen.desktop text/html
zanken-default-quick-browser qutebrowser
source "$ZANKEN_INSTALL/post-install/release.sh"
trap - EXIT INT TERM
echo "Desktop installed. Backup retained: $DESKTOP_BACKUP"
echo 'Packages and newly added wallpapers/cursor assets are not removed by configuration restore.'
