if status is-interactive; and type -q psychic
    psychic fish | source
    bind ctrl-o 'pd; commandline --function repaint'
end
