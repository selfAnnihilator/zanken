if [[ ${ZANKEN_RELEASE_INSTALL:-0} == "1" ]]; then
  release_args=(switch "$ZANKEN_RELEASE_MODE" --adopt --expect-commit "$ZANKEN_INSTALL_COMMIT")
  if [[ -n ${ZANKEN_RELEASE_VERSION:-} ]]; then
    release_args+=(--version "$ZANKEN_RELEASE_VERSION")
  fi
  "$ZANKEN_REPOSITORY/bin/zanken-release" "${release_args[@]}"
fi
