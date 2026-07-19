# Set identification from install inputs
if [[ -n ${ZANKEN_USER_NAME//[[:space:]]/} ]]; then
  git config --global user.name "$ZANKEN_USER_NAME"
fi

if [[ -n ${ZANKEN_USER_EMAIL//[[:space:]]/} ]]; then
  git config --global user.email "$ZANKEN_USER_EMAIL"
fi
