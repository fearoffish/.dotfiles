function __dotfiles_hosts_with --description "Print other hosts whose hosts/<host>/<file> has a line matching a regex"
    set -l src $argv[1]
    set -l host $argv[2]
    set -l file $argv[3]
    set -l regex $argv[4]
    for dir in $src/hosts/*/
        set -l other (path basename $dir)
        test $other = $host; and continue
        test -f $dir$file; or continue
        string match -rq -- $regex <$dir$file; and echo $other
    end
end
