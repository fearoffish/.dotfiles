# ngrok completions for fish.
#
# `ngrok completion` only emits zsh (its output starts with `#compdef ngrok`,
# and the subcommand takes no --shell flag), so the eval snippet from ngrok's
# own help text has nothing to give fish. ngrok is a Cobra CLI, though, and
# Cobra's hidden `__complete` command is shell-agnostic: it prints
# `value<TAB>description` lines, which is already fish's format, followed by a
# `:N` directive line. Strip that line and fish can use the rest directly.
#
# This lives in completions/ rather than conf.d/ so fish loads it lazily, the
# first time an ngrok command is completed, instead of on every shell start.

function __ngrok_complete
    set -l tokens (commandline -opc)

    # Drop 'ngrok' itself; Cobra wants only the arguments after the command.
    set -q tokens[1]; and set -e tokens[1]

    # Cobra expects the word being completed as the final argument, and needs
    # it even when empty. Quoting the variable guarantees exactly one argument
    # either way, where a bare command substitution would collapse to none.
    set -l current (commandline -ct)

    ngrok __complete $tokens "$current" 2>/dev/null | string match -r -v '^:'
end

complete -c ngrok -f -a '(__ngrok_complete)'

# ngrok answers NoFileComp for almost everything, hence -f above. These are the
# flags that genuinely want a path, so they opt file completion back in.
complete -c ngrok -F -n '__fish_prev_arg_in --config --crt --key --log --mutual-tls-cas --traffic-policy-file --upstream-tls-verify-cas'
