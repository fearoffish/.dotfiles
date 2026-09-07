function gsign --description 'Sign my own commits on this branch, merges included (1Password SSH key)'
    set -l onto $argv[1]
    set -l me (git config user.email)

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

    set -l unsigned (git log --author=$me --format='%G? %H' $onto..HEAD | string match --invert -r '^G ' | string replace -r '^. ' '')
    if not set -q unsigned[1]
        echo "gsign: every commit by $me is signed already"
        return 0
    end

    # Rewriting a commit rewrites every descendant, so someone else's commit
    # above one of my unsigned ones would change id. Those are not mine to touch.
    set -l theirs
    for commit in $unsigned
        set -a theirs (git log --ancestry-path --format='%ae %h %an: %s' $commit..HEAD | string match --invert "$me *")
    end
    if set -q theirs[1]
        echo 'gsign: refusing, signing would rewrite commits that are not mine:' >&2
        printf '%s\n' $theirs | string replace -r '^\S+ ' '' | sort -u >&2
        echo 'rebase my commits above theirs first, or pass an explicit base' >&2
        return 1
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
    # Only my commits get a signature. Everyone else's is echoed back unchanged;
    # the check above guarantees their parents have not moved, and if that ever
    # fails the filter aborts before the branch ref is touched.
    # -f because the backup ref this leaves behind is cleared below, so a stale one
    # from an earlier run must not block the next. The reflog is the way back.
    env FILTER_BRANCH_SQUELCH_WARNING=1 GSIGN_ME=$me git filter-branch -f \
        --commit-filter '
            if test "$GIT_AUTHOR_EMAIL" = "$GSIGN_ME"; then
                git commit-tree -S "$@"
            elif test "$(git rev-parse "$GIT_COMMIT^@")" = "$(shift; printf "%s\n" "$@" | grep -v "^-p$")"; then
                echo "$GIT_COMMIT"
            else
                echo "gsign: would rewrite $GIT_COMMIT by $GIT_AUTHOR_EMAIL, aborting" >&2
                exit 1
            fi' -- $onto..HEAD
    or return 1

    for ref in (git for-each-ref --format='%(refname)' refs/original)
        git update-ref -d $ref
    end

    echo "gsign: signed "(count $unsigned)" of mine, was $before"
    git log --format='%G? %ae' $onto..HEAD | sort | uniq -c
end
