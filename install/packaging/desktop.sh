mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "$ZANKEN_PATH/install/zanken-desktop.packages")
zanken-pkg-add "${packages[@]}"
