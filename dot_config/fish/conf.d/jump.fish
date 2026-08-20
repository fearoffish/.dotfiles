# Directories that `j` searches. Add as many roots as you like; every directory
# under them (any depth, .gitignore honoured) becomes a jump target.
set -g jump_roots ~/a

# Ctrl+G opens the picker without typing `j`; repaint so the prompt shows the new cwd
if status is-interactive
    bind ctrl-g 'j; commandline --function repaint'
end
