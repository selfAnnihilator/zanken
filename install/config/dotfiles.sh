# Check out the compositor and shell configuration from the authoritative repo.
# This deliberately limits checkout to Niri and Quickshell so an installation
# never overwrites unrelated user files in $HOME.
ZANKEN_DOTFILES_REPO="${ZANKEN_DOTFILES_REPO:-https://github.com/selfAnnihilator/dotfiles.git}"
ZANKEN_DOTFILES_DIR="${ZANKEN_DOTFILES_DIR:-$HOME/dotfiles}"
ZANKEN_DOTFILES_BRANCH="${ZANKEN_DOTFILES_BRANCH:-main}"

if [[ ! -d $ZANKEN_DOTFILES_DIR ]]; then
  git clone --bare "$ZANKEN_DOTFILES_REPO" "$ZANKEN_DOTFILES_DIR"
  git --git-dir="$ZANKEN_DOTFILES_DIR" config --local status.showUntrackedFiles no
else
  git --git-dir="$ZANKEN_DOTFILES_DIR" fetch --prune origin "+refs/heads/$ZANKEN_DOTFILES_BRANCH:refs/heads/$ZANKEN_DOTFILES_BRANCH"
fi

git --git-dir="$ZANKEN_DOTFILES_DIR" --work-tree="$HOME" \
  checkout --force "$ZANKEN_DOTFILES_BRANCH" -- .config/niri .config/quickshell
