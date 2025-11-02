# Chezmoi Dotfiles

This repository contains my personal dotfiles managed by [chezmoi](https://www.chezmoi.io/), designed to work seamlessly across my MacBook M2 and AMD64 Linux machines.

## Quick Start

### Option 1: Bootstrap from scratch
```bash
# Clone this repository to your chezmoi source directory
git clone <your-repo-url> ~/.local/share/chezmoi
cd ~/.local/share/chezmoi

# Run the bootstrap script
./bootstrap.sh
```

### Option 2: Use chezmoi directly
```bash
# Initialize and apply dotfiles from a git repository
chezmoi init --apply <your-repo-url>
```

### Option 3: Manual installation
```bash
# Make the install script executable and run it
chmod +x install.sh
./install.sh
```

## What's Included

### Cross-Platform Support
- **macOS**: Full support for both Intel and Apple Silicon Macs
- **Linux**: AMD64 and ARM64 support with automatic package manager detection

### Core Tools Installed
- **Homebrew**: Package manager for both macOS and Linux
- **chezmoi**: Dotfiles manager
- **1Password CLI**: Password manager command-line interface
- **Essential CLI tools**: git, curl, wget, jq, ripgrep, fd, bat, fzf, etc.
- **Development tools**: neovim, fish shell, starship prompt
- **Git configuration**: Pre-configured with SSH signing via 1Password

### Platform-Specific Features
#### macOS
- GUI applications via Homebrew Cask (Rectangle, iTerm2, Zed, etc.)
- Xcode command line tools installation
- 1Password SSH agent integration
- macOS-specific optimizations

#### Linux
- Distribution detection (apt, yum, pacman)
- Linux-specific package installations
- Proper Homebrew setup for Linux
- 1Password SSH agent setup (with desktop app)

## File Structure

```
├── install.sh              # Main installation script
├── bootstrap.sh            # Simple bootstrap runner
├── .chezmoi.toml.tmpl      # Chezmoi configuration template
├── Brewfile.tmpl           # Platform-aware Homebrew packages
├── dot_gitconfig.tmpl      # Git configuration template
├── dot_ssh/
│   └── config.tmpl         # SSH configuration with 1Password
├── scripts/
│   └── setup-1password-ssh.sh  # 1Password SSH setup script
└── README.md              # This file
```

## Configuration

The setup uses chezmoi's templating system to handle platform differences:

- **`.chezmoi.toml.tmpl`**: Main configuration with platform detection
- **`Brewfile.tmpl`**: Conditional package installation based on OS/architecture
- **Platform variables**: Available in all templates
  - `is_macos`, `is_linux`
  - `is_arm64`, `is_amd64`
  - `is_laptop`, `is_desktop`
  - `is_macos_arm64`, `is_linux_amd64`, etc.

## Usage

### Daily Operations
```bash
# Check what would change
chezmoi status

# Apply changes
chezmoi apply

# Edit a dotfile
chezmoi edit ~/.gitconfig

# Add a new dotfile
chezmoi add ~/.newconfig

# Update from source repository
chezmoi update
```

### 1Password CLI Setup
```bash
# Sign in to your 1Password account
op signin

# Verify you're signed in
op whoami

# List your items
op item list

# Get a password (example)
op item get "GitHub" --fields password

# Setup SSH signing with 1Password
./scripts/setup-1password-ssh.sh
```

### Managing Templates
```bash
# Edit the Brewfile template
chezmoi edit Brewfile.tmpl

# Apply and install new packages
chezmoi apply
brew bundle --file=~/.local/share/chezmoi/Brewfile
```

### Platform-Specific Files
Use chezmoi's suffix system for platform-specific files:
- `file.darwin` - macOS only
- `file.linux` - Linux only  
- `file.arm64` - ARM64 only
- `file.amd64` - AMD64 only

## Customization

### Adding New Packages
Edit `Brewfile.tmpl` and use conditional blocks:
```ruby
{{- if .is_macos }}
cask "mac-only-app"
{{- end }}

{{- if .is_linux }}
brew "linux-specific-tool"
{{- end }}
```

### Personal Information
Update `.chezmoi.toml.tmpl` with your details:
```toml
[data]
    name = "Your Name"
    email = "your.email@example.com"
```

### Shell Configuration
The install script automatically:
- Installs fish shell
- Sets fish as default shell
- Configures starship prompt

## Troubleshooting

### Permission Issues
```bash
# Make scripts executable
chmod +x install.sh bootstrap.sh
```

### Homebrew Issues on Linux
```bash
# Ensure Homebrew is in PATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

### Chezmoi State Issues
```bash
# Reset chezmoi state
chezmoi state reset

# Re-initialize
chezmoi init --apply
```

## Migration from Dotbot

If migrating from a dotbot setup:
1. Review your existing dotbot configuration
2. Add equivalent files to chezmoi: `chezmoi add <file>`
3. Convert any complex linking logic to chezmoi templates
4. Test on a clean system before fully switching

## Contributing

1. Test changes on both macOS and Linux if possible
2. Use platform conditionals for OS-specific configurations
3. Keep the installation script idempotent
4. Update this README for significant changes

## Security Notes

The setup includes comprehensive 1Password integration:

### 1Password CLI
- Automatically installed on both macOS and Linux
- Use `op signin` to authenticate after installation
- Integrate with other tools for secure credential access

### SSH Key Management with 1Password
- **macOS**: Full SSH agent integration via 1Password app
- **Linux**: SSH agent support with 1Password desktop app
- Git signing uses SSH keys instead of GPG for better UX
- Automatic SSH key loading from 1Password vault

### Setup Process
1. Install 1Password app (macOS/Linux desktop)
2. Enable SSH agent in 1Password preferences
3. Add SSH keys to your 1Password vault
4. Run `./scripts/setup-1password-ssh.sh` for automatic configuration
5. Add public keys to GitHub/GitLab for commit signing

### Git Signing
- Uses SSH signing format (more reliable than GPG)
- Automatically configured based on platform
- macOS: Uses 1Password SSH agent seamlessly
- Linux: Falls back to GPG if 1Password desktop unavailable

## License

[Your License Here]