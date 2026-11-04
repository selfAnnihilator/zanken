#!/bin/bash
# Visual-only harness. Never authenticates, installs packages or changes config.
set -e
command -v gum >/dev/null || { echo 'gum is required for this visual test.'; exit 1; }
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export ZANKEN_PATH=${ZANKEN_DEMO_SOURCE:-$root}
source "$ZANKEN_PATH/install/helpers/presentation.sh"
trap 'printf "\033[0m\033[?25h"' EXIT
clear_logo
if [[ ${1:-} == "--reference" ]]; then
  printf '%sInstalling...\n\n' "$PADDING_LEFT_SPACES"
  printf '%s  Building desktop packages...\n' "$PADDING_LEFT_SPACES"
  read -r -p 'Reference preview only. Enter to close: '
  exit 0
fi
installer_status 'AUTHENTICATION  •  Preview only; no password needed'
read -r -p 'Press Enter to simulate successful authentication: '
clear_logo
installer_status 'INSTALLING  •  Desktop assets'
printf '%s\n' '      ✓ Existing Yay reused' '      ✓ Wallpaper library verified' '      ✓ Zen and qutebrowser shortcuts prepared' '      → Installing Brushbuddy; keeping Hornet'
printf '\n%s\n' '      Preview only. Press Enter for the completion screen.'
read -r
clear_logo
installer_status 'COMPLETE  •  Zanken desktop configuration ready'
printf '%s\n' '      Configuration backup retained.' '      Start a new Niri session to verify the desktop.'
read -r -p 'Preview only. Enter to close: '
