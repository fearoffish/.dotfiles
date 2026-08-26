function claude --description "Claude Code, sandboxed by Agent Safehouse"
    safe --enable=clipboard,cleanshot,1password \
        --append-profile ~/.config/safehouse/image-paste.sb \
        claude --dangerously-skip-permissions $argv
end
