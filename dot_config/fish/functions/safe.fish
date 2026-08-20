function safe --description "Run a command inside the Agent Safehouse sandbox"
    # Extra read-only grants, e.g. set -l ro_dirs $HOME/docs $HOME/scripts
    set -l ro_dirs

    set -l ro_flag
    if set -q ro_dirs[1]
        set ro_flag --add-dirs-ro=(string join ":" $ro_dirs)
    end

    command safehouse $ro_flag $argv
end
