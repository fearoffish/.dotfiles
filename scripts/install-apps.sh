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
    echo -e "${BLUE}[APP-INSTALLER]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[APP-INSTALLER]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[APP-INSTALLER]${NC} $1"
}

log_error() {
    echo -e "${RED}[APP-INSTALLER]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Install macOS apps via Homebrew
install_macos_apps() {
    if [ ! -f "Brewfile" ]; then
        log_error "Brewfile not found"
        return 1
    fi

    if ! command_exists brew; then
        log_error "Homebrew not found. Please install Homebrew first."
        return 1
    fi

    log_info "Installing macOS applications via Homebrew..."
    brew bundle --file=Brewfile || log_warning "Some Homebrew installations may have failed"
    log_success "macOS applications installed"
}

# Install Linux apps with Snap-first approach
install_linux_apps() {
    if [ ! -f "linux-apps.txt" ]; then
        log_error "linux-apps.txt not found"
        return 1
    fi

    log_info "Installing Linux applications (Snap first, APT fallback)..."

    while IFS= read -r app; do
        # Skip empty lines and comments
        if [[ -z "$app" || "$app" =~ ^#.* ]]; then
            continue
        fi

        log_info "Installing: $app"

        # Try Snap first (for latest versions)
        if sudo snap install "$app" >/dev/null 2>&1; then
            log_success "✓ $app installed via Snap"
        # Try APT fallback
        elif sudo apt update >/dev/null 2>&1 && sudo apt install -y "$app" >/dev/null 2>&1; then
            log_success "✓ $app installed via APT"
        # Special cases that need different handling
        elif install_special_case "$app"; then
            log_success "✓ $app installed via special method"
        else
            log_warning "✗ Failed to install $app"
        fi
    done < linux-apps.txt

    log_success "Linux applications installation completed"
}

# Handle special cases that need custom installation
install_special_case() {
    local app="$1"

    case "$app" in
        "1password")
            # 1Password needs special repo setup
            if ! command_exists 1password; then
                log_info "Setting up 1Password repository..."
                curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
                echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
                sudo apt update && sudo apt install -y 1password
                return $?
            fi
            return 0
            ;;
        "github-desktop")
            # GitHub Desktop is not in standard repos, try Flatpak
            if command_exists flatpak; then
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1
                flatpak install -y flathub io.github.shiftey.Desktop >/dev/null 2>&1
                return $?
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Main installation function
main() {
    log_info "Simple App Installer"
    log_info "==================="
    log_info "Platform: $OS"

    case "$OS" in
        "darwin")
            install_macos_apps
            ;;
        "linux")
            install_linux_apps
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac

    log_success "==================="
    log_success "Installation completed!"
    log_info ""
    log_info "To add/remove apps in the future:"
    if [ "$OS" = "darwin" ]; then
        log_info "  - Edit Brewfile"
        log_info "  - Run: brew bundle --file=Brewfile"
    else
        log_info "  - Edit linux-apps.txt"
        log_info "  - Run: ./scripts/install-apps.sh"
    fi
}

# Show help
show_help() {
    cat << EOF
Simple App Installer

Usage: $0 [--help]

This script installs applications using native package managers:
- macOS: Uses Homebrew with Brewfile
- Linux: Uses Snap (preferred) with APT fallback from linux-apps.txt

Files needed:
- Brewfile (for macOS)
- linux-apps.txt (for Linux)

To customize your app list:
- macOS: Edit Brewfile
- Linux: Edit linux-apps.txt (one app per line)

EOF
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
