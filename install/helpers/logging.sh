start_log_output() {
  (
    while true; do
      clear_logo
      installer_status "INSTALLING  •  ${CURRENT_STAGE:-Preparing}"
      local lines=$((TERM_HEIGHT - 11)) width=$((LOGO_WIDTH - 2)) line
      (( lines < 1 )) && lines=1
      (( width < 10 )) && width=10
      while IFS= read -r line; do
        line=$(printf '%s' "$line" | LC_ALL=C tr -d '\000-\010\013-\037\177')
        printf '%s\033[90m%s\033[0m\n' "$PADDING_LEFT_SPACES" "${line:0:width}"
      done < <(tail -n "$lines" "$ZANKEN_INSTALL_LOG_FILE" 2>/dev/null)
      printf '\n%sLog: %s\n' "$PADDING_LEFT_SPACES" "$ZANKEN_INSTALL_LOG_FILE"
      sleep 0.5
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
    clear_logo
    installer_status 'AUTHENTICATION  •  Enter your password below'
    # sudo owns input. Passwords never pass through tee or the install log.
    command sudo -v </dev/tty >/dev/tty 2>&1 || return $?
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
  show_cursor
  echo "=== Zanken stages completed: $(date -Is) ===" >>"$ZANKEN_INSTALL_LOG_FILE"
}
run_logged() {
  local script=$1 exit_code=0
  export CURRENT_SCRIPT="$script"
  export CURRENT_STAGE="${script#"$ZANKEN_INSTALL/"}"
  installer_authenticate
  echo "Starting: $CURRENT_STAGE" >>"$ZANKEN_INSTALL_LOG_FILE"
  (
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
  # Hidden stages never ask for a password; the parent authenticates first.
  if PATH="$ZANKEN_INSTALL/helpers/noninteractive:$PATH" bash -eE -c 'source "$1"' bash "$script" </dev/null >>"$ZANKEN_INSTALL_LOG_FILE" 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi
  stop_log_output
  echo "Finished: $CURRENT_STAGE (status $exit_code)" >>"$ZANKEN_INSTALL_LOG_FILE"
  if (( exit_code == 0 )); then unset CURRENT_SCRIPT; fi
  return "$exit_code"
}
