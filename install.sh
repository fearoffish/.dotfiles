#!/bin/bash

set -e

# Default options
INSTALL_DESKTOP_APPS=true
FORCE_INSTALL=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS and architecture
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        arm64)
            ARCH="arm64"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    log_info "Detected platform: $OS/$ARCH"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew
install_homebrew() {
    if command_exists brew; then
        log_info "Homebrew already installed"
        return
    fi

    log_info "Installing Homebrew..."

    case $OS in
        darwin)
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            ;;
        linux)
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # Add Homebrew to PATH for Linux
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            ;;
        *)
            log_error "Unsupported OS for Homebrew: $OS"
            exit 1
            ;;
    esac

    log_success "Homebrew installed successfully"
}

# Install chezmoi
install_chezmoi() {
    if command_exists chezmoi; then
        log_info "chezmoi already installed"
        return
    fi

    log_info "Installing chezmoi..."

    case $OS in
        darwin)
            if command_exists brew; then
                brew install chezmoi
            else
                curl -sfL https://git.io/chezmoi | sh
            fi
            ;;
        linux)
            if command_exists brew; then
                brew install chezmoi
            else
                # Install via binary for Linux
                CHEZMOI_VERSION=$(curl -s "https://api.github.com/repos/twpayne/chezmoi/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
                curl -fsSL "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_${ARCH}.tar.gz" | tar -xz -C /tmp
                sudo mv /tmp/chezmoi /usr/local/bin/
            fi
            ;;
        *)
            log_error "Unsupported OS for chezmoi: $OS"
            exit 1
            ;;
    esac

    log_success "chezmoi installed successfully"
}

# Install 1Password CLI
install_1password_cli() {
    if command_exists op; then
        log_info "1Password CLI already installed"
        return
    fi

    log_info "Installing 1Password CLI..."

    case $OS in
        darwin)
            if command_exists brew; then
                brew install --cask 1password-cli
            else
                log_warning "Homebrew not found, skipping 1Password CLI installation"
            fi
            ;;
        linux)
            # Install via official method for Linux
            curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
            echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
            sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
            curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
            sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
            curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
            sudo apt update && sudo apt install 1password-cli
            ;;
        *)
            log_warning "Unsupported OS for 1Password CLI: $OS"
            ;;
    esac

    if command_exists op; then
        log_success "1Password CLI installed successfully"
    else
        log_warning "1Password CLI installation may have failed"
    fi
}

# Install essential packages based on platform
install_essentials() {
    log_info "Installing essential packages..."

    case $OS in
        darwin)
            # macOS essentials
            if command_exists brew; then
                brew install git curl wget
                # Install macOS-specific tools
                brew install --cask rectangle
                brew install --cask iterm2
            fi
            ;;
        linux)
            # Linux essentials
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update
                sudo apt-get install -y git curl wget build-essential
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y git curl wget gcc gcc-c++ make
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm git curl wget base-devel
            fi

            if command_exists brew; then
                # Install Linux-specific tools via Homebrew
                brew install gcc
            fi
            ;;
    esac

    log_success "Essential packages installed"
}

# Install desktop applications
install_desktop_apps() {
    log_info "Installing desktop applications..."

    if [ -f "scripts/install-apps.sh" ]; then
        ./scripts/install-apps.sh || log_warning "Desktop app installation failed"
    else
        log_error "Desktop app installer not found"
        return 1
    fi

    log_success "Desktop applications installed"
}

# Initialize or update chezmoi
setup_chezmoi() {
    log_info "Setting up chezmoi dotfiles..."

    # Get the current directory (where the install script is being run from)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CHEZMOI_SOURCE="$HOME/.local/share/chezmoi"

    if [ -d "$CHEZMOI_SOURCE" ]; then
        log_info "Existing chezmoi repository found..."

        # Check if we have any commits and a remote configured
        if git -C "$CHEZMOI_SOURCE" rev-parse HEAD >/dev/null 2>&1 && git -C "$CHEZMOI_SOURCE" remote >/dev/null 2>&1; then
            # We have commits and a remote, safe to update
            log_info "Updating existing chezmoi repository..."
            if ! chezmoi update; then
                log_warning "chezmoi update failed, trying apply instead..."
                chezmoi apply
            fi
        else
            # No commits or no remote, just apply
            log_info "Repository has no commits or remote, applying dotfiles..."
            chezmoi apply
        fi
    else
        log_info "Initializing chezmoi..."

        # Check if we're running from a chezmoi source directory
        if [ -f "$SCRIPT_DIR/.chezmoi.toml.tmpl" ] || [ -f "$SCRIPT_DIR/.chezmoi.yaml.tmpl" ] || [ -f "$SCRIPT_DIR/dot_gitconfig.tmpl" ]; then
            log_info "Initializing from current directory..."
            chezmoi init --apply "$SCRIPT_DIR"
        else
            # If you want to use a git repository, uncomment and modify the line below:
            # chezmoi init --apply https://github.com/yourusername/dotfiles.git
            log_info "Initializing empty chezmoi repository..."
            chezmoi init
        fi
    fi

    log_success "chezmoi setup complete"
}

