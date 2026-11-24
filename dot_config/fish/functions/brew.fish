function brew --wraps brew --description "Homebrew, recording installs and uninstalls in the dotfiles Brewfiles"
    command brew $argv
    set -l result $status

    if test $result -eq 0; and status is-interactive; and contains -- "$argv[1]" install uninstall remove rm
        set -l names (string match -v -- '-*' $argv[2..])
        set -l flag
        test "$argv[1]" != install; and set flag --uninstalled
        set -q names[1]; and brewsync $flag $names
    end
    return $result
end
