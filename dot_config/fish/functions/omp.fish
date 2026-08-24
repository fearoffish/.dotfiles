function omp --description "omp, with every AWS environment variable unset"
    set -l stripped
    for var in (set --names --export | string match 'AWS_*')
        set -a stripped -u $var
    end
    command env $stripped omp $argv
end
