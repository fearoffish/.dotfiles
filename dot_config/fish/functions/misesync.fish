function misesync --description "Reconcile mise use -g changes with the dotfiles mise configs"
    set -l src (chezmoi source-path)
    or return 1
    set -l host (chezmoi execute-template '{{ .host }}')
    or return 1
    set -l live ~/.config/mise/config.toml
    set -l shared $src/dot_config/mise/config.toml
    set -l hostfile $src/hosts/$host/mise.toml

    # A blank first column means the live file is what chezmoi last wrote, so
    # any difference comes from the source and apply is all that's needed.
    set -l state (chezmoi status $live)
    if test -z "$state"; or string match -q -- ' *' $state
        echo "misesync: no local mise use -g changes on $host"
    else
        set -l live_lines (__misesync_tools $live)
        set -l shared_lines (__misesync_tools $shared)
        set -l host_lines
        test -f $hostfile; and set host_lines (__misesync_tools $hostfile)
        set -l live_keys (__misesync_key $live_lines)
        set -l shared_keys (__misesync_key $shared_lines)
        set -l host_keys (__misesync_key $host_lines)

        for i in (seq (count $live_lines))
            set -l key $live_keys[$i]
            set -l line $live_lines[$i]
            if set -l at (contains -i -- $key $shared_keys)
                test "$shared_lines[$at]" = "$line"; and continue
                read -l -P "Changed with mise use -g: $line (shared has $shared_lines[$at])  [U]pdate shared / [k]eep shared: " choice
                or return 1
                switch (string lower -- $choice)
                    case '' u
                        __misesync_edit $shared $key $line
                        echo "  updated in dot_config/mise/config.toml"
                end
                continue
            end
            contains -- $key $host_keys; and continue

            set -l others (__dotfiles_hosts_with $src $host mise.toml "^\Q$key\E\s*=")
            if set -q others[1]
                read -l -P "Added with mise use -g, tracked on $others: $line  [S]hared, moving it from $others / [h]ost $host / [d]iscard: " choice
                or return 1
                switch (string lower -- $choice)
                    case '' s
                        __misesync_edit $shared $key $line
                        for other in $others
                            __misesync_edit $src/hosts/$other/mise.toml $key
                        end
                        echo "  moved to dot_config/mise/config.toml"
                    case h
                        __misesync_edit $hostfile $key $line
                        echo "  added to hosts/$host/mise.toml"
                end
            else
                read -l -P "Added with mise use -g: $line  [H]ost $host / [s]hared / [d]iscard: " choice
                or return 1
                switch (string lower -- $choice)
                    case '' h
                        __misesync_edit $hostfile $key $line
                        echo "  added to hosts/$host/mise.toml"
                    case s
                        __misesync_edit $shared $key $line
                        echo "  added to dot_config/mise/config.toml"
                end
            end
        end

        for i in (seq (count $shared_lines))
            contains -- $shared_keys[$i] $live_keys; and continue
            read -l -P "Removed with mise unuse -g: $shared_lines[$i]  [d]rop from shared / [K]eep: " choice
            or return 1
            switch (string lower -- $choice)
                case d
                    __misesync_edit $shared $shared_keys[$i]
                    echo "  dropped from dot_config/mise/config.toml"
            end
        end
    end

    if test -f $hostfile
        for line in (__misesync_tools $hostfile)
            set -l key (__misesync_key $line)
            set -l others (__dotfiles_hosts_with $src $host mise.toml "^\Q$key\E\s*=")
            set -q others[1]; or continue
            read -l -P "In both hosts/$host and hosts/$others mise.toml: $line  [m]ove to shared / [L]ater: " choice
            or return 1
            switch (string lower -- $choice)
                case m
                    __misesync_edit $shared $key $line
                    for h in $host $others
                        __misesync_edit $src/hosts/$h/mise.toml $key
                    end
                    echo "  moved to dot_config/mise/config.toml"
            end
        end
    end

    # The live global file is chezmoi-managed: apply now so choices take effect
    # and anything discarded leaves ~/.config/mise/config.toml.
    chezmoi apply --force $live ~/.config/mise/conf.d/host.toml
    and echo "misesync: applied; review with git -C $src diff"
end

function __misesync_tools --description "Print the entries of a mise file's [tools] table"
    awk '/^\[/ { tools = ($0 == "[tools]"); next } tools && /=/' $argv[1]
end

function __misesync_key --description "Print the tool name of each [tools] entry"
    for line in $argv
        string replace -r -- '\s*=.*' '' $line
    end
end

function __misesync_edit --description "Set (with a line) or remove (without) a tool in a mise file's [tools] table"
    set -l file $argv[1]
    test -f $file; or touch $file
    KEY=$argv[2] LINE="$argv[3]" awk '
        { l[NR] = $0 }
        /^\[/ { tools = ($0 == "[tools]"); if (tools) last = NR; next }
        tools && /=/ {
            key = $0; sub(/[ \t]*=.*/, "", key)
            if (key == ENVIRON["KEY"]) {
                if (ENVIRON["LINE"] != "") l[NR] = ENVIRON["LINE"]; else skip[NR] = 1
                done = 1
            }
            last = NR
        }
        END {
            add = ENVIRON["LINE"] != "" && !done
            if (add && !last) { print "[tools]"; print ENVIRON["LINE"]; add = 0 }
            for (n = 1; n <= NR; n++) {
                if (!skip[n]) print l[n]
                if (add && n == last) print ENVIRON["LINE"]
            }
        }' $file >$file.tmp; and mv $file.tmp $file
end
