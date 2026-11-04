# Resolve boot packages before any boot configuration is changed.
prepare_limine_packages() {
  limine_package_args=()
  local package metadata
  local -a archives=() selected=()
  if [[ -n ${ZANKEN_LIMINE_PACKAGE_DIR:-} ]]; then
    for package in limine-snapper-sync limine-mkinitcpio-hook; do
      archives=("$ZANKEN_LIMINE_PACKAGE_DIR/$package/$package-"*.pkg.tar.zst)
      if (( ${#archives[@]} != 1 )) || [[ ! -f ${archives[0]} ]]; then
        echo "Expected exactly one built archive for $package in $ZANKEN_LIMINE_PACKAGE_DIR" >&2
        return 1
      fi
      metadata=$(LC_ALL=C pacman -Qp "${archives[0]}") || return 1
      if [[ $metadata != "$package "* ]]; then
        echo "Wrong package identity in ${archives[0]}" >&2
        return 1
      fi
      selected+=("${archives[0]}")
    done
    limine_package_args=(-U --needed "${selected[@]}")
  elif pacman -Q limine-snapper-sync limine-mkinitcpio-hook &>/dev/null; then
    return 0
  elif pacman -Si limine-snapper-sync limine-mkinitcpio-hook &>/dev/null; then
    limine_package_args=(-S --needed limine-snapper-sync limine-mkinitcpio-hook)
  else
    echo "Boot packages unavailable in configured repositories. Build them first and set ZANKEN_LIMINE_PACKAGE_DIR; boot configuration was not changed." >&2
    return 1
  fi
}
