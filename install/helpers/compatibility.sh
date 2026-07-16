# Transitional compatibility for installer stages inherited from Omarchy.
#
# The project binaries are named zanken-*. A number of sourced installer
# stages still call omarchy-* commands; provide aliases only for this install
# process so a fresh checkout remains self-contained while those stages are
# migrated incrementally.
ZANKEN_INSTALL_COMPAT_BIN_DIR=$(mktemp -d "${TMPDIR:-/tmp}/zanken-install-bin.XXXXXX")

for zanken_command in "$ZANKEN_PATH"/bin/zanken-*; do
  [[ -x $zanken_command ]] || continue
  legacy_name="${zanken_command##*/zanken-}"
  ln -s "$zanken_command" "$ZANKEN_INSTALL_COMPAT_BIN_DIR/omarchy-$legacy_name"
done

export PATH="$ZANKEN_INSTALL_COMPAT_BIN_DIR:$PATH"
