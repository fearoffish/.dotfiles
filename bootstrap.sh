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
    echo -e "${BLUE}[BOOTSTRAP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[BOOTSTRAP]${NC} $1"
}

log_error() {
    echo -e "${RED}[BOOTSTRAP]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're in the right directory
if [ ! -f "$SCRIPT_DIR/install.sh" ]; then
    log_error "install.sh not found in $SCRIPT_DIR"
    log_error "Please ensure this script is in your chezmoi source directory."
    exit 1
fi

log_info "Starting bootstrap process from $SCRIPT_DIR..."

# Change to script directory
cd "$SCRIPT_DIR"

# Make install script executable
chmod +x install.sh

# Run the main installation
log_info "Running installation script..."
./install.sh

log_success "Bootstrap complete!"
log_info "Your dotfiles have been installed using chezmoi."
log_info "Next steps:"
log_info "  - Edit files with: chezmoi edit <file>"
log_info "  - Add new files with: chezmoi add <file>"
log_info "  - Apply changes with: chezmoi apply"
log_info "  - Check status with: chezmoi status"
