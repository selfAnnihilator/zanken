#!/bin/bash
set -eEuo pipefail
(( $# == 1 && EUID != 0 )) || { echo 'Usage: bash install/desktop-restore.sh /absolute/backup/path (as regular user)'; exit 2; }
[[ -z ${WAYLAND_DISPLAY:-} && -z ${NIRI_SOCKET:-} ]] || { echo 'Log out and restore from a TTY.'; exit 2; }
DESKTOP_BACKUP=$1
[[ ! -L $DESKTOP_BACKUP && $(dirname "$DESKTOP_BACKUP") == "$HOME" && $(basename "$DESKTOP_BACKUP") == zanken-desktop-backup.* ]] || {
  echo 'Select the original backup directory directly inside your home.'; exit 2;
}
[[ -O $DESKTOP_BACKUP && -d $DESKTOP_BACKUP/original && ! -L $DESKTOP_BACKUP/original && -f $DESKTOP_BACKUP/targets.txt ]] || {
  echo 'Invalid or unowned backup.'; exit 2;
}
source "$(dirname -- "${BASH_SOURCE[0]}")/helpers/desktop-backup.sh"
for target in "${desktop_targets[@]}"; do
  parent=$(dirname "$HOME/$target")
  while [[ $parent != "$HOME" && $parent != "/" ]]; do
    [[ ! -L $parent ]] || { echo "Resolve symlinked parent before restore: $parent"; exit 2; }
    parent=$(dirname "$parent")
  done
done
echo 'This restores desktop configuration only. Packages and added assets stay installed.'
read -r -p 'Type RESTORE to continue: ' answer
[[ $answer == "RESTORE" ]] || exit 0
desktop_restore
