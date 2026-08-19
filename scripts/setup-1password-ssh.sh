#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[1PASSWORD-SSH]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[1PASSWORD-SSH]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[1PASSWORD-SSH]${NC} $1"
}

log_error() {
    echo -e "${RED}[1PASSWORD-SSH]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Setup 1Password SSH agent
setup_1password_ssh() {
    log_info "Setting up 1Password SSH integration..."

    # Check if 1Password CLI is installed
    if ! command_exists op; then
        log_error "1Password CLI (op) not found. Please install it first."
        exit 1
    fi

    # Check if user is signed in
    if ! op whoami >/dev/null 2>&1; then
        log_warning "Not signed in to 1Password. Please run: op signin"
        log_info "After signing in, run this script again."
        exit 1
    fi

    setup_macos_ssh
}

# Setup SSH for macOS
setup_macos_ssh() {
    log_info "Setting up 1Password SSH for macOS..."

    # Check if 1Password app is installed
    if [ ! -d "/Applications/1Password 7 - Password Manager.app" ]; then
        log_warning "1Password 7 app not found. Checking for 1Password 8..."
        if [ ! -d "/Applications/1Password.app" ]; then
            log_error "1Password app not found. Please install 1Password from the App Store or website."
            exit 1
        fi
    fi

    # Enable SSH agent in 1Password
    log_info "Please enable SSH agent in 1Password:"
    log_info "1. Open 1Password"
    log_info "2. Go to Preferences → Developer"
    log_info "3. Enable 'Use the SSH agent'"
    log_info "4. Enable 'Display key names when authorizing connections'"

    # Set up git to use SSH signing
    log_info "Configuring git for SSH signing..."

    # Check if we have an SSH signing key
    SSH_KEYS=$(op item list --categories "SSH Key" --format json 2>/dev/null || echo "[]")
    if [ "$SSH_KEYS" = "[]" ]; then
        log_warning "No SSH keys found in 1Password."
        log_info "Please add your SSH keys to 1Password or generate new ones."
        log_info "You can generate a new SSH key with:"
        log_info "  ssh-keygen -t ed25519 -C 'your.email@example.com'"
    else
        log_success "SSH keys found in 1Password"
    fi

    # Configure git
    if [ -f ~/.gitconfig ]; then
        log_info "Updating git configuration for SSH signing..."
        git config --global gpg.format ssh
        git config --global commit.gpgsign true

        # Try to set the SSH signing program
        if [ -d "/Applications/1Password.app" ]; then
            git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        else
            git config --global gpg.ssh.program "/Applications/1Password 7 - Password Manager.app/Contents/MacOS/op-ssh-sign"
        fi

        log_success "Git configured for SSH signing"
    fi
}

# Test SSH setup
test_ssh_setup() {
    log_info "Testing SSH setup..."

    if [ -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]; then
        log_success "1Password SSH agent socket found"
        export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    fi

    # Test SSH agent
    if ssh-add -l >/dev/null 2>&1; then
        log_success "SSH agent is working"
        log_info "Available SSH keys:"
        ssh-add -l
    else
        log_warning "SSH agent not responding or no keys loaded"
    fi

    # Test git signing (if we have a signing key configured)
    if git config --get user.signingkey >/dev/null; then
        log_info "Testing git signing..."
        if git config --get commit.gpgsign >/dev/null && [ "$(git config --get commit.gpgsign)" = "true" ]; then
            log_success "Git signing is enabled"
        else
            log_warning "Git signing is not enabled"
        fi
    fi
}

# Main function
main() {
    log_info "1Password SSH Setup"
    log_info "==================="

    setup_1password_ssh
    test_ssh_setup

    log_success "==================="
    log_success "Setup completed!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Make sure you have SSH keys in 1Password"
    log_info "2. Add your public key to GitHub/GitLab"
    log_info "3. Test with: ssh -T git@github.com"
    log_info "4. Make a test commit to verify signing works"
    log_info ""
    log_info "Troubleshooting:"
    log_info "- Restart your terminal after setup"
    log_info "- Check 1Password → Settings → Developer"
}

# Run main function
main "$@"
