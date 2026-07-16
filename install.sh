#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Parse flags
ZANKEN_CLEAN=0
for arg in "$@"; do
  [[ "$arg" == "--clean" ]] && ZANKEN_CLEAN=1
done
export ZANKEN_CLEAN

# The installer is executed from the Zanken checkout. Keep the inherited
# OMARCHY_* names as compatibility aliases until the remaining installer
# stages are renamed, but never point them at a separate, nonexistent clone.
export ZANKEN_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export OMARCHY_PATH="$ZANKEN_PATH"
export OMARCHY_INSTALL="$ZANKEN_PATH/install"
export OMARCHY_INSTALL_LOG_FILE="/var/log/omarchy-install.log"
export PATH="$ZANKEN_PATH/bin:$PATH"

# Install
source "$OMARCHY_INSTALL/helpers/all.sh"
source "$OMARCHY_INSTALL/preflight/all.sh"
source "$OMARCHY_INSTALL/packaging/all.sh"
source "$OMARCHY_INSTALL/config/all.sh"
source "$OMARCHY_INSTALL/login/all.sh"
source "$OMARCHY_INSTALL/post-install/all.sh"
