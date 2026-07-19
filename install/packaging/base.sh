# Install all base packages
mapfile -t packages < <(grep -v '^#' "$ZANKEN_PATH/install/zanken-base.packages" | grep -v '^$')
zanken-pkg-add "${packages[@]}"
