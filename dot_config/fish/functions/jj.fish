function jj --wraps=jj --description 'jj wrapper with shortcuts'
    # `jj start <words>` — fetch, new off trunk, describe, set bookmark
    if test (count $argv) -ge 2; and test "$argv[1]" = "start"
        set -l trunk main
        if not command jj log -r 'main' --no-graph --limit 1 2>/dev/null | string length -q
            set trunk master
        end

        set -l desc (string join " " $argv[2..])
        set -l bookmark (string join "-" $argv[2..] | string lower)

        command jj git fetch
        command jj new $trunk
        command jj describe -m "$desc"
        command jj bookmark set $bookmark
        echo ">>> On $trunk, bookmark '$bookmark' ready to go."
        return
    end

    # `jj ship` — push, then move off to trunk (you're done with this branch)
    if test (count $argv) -ge 1; and test "$argv[1]" = "ship"
        command jj git push
        set -l push_status $status
        if test $push_status -eq 0
            set -l trunk main
            if not command jj log -r 'main' --no-graph --limit 1 2>/dev/null | string length -q
                set trunk master
            end

            echo ""
            echo ">>> Auto: fetch + new change off $trunk..."
            command jj git fetch
            command jj new $trunk
            echo ">>> Ready for next change."
        end
        return $push_status
    end

    # Everything else — plain pass-through, no hooks
    command jj $argv
    return $status
end
