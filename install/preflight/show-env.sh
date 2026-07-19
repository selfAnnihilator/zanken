# Show installation environment variables
gum log --level info "Installation Environment:"

env | grep -E "^(ZANKEN_CHROOT_INSTALL|ZANKEN_ONLINE_INSTALL|ZANKEN_USER_NAME|ZANKEN_USER_EMAIL|USER|HOME|ZANKEN_REPO|ZANKEN_REF|ZANKEN_PATH)=" | sort | while IFS= read -r var; do
  gum log --level info "  $var"
done
