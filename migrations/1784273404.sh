echo "Remove retired Omarchy package, Walker, and Elephant integration"

if [[ -f /etc/pacman.conf ]] && grep -q '^\[omarchy\]$' /etc/pacman.conf; then
  sudo sed -i '/^\[omarchy\]$/,/^[[:space:]]*$/d' /etc/pacman.conf
fi

systemctl --user disable --now app-walker@autostart.service 2>/dev/null || true
systemctl --user disable --now elephant.service 2>/dev/null || true
systemctl --user daemon-reload

rm -f \
  ~/.config/autostart/walker.desktop \
  ~/.config/systemd/user/app-walker@autostart.service.d/restart.conf \
  ~/.config/elephant/menus/zanken_themes.lua \
  ~/.config/elephant/menus/zanken_background_selector.lua \
  ~/.config/elephant/menus/zanken_unlocks.lua \
  ~/.config/elephant/menus/omarchy_themes.lua \
  ~/.config/elephant/menus/omarchy_background_selector.lua \
  ~/.config/elephant/menus/omarchy_unlocks.lua

if [[ -e /etc/pacman.d/hooks/walker-restart.hook ]]; then
  sudo rm -f /etc/pacman.d/hooks/walker-restart.hook
fi
