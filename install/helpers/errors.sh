# Error and terminal ownership belong to the original installer process only.
INSTALLER_UI_PID=$BASHPID
ERROR_HANDLING=false
INSTALLER_TTY_STATE=$(stty -g </dev/tty 2>/dev/null || true)
installer_restore_terminal() {
  if [[ -n $INSTALLER_TTY_STATE ]]; then
    stty "$INSTALLER_TTY_STATE" </dev/tty 2>/dev/null || true
  fi
}
show_cursor() { printf '\033[0m\033[?25h'; }
save_original_outputs() { exec 3>&1 4>&2; }
restore_outputs() { exec 1>&3 2>&4; }
show_log_tail() {
  [[ -f $ZANKEN_INSTALL_LOG_FILE ]] || return 0
  # Strip complete ANSI sequences, then remaining control bytes.
  tail -n 15 "$ZANKEN_INSTALL_LOG_FILE" |
    sed -E $'s/\033\\[[0-?]*[ -/]*[@-~]//g' |
    LC_ALL=C tr -d '\000-\010\013-\037\177'
}
catch_errors() {
  local exit_code=${1:-$?}
  [[ $BASHPID == "$INSTALLER_UI_PID" ]] || return "$exit_code"
  [[ $ERROR_HANDLING == "false" ]] || return "$exit_code"
  ERROR_HANDLING=true
  trap - ERR INT TERM
  set +e
  stop_log_output
  restore_outputs
  installer_restore_terminal
  show_cursor
  printf '\r\nInstallation stopped (status %s).\r\n' "$exit_code"
  printf 'Failed stage: %s\r\n\r\n' "${CURRENT_SCRIPT:-unknown}"
  show_log_tail
  printf '\r\nFull log: %s\r\n' "$ZANKEN_INSTALL_LOG_FILE"
  printf 'The installer has exited. Inspect the log before retrying.\r\n'
  exit "$exit_code"
}
exit_handler() {
  local exit_code=$?
  [[ $BASHPID == "$INSTALLER_UI_PID" ]] || return "$exit_code"
  if (( exit_code != 0 )) && [[ $ERROR_HANDLING == "false" ]]; then
    catch_errors "$exit_code"
  else
    stop_log_output
    installer_restore_terminal
    show_cursor
  fi
}
trap 'catch_errors "$?"' ERR
trap 'catch_errors 130' INT
trap 'catch_errors 143' TERM
trap exit_handler EXIT
save_original_outputs