# Apply dotfiles
apply_dotfiles() {
    log_info "Applying dotfiles..."
    chezmoi apply
    log_success "Dotfiles applied successfully"
}

# Platform-specific post-install steps
post_install() {
    case $OS in
        darwin)
            log_info "Running macOS-specific setup..."

            # Set default shell to fish if installed
            if command_exists fish; then
                if ! grep -q "$(which fish)" /etc/shells; then
                    echo "$(which fish)" | sudo tee -a /etc/shells
                fi
                chsh -s "$(which fish)"
                log_success "Default shell set to fish"
            fi

            # Install Xcode command line tools if not installed
            if ! xcode-select -p >/dev/null 2>&1; then
                log_info "Installing Xcode command line tools..."
                xcode-select --install
            fi
            ;;
        linux)
            log_info "Running Linux-specific setup..."

            # Set default shell to fish if installed
            if command_exists fish; then
                if ! grep -q "$(which fish)" /etc/shells; then
                    echo "$(which fish)" | sudo tee -a /etc/shells
                fi
                chsh -s "$(which fish)"
                log_success "Default shell set to fish"
            fi
            ;;
    esac
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-desktop-apps)
                INSTALL_DESKTOP_APPS=false
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help information
show_help() {
    cat << EOF
Chezmoi Dotfiles Installer

Usage: $0 [options]

Options:
    --no-desktop-apps    Skip desktop application installation
    --force             Force installation without prompts
    --help, -h          Show this help message

This script will:
1. Install Homebrew (if not present)
2. Install chezmoi
3. Install 1Password CLI
4. Install essential packages
5. Install desktop applications (unless --no-desktop-apps is used)
6. Set up chezmoi dotfiles
7. Configure 1Password SSH integration

Examples:
    $0                   # Full installation
    $0 --no-desktop-apps # Skip GUI applications
    $0 --force           # Install without prompts

EOF
}

# Main installation function
main() {
    parse_args "$@"

    log_info "Starting dotfiles installation..."
    log_info "======================================"

    detect_platform

    # Install prerequisites
    install_homebrew
    install_chezmoi
    install_1password_cli
    install_essentials

    # Install desktop apps unless skipped
    if [ "$INSTALL_DESKTOP_APPS" = true ]; then
        install_desktop_apps
    else
        log_info "Skipping desktop applications (--no-desktop-apps specified)"
    fi

    # Setup dotfiles
    setup_chezmoi
    apply_dotfiles

    # Platform-specific setup
    post_install

    # Run 1Password SSH setup if available
    if [ -f "scripts/setup-1password-ssh.sh" ]; then
        log_info ""
        log_info "Setting up 1Password SSH integration..."
        ./scripts/setup-1password-ssh.sh || log_warning "1Password SSH setup failed, continuing..."
    fi

    log_info ""
    log_info "You may need to:"
    log_info "  - Restart your terminal or run 'source ~/.bashrc' (Linux)"
    log_info "  - Run 'chezmoi edit-config' to customize your chezmoi configuration"
    log_info "  - Run 'chezmoi add <file>' to add more dotfiles"
    log_info "  - Run 'chezmoi apply' to apply changes after editing"
    log_info ""
    log_info "1Password CLI setup:"
    log_info "  - Sign in: op signin"
    log_info "  - Test access: op whoami"
    log_info "  - List items: op item list"
    log_info "  - Setup SSH: ./scripts/setup-1password-ssh.sh"

    if [ "$INSTALL_DESKTOP_APPS" = false ]; then
        log_info ""
        log_info "Desktop applications:"
        log_info "  - Install later with: ./scripts/install-apps.sh"
        log_info "  - Edit Brewfile (macOS) or linux-apps.txt (Linux) to customize"
    fi
}

# Run main function
main "$@"
