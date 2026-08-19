/opt/homebrew/bin/brew shellenv | source
# Use 1Password SSH agent
set -gx SSH_AUTH_SOCK ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Add ~/.local/bin to PATH
fish_add_path -g ~/.local/bin

# Disable new user greeting.
set fish_greeting

# AWS defaults
set -gx AWS_PROFILE staging
set -gx AWS_REGION eu-west-1

# Initialize starship. Config lives at the default ~/.config/starship.toml.
if type -q starship
    starship init fish | source
end

if status is-interactive
    mise activate fish | source
else
    mise activate fish --shims | source
end

set -gx HOMEBREW_NO_ENV_HINTS 1

# Set our editors
set -xg EDITOR 'zed --wait'

# Add bun binary location
fish_add_path ~/.bun/bin
