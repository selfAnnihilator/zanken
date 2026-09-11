#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Existing systems get a scoped desktop takeover, never full OS provisioning.
if [[ ${1:-} == "--replace-niri" ]]; then
  shift
  exec bash "$(dirname -- "${BASH_SOURCE[0]}")/install/desktop.sh" "$@"
fi

# Parse flags
ZANKEN_CLEAN=0
for arg in "$@"; do
  [[ "$arg" == "--clean" ]] && ZANKEN_CLEAN=1
done
export ZANKEN_CLEAN

# The installer is executed from the Zanken checkout.
export ZANKEN_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export ZANKEN_INSTALL="$ZANKEN_PATH/install"
export ZANKEN_INSTALL_LOG_FILE="/var/log/zanken-install.log"
export PATH="$ZANKEN_PATH/bin:$PATH"

# Install
source "$ZANKEN_INSTALL/helpers/all.sh"
source "$ZANKEN_INSTALL/preflight/all.sh"
source "$ZANKEN_INSTALL/packaging/all.sh"
source "$ZANKEN_INSTALL/config/all.sh"
source "$ZANKEN_INSTALL/login/all.sh"
source "$ZANKEN_INSTALL/post-install/all.sh"
