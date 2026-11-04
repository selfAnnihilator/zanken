# Portable, interactive additions; do not replace the user's shell settings.
[[ $- == *i* ]] || return 0
export ZANKEN_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/zanken/current-release/source"
export OMARCHY_PATH="$ZANKEN_PATH"
[[ :$PATH: == *":$ZANKEN_PATH/bin:"* ]] || export PATH="$ZANKEN_PATH/bin:$PATH"
export EDITOR="${EDITOR:-nvim}"
alias t='zanken-launch-zellij'
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons'
alias ..='cd ..'
alias ...='cd ../..'
ff() { fzf --preview 'bat --style=numbers --color=always -- {}'; }
eval "$(zoxide init bash)"
eval "$(mise activate bash)"
eval "$(starship init bash)"
[[ ! -f /usr/share/bash-completion/bash_completion ]] || source /usr/share/bash-completion/bash_completion
[[ ! -f /usr/share/fzf/key-bindings.bash ]] || source /usr/share/fzf/key-bindings.bash
