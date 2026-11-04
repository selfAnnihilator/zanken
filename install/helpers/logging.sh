# Only the parent owns interactive input and error reporting.
start_log_output() {
  (
    trap - ERR EXIT
    sleeper=
    trap '[[ -z $sleeper ]] || kill "$sleeper" 2>/dev/null; exit 0' TERM INT
    set +e
    local elapsed=0
    while true; do
      sleep 15 & sleeper=$!
      wait "$sleeper" || exit 0
      elapsed=$((elapsed + 15))
      printf '\r\n  Still running: %s (%ss)\r\n' "$CURRENT_STAGE" "$elapsed" || exit 0
    done
  ) &
  monitor_pid=$!
}
stop_log_output() {
  if [[ -n ${monitor_pid:-} ]]; then
    kill "$monitor_pid" 2>/dev/null || true
    wait "$monitor_pid" 2>/dev/null || true
    unset monitor_pid
  fi
  if [[ -n ${ZANKEN_AUTH_PID:-} ]]; then
    kill "$ZANKEN_AUTH_PID" 2>/dev/null || true
    wait "$ZANKEN_AUTH_PID" 2>/dev/null || true
    unset ZANKEN_AUTH_PID
  fi
}
installer_authenticate() {
  stop_log_output
  if ! command sudo -n -v 2>/dev/null; then
    clear_logo force
    installer_status 'AUTHENTICATION  •  Enter your password below'
    local auth_status=0
    command sudo -v </dev/tty >/dev/tty 2>&1 || auth_status=$?
    if declare -F installer_restore_terminal >/dev/null; then installer_restore_terminal; fi
    clear_logo force
    (( auth_status == 0 )) || return "$auth_status"
  fi
  clear_logo
}
start_install_log() {
  installer_authenticate
  command sudo touch "$ZANKEN_INSTALL_LOG_FILE"
  command sudo chown "$(id -un)" "$ZANKEN_INSTALL_LOG_FILE"
  chmod 600 "$ZANKEN_INSTALL_LOG_FILE"
  export ZANKEN_START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
  echo "=== Zanken started: $ZANKEN_START_TIME ===" >>"$ZANKEN_INSTALL_LOG_FILE"
}
stop_install_log() {
  stop_log_output
  installer_restore_terminal
  show_cursor
  echo "=== Zanken stages completed: $(date -Is) ===" >>"$ZANKEN_INSTALL_LOG_FILE"
}
run_logged() {
  local script=$1 exit_code=0
  export CURRENT_SCRIPT="$script"
  export CURRENT_STAGE="${script#"$ZANKEN_INSTALL/"}"
  installer_authenticate
  printf '\r\n  Installing: %s\r\n  Log: %s\r\n' "$CURRENT_STAGE" "$ZANKEN_INSTALL_LOG_FILE"
  echo "Starting: $CURRENT_STAGE" >>"$ZANKEN_INSTALL_LOG_FILE"
  (
    trap - ERR EXIT
    sleeper=
    trap '[[ -z $sleeper ]] || kill "$sleeper" 2>/dev/null; exit 0' TERM INT
    while true; do
      sleep 30 & sleeper=$!
      wait "$sleeper" || break
      command sudo -n -v 2>/dev/null || break
    done
  ) >/dev/null 2>&1 &
  ZANKEN_AUTH_PID=$!
  start_log_output
  if ZANKEN_MAKEPKG_BASE_CONF="${MAKEPKG_CONF:-/etc/makepkg.conf}" \
    MAKEPKG_CONF="$ZANKEN_INSTALL/helpers/makepkg.conf" \
    PATH="$ZANKEN_INSTALL/helpers/noninteractive:$PATH" bash -eE -c 'source "$1"' bash "$script" </dev/null >>"$ZANKEN_INSTALL_LOG_FILE" 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi
  stop_log_output
  if declare -F installer_restore_terminal >/dev/null; then installer_restore_terminal; fi
  echo "Finished: $CURRENT_STAGE (status $exit_code)" >>"$ZANKEN_INSTALL_LOG_FILE"
  printf '  Finished: %s (status %s)\r\n' "$CURRENT_STAGE" "$exit_code"
  if (( exit_code == 0 )); then unset CURRENT_SCRIPT; fi
  return "$exit_code"
}
