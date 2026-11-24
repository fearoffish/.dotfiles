function brewsync --description "Reconcile installed Homebrew packages with the dotfiles Brewfiles"
    # Optional arguments narrow the run to those packages, e.g. after `brew install foo`.
    # --uninstalled makes dropping the default, for use right after `brew uninstall`.
    argparse uninstalled -- $argv
    or return 1
    set -l src (chezmoi source-path)
    or return 1
    set -l host (chezmoi execute-template '{{ .host }}')
    or return 1
    set -l shared $src/Brewfile
    set -l hostfile $src/hosts/$host/Brewfile
    set -l ignorefile $src/hosts/$host/brew-ignore
    set -l entry_re '^(tap|brew|cask|mas|go|cargo|uv|npm|vscode) "[^"]+"'

    # The dump lists formulae installed on request only, so dependencies stay out.
    set -l dump (command brew bundle dump --file=- 2>/dev/null)
    or begin
        echo "brewsync: brew bundle dump failed" >&2
        return 1
    end

    set -l installed (string match -r -- $entry_re $dump)
    set -l host_listed
    test -f $hostfile; and set host_listed (string match -r -- $entry_re <$hostfile)
    set -l listed (string match -r -- $entry_re <$shared) $host_listed
    set -l ignored
    test -f $ignorefile; and set ignored (string match -r -- $entry_re <$ignorefile)

    set -l extra
    for key in $installed
        contains -- $key $listed $ignored; or set -a extra $key
    end
    set -l missing
    for key in $listed
        contains -- $key $installed $ignored; or set -a missing $key
    end
    set -l both
    for key in $host_listed
        test (count (__dotfiles_hosts_with $src $host Brewfile "^\Q$key\E")) -gt 0; and set -a both $key
    end

    if set -q argv[1]
        set extra (__brewsync_scope $extra -- $argv)
        set missing (__brewsync_scope $missing -- $argv)
        set both (__brewsync_scope $both -- $argv)
    end

    if not set -q extra[1]; and not set -q missing[1]; and not set -q both[1]
        echo "brewsync: Brewfiles match what's installed on $host"
        return 0
    end

    for key in $extra
        set -l block (__brewsync_block $key $dump)
        set -l others (__dotfiles_hosts_with $src $host Brewfile "^\Q$key\E")
        set -l choice
        if set -q others[1]
            read -P "Installed, tracked on $others: $key  [S]hared, moving it from $others / [h]ost $host / [i]gnore / [l]ater: " choice
            or return 1
            test -z "$choice"; and set choice s
        else
            read -P "Installed, not tracked: $key  [H]ost $host / [s]hared / [i]gnore / [l]ater: " choice
            or return 1
            test -z "$choice"; and set choice h
        end
        switch (string lower -- $choice)
            case h
                __brewsync_insert $hostfile $block
                echo "  added to hosts/$host/Brewfile"
            case s
                __brewsync_insert $shared $block
                for other in $others
                    __brewsync_drop $src/hosts/$other/Brewfile $key
                end
                echo "  added to Brewfile"
            case i
                echo $key >>$ignorefile
                echo "  added to hosts/$host/brew-ignore"
        end
    end

    for key in $missing
        set -l file $hostfile
        contains -- $key $host_listed; or set file $shared
        set -l name (string replace -- "$src/" '' $file)

        set -l prompt "[d]rop from file / [i]nstall / [L]ater"
        set -q _flag_uninstalled; and set prompt "[D]rop from file / [i]nstall / [l]ater"
        read -P "Tracked in $name, not installed: $key  $prompt: " choice
        or return 1
        test -z "$choice"; and set -q _flag_uninstalled; and set choice d
        switch (string lower -- $choice)
            case d
                __brewsync_drop $file $key
                echo "  dropped from $name"
            case i
                string match -r -- "^\Q$key\E.*" <$file | command brew bundle install --file=-
        end
    end

    for key in $both
        # An earlier answer may already have dropped it from this host.
        contains -- $key (string match -r -- $entry_re <$hostfile); or continue
        set -l others (__dotfiles_hosts_with $src $host Brewfile "^\Q$key\E")
        read -l -P "In both hosts/$host and hosts/$others Brewfiles: $key  [m]ove to shared / [L]ater: " choice
        or return 1
        switch (string lower -- $choice)
            case m
                __brewsync_insert $shared (__brewsync_block $key (cat $hostfile))
                for h in $host $others
                    __brewsync_drop $src/hosts/$h/Brewfile $key
                end
                echo "  moved to Brewfile"
        end
    end

    echo "brewsync: review with git -C $src diff"
end

function __brewsync_scope --description "Keep Brewfile keys matching the given package names"
    set -l i (contains -i -- -- $argv)
    test $i -gt 1; or return 0
    set -l keys $argv[1..(math $i - 1)]
    set -l names $argv[(math $i + 1)..]
    for key in $keys
        set -l entry (string match -r -- '"([^"]+)"' $key)[2]
        for name in $names
            # Matches plain names, tap-qualified names and the tap a formula came from.
            if test "$entry" = "$name"; or string match -q -- "*/$name" $entry; or string match -q -- "$entry/*" $name
                echo $key
                break
            end
        end
    end
end

function __brewsync_block --description "Print a Brewfile entry with the description comment above it"
    set -l key $argv[1]
    set -l lines $argv[2..]
    set -l line (string match -r -- "^\Q$key\E.*" $lines)[1]
    set -l at (contains -i -- $line $lines)
    if test $at -gt 1; and string match -q -- '# *' $lines[(math $at - 1)]
        echo $lines[(math $at - 1)]
    end
    echo $line
end

function __brewsync_insert --description "Insert lines after the last entry of the same type"
    set -l file $argv[1]
    set -l block $argv[2..]
    set -l type (string split -m1 ' ' -- $block[-1])[1]
    BLOCK=(string join \n -- $block | string collect) TYPE=$type awk '
        { lines[NR] = $0; if (index($0, ENVIRON["TYPE"] " \"") == 1) last = NR }
        END {
            if (!last) last = NR
            for (n = 1; n <= NR; n++) { print lines[n]; if (n == last) print ENVIRON["BLOCK"] }
            if (NR == 0) print ENVIRON["BLOCK"]
        }' $file >$file.tmp; and mv $file.tmp $file
end

function __brewsync_drop --description "Remove an entry and its description comment"
    KEY=$argv[2] awk '
        index($0, ENVIRON["KEY"]) == 1 { held = ""; next }
        { if (held != "") print held; held = "" }
        /^# / { held = $0; next }
        { print }
        END { if (held != "") print held }' $argv[1] >$argv[1].tmp; and mv $argv[1].tmp $argv[1]
end
