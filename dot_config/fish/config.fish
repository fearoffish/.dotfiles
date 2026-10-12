/opt/homebrew/bin/brew shellenv | source
# Use 1Password SSH agent
set -gx SSH_AUTH_SOCK ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
set -gx OP_BIOMETRIC_UNLOCK_ENABLED true

# Add ~/.local/bin to PATH
fish_add_path -g ~/.local/bin

# Disable new user greeting.
set fish_greeting

if status is-interactive
    # Config lives at the default ~/.config/starship.toml.
    if type -q starship
        starship init fish | source
    end
    mise activate fish | source
else
    mise activate fish --shims | source
end

# Ring the bell on Ctrl+G like readline does. Rune sends Ctrl+A Ctrl+G and waits
# for the bell to know the shell has processed its input; stock fish stays silent.
if status is-interactive
    bind ctrl-g 'printf \a'
end

set -gx HOMEBREW_NO_ENV_HINTS 1

# Set our editors
set -xg EDITOR 'zed --wait'

# Add bun binary location
fish_add_path ~/.bun/bin

