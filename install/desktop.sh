#!/bin/bash
set -eEo pipefail
(( $# == 0 )) || { echo 'Usage: install.sh --desktop' >&2; exit 2; }
(( EUID != 0 )) || { echo 'Run as your regular user, not root.' >&2; exit 2; }
command -v pacman >/dev/null || { echo 'An Arch-based system is required.' >&2; exit 2; }
[[ -z ${WAYLAND_DISPLAY:-} && -z ${NIRI_SOCKET:-} ]] || {
  echo 'Log out of the graphical session and run from a TTY to replace Niri safely.' >&2; exit 2;
}
[[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" && ${XDG_DATA_HOME:-$HOME/.local/share} == "$HOME/.local/share" && ${XDG_STATE_HOME:-$HOME/.local/state} == "$HOME/.local/state" ]] || {
  echo 'Custom XDG roots are not supported by the takeover installer yet.' >&2; exit 2;
}
[[ ${ZANKEN_RELEASE_INSTALL:-0} == "1" ]] || {
  echo 'Use the verified boot.sh entry point with --replace-niri.' >&2; exit 2;
}
[[ ! -e $HOME/.local/state/zanken/releases/installed.json ]] || {
  echo 'This is already a managed Zanken release. Use release update/rollback instead.' >&2; exit 2;
}
export ZANKEN_INSTALL_MODE=desktop
export ZANKEN_INSTALL_WORKFLOW=1
export ZANKEN_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export ZANKEN_INSTALL="$ZANKEN_PATH/install"
export ZANKEN_INSTALL_LOG_FILE=/var/log/zanken-install.log
export PATH="$ZANKEN_PATH/bin:$PATH"
export ZANKEN_HARDWARE_REPORT
ZANKEN_HARDWARE_REPORT=$(mktemp)
python3 -B "$ZANKEN_PATH/lib/zanken/hardware.py" plan "$ZANKEN_HARDWARE_REPORT"
python3 -B "$ZANKEN_PATH/lib/zanken/workflow.py" preflight "$ZANKEN_PATH"
python3 -B "$ZANKEN_PATH/lib/zanken/login.py" preflight "$ZANKEN_PATH"
python3 -B "$ZANKEN_PATH/lib/zanken/boot.py" preflight "$ZANKEN_PATH"
source "$ZANKEN_INSTALL/helpers/all.sh"
clear_logo
installer_status 'INSTALL DESKTOP AND WORKFLOW'
echo 'Replaces Niri entry point, Zanken bar, Foot, cursor settings and browser shortcuts.'
echo 'Backs up affected configuration first. Personal files and browser profiles stay.'
echo 'Enables the Pixel Sakura password login screen and boot animation for the next boot. Preserves bootloader and partitions.'
if command -v gum >/dev/null; then
  gum confirm --default=false 'Back up and replace this desktop?' || exit 0
else
  read -r -p 'Type INSTALL to back up and install the desktop and workflow: ' install_answer
  [[ $install_answer == "INSTALL" ]] || exit 0
fi
start_install_log
cat "$ZANKEN_HARDWARE_REPORT" >> "$ZANKEN_INSTALL_LOG_FILE"
run_logged "$ZANKEN_INSTALL/preflight/pacman.sh"
# Package refresh can change kernels; re-evaluate before any graphics changes.
python3 -B "$ZANKEN_PATH/lib/zanken/hardware.py" plan "$ZANKEN_HARDWARE_REPORT"
python3 -B "$ZANKEN_PATH/lib/zanken/hardware.py" apply "$ZANKEN_HARDWARE_REPORT" 2>&1 | tee -a "$ZANKEN_INSTALL_LOG_FILE"
run_logged "$ZANKEN_INSTALL/packaging/desktop.sh"
run_logged "$ZANKEN_INSTALL/config/replace-desktop.sh"
run_logged "$ZANKEN_INSTALL/login/desktop.sh"
mkdir -p "$HOME/.local/state/zanken/install"
cp "$ZANKEN_HARDWARE_REPORT" "$HOME/.local/state/zanken/install/hardware.json"
rm -f "$ZANKEN_HARDWARE_REPORT"
source "$ZANKEN_INSTALL/post-install/finished.sh"
