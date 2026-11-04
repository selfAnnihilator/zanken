if [[ ${ZANKEN_RELEASE_INSTALL:-0} == "1" ]]; then
  # The installer is running from the already verified, pinned source archive.
  # Generation activation occurs after the remaining system provisioning steps.
  echo "Desktop activation deferred until system provisioning completes"
else
  zanken-config-desktop adopt
fi
