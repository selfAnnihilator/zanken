# Scrolling console output: no competing full-screen renderer or raw input mode.
if ! command -v gum &>/dev/null; then
  zanken-pkg-add gum
fi
installer_dimensions() {
  local size
  size=$(stty size </dev/tty 2>/dev/null || true)
  read -r TERM_HEIGHT TERM_WIDTH <<<"${size:-24 80}"
  TERM_HEIGHT=${TERM_HEIGHT:-24}
  TERM_WIDTH=${TERM_WIDTH:-80}
  (( TERM_HEIGHT > 0 )) || TERM_HEIGHT=24
  (( TERM_WIDTH > 0 )) || TERM_WIDTH=80
  PADDING_LEFT=2
  (( TERM_WIDTH >= 100 )) && PADDING_LEFT=6
  LOGO_WIDTH=$((TERM_WIDTH - PADDING_LEFT * 2))
  (( LOGO_WIDTH > 100 )) && LOGO_WIDTH=100
  LOGO_HEIGHT=5
  export TERM_HEIGHT TERM_WIDTH PADDING_LEFT LOGO_WIDTH LOGO_HEIGHT
  PADDING_LEFT_SPACES=$(printf '%*s' "$PADDING_LEFT" '')
  export PADDING_LEFT_SPACES
}
installer_dimensions
export GUM_CONFIRM_SELECTED_BACKGROUND=1 GUM_CONFIRM_SELECTED_FOREGROUND=7
export GUM_CHOOSE_CURSOR_FOREGROUND=1 GUM_CHOOSE_SELECTED_FOREGROUND=7
export GUM_CONFIRM_PADDING='1 2' GUM_CHOOSE_PADDING='1 2'
clear_logo() {
  installer_dimensions
  if [[ ${INSTALLER_HEADER_SHOWN:-0} == "1" && ${1:-} != "force" ]]; then
    return 0
  fi
  INSTALLER_HEADER_SHOWN=1
  printf '\033[H\033[2J\033[0m'
  printf '\n%s\033[1;31m斬  Z A N K E N\033[0m\n' "$PADDING_LEFT_SPACES"
  printf '%sNIRI DESKTOP  /  INSTALLER\n\n' "$PADDING_LEFT_SPACES"
}
installer_status() {
  printf '%s%s\n\n' "$PADDING_LEFT_SPACES" "$1"
}
