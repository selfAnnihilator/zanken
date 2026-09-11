stop_install_log
clear_logo
installer_status 'COMPLETE  •  Zanken is ready for a fresh session'
printf '%sLog: %s\n\n' "$PADDING_LEFT_SPACES" "$ZANKEN_INSTALL_LOG_FILE"
if [[ ${ZANKEN_INSTALL_MODE:-full} != "desktop" ]] && sudo test -f /etc/sudoers.d/99-zanken-installer; then
  sudo rm -f /etc/sudoers.d/99-zanken-installer
fi
if [[ ${ZANKEN_INSTALL_MODE:-full} == "desktop" ]]; then
  echo 'Log out and choose Niri to start Zanken. No reboot is required.'
elif gum confirm --default=false 'Reboot now?'; then
  if [[ -n ${ZANKEN_CHROOT_INSTALL:-} ]]; then
    touch /var/tmp/zanken-install-completed
  else
    sudo reboot
  fi
fi
