# Fixed, user-scoped targets. Never execute a restore manifest as shell code.
desktop_targets=(.config/niri .config/quickshell/zanken .config/foot .config/zanken .config/hypr/hypridle.conf
  .config/gtk-3.0/settings.ini .config/gtk-4.0/settings.ini .config/mimeapps.list
  .local/share/applications/mimeapps.list .icons/default .icons/Brushbuddy .icons/Hornet
  .local/share/zanken .local/state/zanken/releases
  .bashrc .config/zellij .config/tmux/tmux.conf .config/starship.toml
  .config/lazygit/config.yml .config/fastfetch/config.jsonc .config/xdg-terminals.list
  .config/fish/conf.d/zanken-workflow.fish .config/fish/conf.d/zanken-zellij.fish
  .config/systemd/user/zanken-zellij-snapshot.service .config/systemd/user/zanken-zellij-snapshot.timer
  .config/systemd/user/zanken-powerprofiles-sync.service)
workflow_units=(zanken-zellij-snapshot.timer zanken-powerprofiles-sync.service)
desktop_backup() {
  local target parent unit enabled active
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
  if [[ ${ZANKEN_INSTALL_WORKFLOW:-0} == "1" ]]; then
    systemctl --user show-environment >/dev/null || return 1
    for unit in "${workflow_units[@]}"; do
      enabled=$(systemctl --user is-enabled "$unit" 2>/dev/null || true)
      active=$(systemctl --user is-active "$unit" 2>/dev/null || true)
      printf '%s %s %s\n' "$unit" "${enabled:-not-found}" "${active:-inactive}" >> "$DESKTOP_BACKUP/services.txt"
    done
  fi
  echo "Desktop backup: $DESKTOP_BACKUP"
}
desktop_restore() {
  local target failed unit enabled active
  [[ -n ${DESKTOP_BACKUP:-} && -d $DESKTOP_BACKUP/original && -f $DESKTOP_BACKUP/targets.txt ]] || return 1
  if [[ -f $DESKTOP_BACKUP/services.txt ]]; then
    for unit in "${workflow_units[@]}"; do
      if systemctl --user cat "$unit" >/dev/null 2>&1; then
        systemctl --user disable --now "$unit" || return 1
      fi
    done
  fi
  failed=$(mktemp -d "$DESKTOP_BACKUP/failed.XXXXXX")
  for target in "${desktop_targets[@]}"; do
    # Older backups have a smaller scope. Never remove newly supported targets
    # that were not captured in the selected backup.
    grep -Fqx "$target" "$DESKTOP_BACKUP/targets.txt" || continue
    if [[ -e $HOME/$target || -L $HOME/$target ]]; then
      mkdir -p "$failed/$(dirname "$target")"
      mv "$HOME/$target" "$failed/$target"
    fi
    if [[ -e $DESKTOP_BACKUP/original/$target || -L $DESKTOP_BACKUP/original/$target ]]; then
      mkdir -p "$HOME/$(dirname "$target")"
      cp -a "$DESKTOP_BACKUP/original/$target" "$HOME/$target"
    fi
  done
  if [[ -f $DESKTOP_BACKUP/services.txt ]]; then
    systemctl --user daemon-reload || return 1
    while read -r unit enabled active; do
      case "$unit" in
        zanken-zellij-snapshot.timer|zanken-powerprofiles-sync.service) ;;
        *) echo "Invalid service backup" >&2; return 1 ;;
      esac
      case "$enabled" in
        enabled) systemctl --user enable "$unit" || return 1 ;;
        enabled-runtime) systemctl --user enable --runtime "$unit" || return 1 ;;
        masked) systemctl --user mask "$unit" || return 1 ;;
        masked-runtime) systemctl --user mask --runtime "$unit" || return 1 ;;
      esac
      if [[ $active == "active" ]]; then systemctl --user start "$unit" || return 1; fi
    done < "$DESKTOP_BACKUP/services.txt"
  fi
  echo "Configuration restored; displaced candidate preserved in $failed"
}
