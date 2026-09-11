# Fixed, user-scoped targets. Never execute a restore manifest as shell code.
desktop_targets=(.config/niri .config/quickshell/zanken .config/foot .config/zanken .config/hypr/hypridle.conf
  .config/gtk-3.0/settings.ini .config/gtk-4.0/settings.ini .config/mimeapps.list
  .local/share/applications/mimeapps.list .icons/default .icons/Brushbuddy .icons/Hornet
  .local/share/zanken .local/state/zanken/releases)
desktop_backup() {
  local target parent
  for target in .config/gtk-3.0/settings.ini .config/gtk-4.0/settings.ini .config/mimeapps.list .local/share/applications/mimeapps.list .icons/default .icons/default/index.theme .local/share/zanken .local/state/zanken/releases .local/share/icons/Hornet .local/share/icons/Brushbuddy .local/share/icons/Brushbuddy/cursors Pictures/wallpaper; do
    [[ ! -L $HOME/$target ]] || { echo "Resolve this symlink before takeover: $HOME/$target" >&2; return 1; }
  done
  # Reject symlinked ancestor directories so writes cannot escape the scope.
  for target in "${desktop_targets[@]}" .local/share/icons/Hornet .local/share/icons/Brushbuddy Pictures/wallpaper; do
    parent=$(dirname "$HOME/$target")
    while [[ $parent != "$HOME" && $parent != "/" ]]; do
      [[ ! -L $parent ]] || { echo "Symlinked parent not supported: $parent" >&2; return 1; }
      parent=$(dirname "$parent")
    done
  done
  DESKTOP_BACKUP=$(mktemp -d "$HOME/zanken-desktop-backup.XXXXXX")
  export DESKTOP_BACKUP
  mkdir "$DESKTOP_BACKUP/original"
  for target in "${desktop_targets[@]}"; do
    if [[ -e $HOME/$target || -L $HOME/$target ]]; then
      mkdir -p "$DESKTOP_BACKUP/original/$(dirname "$target")"
      cp -a "$HOME/$target" "$DESKTOP_BACKUP/original/$target"
    fi
  done
  printf '%s\n' "${desktop_targets[@]}" > "$DESKTOP_BACKUP/targets.txt"
  echo "Desktop backup: $DESKTOP_BACKUP"
}
desktop_restore() {
  local target failed
  [[ -n ${DESKTOP_BACKUP:-} && -d $DESKTOP_BACKUP/original && -f $DESKTOP_BACKUP/targets.txt ]] || return 1
  failed=$(mktemp -d "$DESKTOP_BACKUP/failed.XXXXXX")
  for target in "${desktop_targets[@]}"; do
    if [[ -e $HOME/$target || -L $HOME/$target ]]; then
      mkdir -p "$failed/$(dirname "$target")"
      mv "$HOME/$target" "$failed/$target"
    fi
    if [[ -e $DESKTOP_BACKUP/original/$target || -L $DESKTOP_BACKUP/original/$target ]]; then
      mkdir -p "$HOME/$(dirname "$target")"
      cp -a "$DESKTOP_BACKUP/original/$target" "$HOME/$target"
    fi
  done
  echo "Configuration restored; displaced candidate preserved in $failed"
}
