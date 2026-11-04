if status is-interactive
  function t --description 'Attach to or restore a Zellij workspace'
    zanken-launch-zellij $argv
  end

  # Sessions switched through Zellij's own picker bypass the launcher, so mark
  # the session as most recent whenever a command starts in it.
  function __zanken_zellij_active --on-event fish_preexec
    set -q ZELLIJ_SESSION_NAME; or return
    set -l state_home $XDG_STATE_HOME
    test -n "$state_home"; or set state_home $HOME/.local/state
    set -l last_file $state_home/zanken/zellij-last-session
    test -f $last_file; and test (head -n 1 $last_file 2>/dev/null) = $ZELLIJ_SESSION_NAME; and return
    zanken-cmd-zellij-session active $ZELLIJ_SESSION_NAME &>/dev/null &
    disown
  end
end
