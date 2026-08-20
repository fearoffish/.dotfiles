function j --description 'Fuzzy find a directory under $jump_roots and cd into it'
    set -q jump_roots[1]; or set -l jump_roots $HOME/a

    set -l roots (path filter --type=dir -- $jump_roots)
    if not set -q roots[1]
        echo 'j: none of $jump_roots exist' >&2
        return 1
    end

    # --follow because repos moved to the sandvault shared folder are left behind
    # as symlinks, which fd skips otherwise. Hidden directories are skipped and
    # .gitignore is honoured, so .git and node_modules stay out of the list.
    # --select-1/--exit-0 make `j <query>` jump straight there when it is unambiguous.
    set -l dir (begin
            printf '%s\n' $roots
            fd --type=dir --follow --absolute-path --color=never . $roots 2>/dev/null
        end | string replace -r '/$' '' | fzf --scheme=path --query="$argv" --select-1 --exit-0 \
            --height=60% --reverse --prompt='jump> ' \
            --preview-window='right,55%' \
            --preview='eza --tree --level=2 --color=always --group-directories-first --ignore-glob=.git {}')

    # Empty on cancel; return success so the prompt does not show a failed status
    test -n "$dir"; or return 0
    cd $dir
end
