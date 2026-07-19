echo "Disable the legacy Quickshell desktop post-boot launcher"

HOOK_DIR="$HOME/.config/zanken/hooks/post-boot.d"
LEGACY_HOOK="$HOOK_DIR/quickshell-desktop"

# Niri starts the managed `zanken` Quickshell configuration itself. Older
# desktop installs left this hook behind, which starts a second `desktop`
# configuration and produces a duplicate bar. Preserve the old hook outside
# the hook runner's glob so it can be recovered if needed.
if [[ -f $LEGACY_HOOK ]] && grep -Fqx 'qs -n -d -c desktop' "$LEGACY_HOOK"; then
  mkdir -p "$HOOK_DIR/disabled"
  mv "$LEGACY_HOOK" "$HOOK_DIR/disabled/quickshell-desktop"
fi
