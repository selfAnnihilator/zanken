source $ZANKEN_INSTALL/preflight/guard.sh
source $ZANKEN_INSTALL/preflight/begin.sh
run_logged $ZANKEN_INSTALL/preflight/show-env.sh
run_logged $ZANKEN_INSTALL/preflight/pacman.sh
run_logged $ZANKEN_INSTALL/preflight/migrations.sh
run_logged $ZANKEN_INSTALL/preflight/first-run-mode.sh
run_logged $ZANKEN_INSTALL/preflight/disable-mkinitcpio.sh
