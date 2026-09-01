if [[ -f /etc/sudoers.d/99-zanken-installer-reboot ]]; then
  sudo /usr/bin/rm -f /etc/sudoers.d/99-zanken-installer-reboot
fi
