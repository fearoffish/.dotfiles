#!/usr/bin/env bash
#
# One-shot setup for a new Mac.
#
#   git clone https://github.com/fearoffish/.dotfiles.git ~/a/dotfiles
#   cd ~/a/dotfiles && ./setup.sh
#
# Safe to re-run: every step checks before it acts.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; NC=$'\033[0m'

log_info()    { echo "${BLUE}[setup]${NC} $1"; }
log_success() { echo "${GREEN}[setup]${NC} $1"; }
log_warning() { echo "${YELLOW}[setup]${NC} $1"; }
log_error()   { echo "${RED}[setup]${NC} $1"; }

step() {
    echo
    echo "${BOLD}==> $1${NC}"
}

# Print instructions, then block until the user says they are done.
wait_for_user() {
    echo
    read -rp "${BOLD}Press Enter once you have done the above...${NC}"
    echo
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

###############################################################################
# Preflight
###############################################################################

if [ "$(uname -s)" != "Darwin" ]; then
    log_error "These dotfiles are macOS only."
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    log_error "Do not run this with sudo. It will ask when it needs to."
    exit 1
fi

echo "${BOLD}Setting up this Mac from $SCRIPT_DIR${NC}"
log_info "You will be asked to sign in to 1Password partway through."

###############################################################################
step "1. Xcode command line tools"
###############################################################################

if xcode-select -p >/dev/null 2>&1; then
    log_success "Already installed"
else
    log_info "Requesting install, accept the dialogue that appears..."
    xcode-select --install 2>/dev/null
    log_info "Waiting for it to finish (up to 30 minutes)..."
    for _ in $(seq 360); do
        xcode-select -p >/dev/null 2>&1 && break
        sleep 5
    done
    if ! xcode-select -p >/dev/null 2>&1; then
        log_error "Still not installed. Run 'xcode-select --install' then re-run this."
        exit 1
    fi
    log_success "Installed"
fi

###############################################################################
step "2. Homebrew"
###############################################################################

if command_exists brew; then
    log_success "Already installed"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log_success "Installed"
fi

for prefix in /opt/homebrew /usr/local; do
    [ -x "$prefix/bin/brew" ] && eval "$("$prefix/bin/brew" shellenv)" && break
done

if ! command_exists brew; then
    log_error "Homebrew installed but not on PATH. Open a new terminal and re-run."
    exit 1
fi

###############################################################################
step "3. App Store sign-in"
###############################################################################

log_info "The Brewfile installs Xcode and other Mac App Store apps."
log_info "Those are skipped silently unless you are signed in first."
echo
echo "  Open the App Store and sign in."
wait_for_user

###############################################################################
step "4. Applications"
###############################################################################

log_info "Installing everything in the Brewfile. This takes a while."
if brew bundle --file="$SCRIPT_DIR/Brewfile"; then
    log_success "All packages installed"
else
    log_warning "Some packages failed. Continuing, you can re-run this later with:"
    log_warning "  brew bundle --file=$SCRIPT_DIR/Brewfile"
fi

###############################################################################
step "5. 1Password"
###############################################################################

log_info "1Password is installed but needs signing in to by hand."
log_info "Its settings are tamper-protected, so this part cannot be scripted."
echo
echo "  1. Open 1Password and sign in."
echo "     You will need your account password and Secret Key, or you can"
echo "     scan the QR code from a device that is already signed in."
echo "  2. Turn on Touch ID under Settings > Security."
echo "  3. Turn on ${BOLD}Settings > Developer > Use the SSH agent${NC}."
wait_for_user

###############################################################################
step "6. Dotfiles"
###############################################################################

if ! command_exists chezmoi; then
    log_error "chezmoi is missing, so the Brewfile step must have failed."
    log_error "Fix that first, then re-run this script."
    exit 1
fi

log_info "Applying dotfiles..."
if chezmoi init --apply --source="$SCRIPT_DIR"; then
    log_success "Dotfiles applied"
else
    log_error "chezmoi failed. Fix the above, then re-run this script."
    exit 1
fi

###############################################################################
step "7. Checking 1Password"
###############################################################################

log_warning "agent.toml was only just written, so quit and reopen 1Password now"
log_warning "or it will not offer keys from your non-Private vaults."
wait_for_user

CHECK="$HOME/.local/bin/1p-check"
[ -x "$CHECK" ] || CHECK="$SCRIPT_DIR/private_dot_local/bin/executable_1p-check"

while ! bash "$CHECK"; do
    echo
    read -rp "Try again? [Y/n] " -n 1 -r reply
    echo
    case "$reply" in
        [Nn]) log_warning "Skipping. Run 1p-check yourself once it is sorted."; break ;;
    esac
done

###############################################################################
step "Done"
###############################################################################

log_success "Setup complete."
echo
log_info "Worth knowing:"
log_info "  - Restart your terminal to pick up fish and the new PATH"
log_info "  - Commits are signed, so they will fail until 1p-check passes"
log_info "  - Some macOS defaults need a logout to take effect"
