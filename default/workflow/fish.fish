status is-interactive; or return
set -gx ZANKEN_PATH "$HOME/.local/share/zanken/current-release/source"
set -gx OMARCHY_PATH "$ZANKEN_PATH"
fish_add_path --path "$ZANKEN_PATH/bin"
set -q EDITOR; or set -gx EDITOR nvim
zoxide init fish | source
mise activate fish | source
starship init fish | source
alias ls 'eza -lh --group-directories-first --icons=auto'
alias lsa 'ls -a'
alias lt 'eza --tree --level=2 --long --icons'
