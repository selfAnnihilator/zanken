if [[ -n ${ZANKEN_ONLINE_INSTALL:-} ]]; then
  # Install build tools
  zanken-pkg-add base-devel

  # Zanken uses official repositories plus the AUR for optional software.
  # Bootstrap the AUR helper before the base package stage needs it.
  if zanken-cmd-missing yay; then
    yay_build_dir=$(mktemp -d /tmp/zanken-yay.XXXXXX)
    git clone --depth=1 https://aur.archlinux.org/yay.git "$yay_build_dir/yay"
    (
      cd "$yay_build_dir/yay"
      makepkg -si --noconfirm --needed
    )
    rm -rf "$yay_build_dir"
  fi

  # Release modes do not select package mirrors. Use the host's Arch repositories.
  sudo pacman -Syu --noconfirm
fi
