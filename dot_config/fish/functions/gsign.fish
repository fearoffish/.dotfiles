function gsign --description 'Sign every commit on this branch, merges included (1Password SSH key)'
    set -l onto $argv[1]

    if test -z "$onto"
        set onto (git merge-base HEAD origin/HEAD)
        if test -z "$onto"
            echo 'gsign: no merge base with origin/HEAD' >&2
            return 1
        end
    end

    if test (git rev-list --count $onto..HEAD) -eq 0
        echo "gsign: no commits above $onto"
        return 0
    end

    set -l unsigned (git log --format='%G?' $onto..HEAD | string match --invert G)
    if not set -q unsigned[1]
        echo 'gsign: every commit is signed already'
        return 0
    end

    # Prove the key is reachable before anything is rewritten: filter-branch does
    # not roll back, so a locked agent would otherwise leave the branch part
    # signed. The probe commit is unreachable and gets pruned.
    if not git commit-tree -S HEAD^{tree} -p HEAD -m 'gsign probe' >/dev/null 2>&1
        echo 'gsign: cannot sign, is the 1Password agent unlocked?' >&2
        return 1
    end

    set -l before (git rev-parse HEAD)

    # filter-branch rather than rebase: it reuses each commit's existing tree and
    # parents, so merge commits keep the resolutions they were made with and there
    # is nothing to replay and nothing that can conflict.
    # -f because the backup ref this leaves behind is cleared below, so a stale one
    # from an earlier run must not block the next. The reflog is the way back.
    env FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f \
        --commit-filter 'git commit-tree -S "$@"' -- $onto..HEAD
    or return 1

    for ref in (git for-each-ref --format='%(refname)' refs/original)
        git update-ref -d $ref
    end

    echo "gsign: "(count $unsigned)" unsigned, rewrote "(git rev-list --count $onto..HEAD)" commits, was $before"
    git log --format='%G?' $onto..HEAD | sort | uniq -c
end
