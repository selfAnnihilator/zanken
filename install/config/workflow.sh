# Release activation installs versioned defaults; this stage owns integration.
workflow_bash_line='[[ ! -f "$HOME/.config/zanken/workflow.bash" ]] || source "$HOME/.config/zanken/workflow.bash"'
if [[ -L $HOME/.bashrc ]]; then
  workflow_bash_copy=$(mktemp "$HOME/.bashrc.XXXXXX")
  cat "$HOME/.bashrc" > "$workflow_bash_copy"
  mv "$workflow_bash_copy" "$HOME/.bashrc"
fi
if ! grep -Fqx "$workflow_bash_line" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n%s\n' "$workflow_bash_line" >> "$HOME/.bashrc"
fi
systemctl --user daemon-reload
systemctl --user enable --now zanken-zellij-snapshot.timer
if [[ -e /sys/firmware/acpi/platform_profile ]] && systemctl is-active --quiet power-profiles-daemon &&
  ! systemctl is-active --quiet tlp && ! systemctl is-active --quiet auto-cpufreq; then
  systemctl --user enable --now zanken-powerprofiles-sync.service
fi
