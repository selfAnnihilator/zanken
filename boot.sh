#!/bin/bash

set -euo pipefail

# Set install mode to online since boot.sh is used for curl installations
export ZANKEN_ONLINE_INSTALL=true

if [[ ${1:-} == "--replace-niri" ]]; then
  (( EUID != 0 )) || { echo 'Use your regular user, not root.'; exit 2; }
  [[ -z ${WAYLAND_DISPLAY:-} && -z ${NIRI_SOCKET:-} ]] || {
    echo 'Log out and run desktop replacement from a TTY.'; exit 2;
  }
  echo 'Desktop replacement downloads packages and upgrades the Arch package set.'
  read -r -p 'Type REPLACE to begin (configuration backup follows): ' takeover_answer
  [[ $takeover_answer == "REPLACE" ]] || exit 0
fi

printf '\n  斬  Z A N K E N\n  Preparing verified installation source\n\n'

# Release mode is independent of package mirrors. Preserve the host's configured
# Arch repositories; selecting dev must not rewrite pacman configuration.
export ZANKEN_RELEASE_MODE="${ZANKEN_RELEASE_MODE:-stable}"
if [[ $ZANKEN_RELEASE_MODE != "stable" && $ZANKEN_RELEASE_MODE != "dev" ]]; then
  echo "ZANKEN_RELEASE_MODE must be stable or dev" >&2
  exit 2
fi
if [[ -n ${ZANKEN_REF:-} ]]; then
  echo "ZANKEN_REF is retired; use ZANKEN_RELEASE_MODE and ZANKEN_RELEASE_VERSION" >&2
  exit 2
fi
export ZANKEN_REPOSITORY="${ZANKEN_REPOSITORY:-$HOME/zanken}"
if [[ -e $ZANKEN_REPOSITORY && ! -d $ZANKEN_REPOSITORY/.git ]]; then
  echo "Repository destination already exists; choose another ZANKEN_REPOSITORY" >&2
  exit 1
fi
sudo pacman -Syu --noconfirm --needed git python jq
if [[ ! -d $ZANKEN_REPOSITORY/.git ]]; then
  git clone "https://github.com/${ZANKEN_REPO:-selfAnnihilator/zanken}.git" "$ZANKEN_REPOSITORY"
fi
if [[ -n $(git -C "$ZANKEN_REPOSITORY" status --porcelain) ]]; then
  echo "Preserving modified repository; commit your work or select a clean repository" >&2
  exit 1
fi

release_args=("$ZANKEN_RELEASE_MODE" --fetch)
if [[ -n ${ZANKEN_RELEASE_VERSION:-} ]]; then
  release_args+=(--version "$ZANKEN_RELEASE_VERSION")
fi
bootstrap_dir=$(mktemp -d)
bundle_json=$("$ZANKEN_REPOSITORY/bin/zanken-release" bundle "${release_args[@]}" --output "$bootstrap_dir/artifact")
export ZANKEN_INSTALL_COMMIT
ZANKEN_INSTALL_COMMIT=$(jq -er '.candidate.commit' <<<"$bundle_json")
(
  cd "$bootstrap_dir/artifact"
  sha256sum --check SHA256SUMS
)
mkdir "$bootstrap_dir/source"
tar -xf "$bootstrap_dir/artifact/source.tar" -C "$bootstrap_dir/source"
export ZANKEN_RELEASE_INSTALL=1
echo "Installing $ZANKEN_RELEASE_MODE at $ZANKEN_INSTALL_COMMIT"
bash "$bootstrap_dir/source/install.sh" "$@"
# Retain the exact source and artifact for installer failure diagnostics.
echo "Installer source and checksum retained at $bootstrap_dir"
