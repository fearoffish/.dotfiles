# Chezmoi Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/), for macOS.

## 🚀 Quick Start

### Fresh Machine Setup (Recommended)

On a brand new machine, run this single command:

```bash
# Bootstrap everything from GitHub
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply fearoffish
```

Or if you prefer the full GitHub URL:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/fearoffish/.dotfiles.git
```

This will automatically:
1. Install chezmoi
2. Clone your dotfiles
3. Install Homebrew
4. Install essential tools (git, curl, wget, 1Password CLI)
5. Configure macOS system defaults (if on macOS)
6. Apply all dotfiles to your home directory
7. Install all packages from Brewfile
8. Set fish as your default shell

### If You Already Have Chezmoi Installed

```bash
chezmoi init --apply fearoffish/.dotfiles
```

## 📦 What Gets Installed

### Automatically Installed Prerequisites
- **Homebrew**: Package manager
- **1Password CLI**: Secure credential management
- **Essential tools**: git, curl, wget
- **Xcode Command Line Tools** (macOS only)

### From Brewfile
- **Development tools**: neovim, fish shell, starship, mise, docker, etc.
- **CLI utilities**: bat, fzf, ripgrep, eza, zoxide, lazygit, etc.
- **Desktop apps** (macOS): iTerm2, Ghostty, Kitty, Raycast, Zed, 1Password, etc.
- **Fonts**: Nerd Fonts, JetBrains Mono, Iosevka, etc.
- **Mac App Store apps** (via `mas`): Things, Keynote, Logic Pro, etc.

### Configuration Files
- Git configuration with SSH signing via 1Password
- SSH configuration with 1Password agent
- Fish shell configuration
- Starship prompt
- Neovim/Lazygit/Terminal configs

## 🔄 How It Works

The bootstrap process runs these scripts in order:

1. **`run_once_before_install-prerequisites.sh`** - Installs Homebrew, 1Password CLI, essential tools
2. **`run_once_before_macos-defaults.sh`** - Configures macOS settings (keyboard repeat, Finder, Dock, etc.)
3. **Dotfiles Applied** - All `dot_*` files are copied to your home directory
4. **`run_onchange_install-packages.sh`** - Installs packages from Brewfile (re-runs when Brewfile changes)
5. **`run_once_after_setup-shell.sh`** - Sets fish as default shell, reminds about 1Password setup

## 🛠️ Daily Usage

```bash
# Check what would change
chezmoi status

# Preview changes
chezmoi diff

# Apply changes
chezmoi apply

# Edit a dotfile
chezmoi edit ~/.gitconfig

# Add a new dotfile
chezmoi add ~/.newconfig

# Update from git and apply
chezmoi update
```

## 📝 Managing Packages

### Adding New Packages

Edit the Brewfile in your chezmoi source directory:

```bash
chezmoi edit Brewfile
```

Add your package:
```ruby
brew "your-new-package"
cask "your-new-app"  # macOS only
mas "App Name", id: 123456789  # Mac App Store
```

Then apply:
```bash
chezmoi apply
```

The `run_onchange_install-packages.sh` script will automatically detect the Brewfile changed and run `brew bundle`.

### Updating Brewfile from Currently Installed Packages

If you've installed packages manually with `brew install` and want to update your Brewfile:

```bash
# Dump all currently installed packages to Brewfile
brew bundle dump --file=~/.local/share/chezmoi/Brewfile --force

# Review the changes
chezmoi diff

# Add and commit the updated Brewfile
cd ~/.local/share/chezmoi
git add Brewfile
git commit -m "Update Brewfile with new packages"
git push
```

**Pro tip**: Keep your Brewfile clean by reviewing what `brew bundle dump` adds. It includes all dependencies, which you may not want to explicitly track.

### Alternative: Selective Adding

Instead of dumping everything, you can manually add what you installed:

```bash
# After installing something manually
brew install new-tool

# Add it to your Brewfile
chezmoi edit Brewfile
# (add the line: brew "new-tool")

# Commit the change
cd ~/.local/share/chezmoi
git add Brewfile
git commit -m "Add new-tool to Brewfile"
git push
```

## 🔧 Configuration

### Personal Information

Your name and email are configured in `.chezmoi.toml.tmpl`:

```toml
[data]
    name = "Jamie van Dyke"
    email = "me@fearof.fish"
```

Edit with: `chezmoi edit-config`

## 🔐 1Password Setup

### Initial Setup

```bash
# Sign in to 1Password
op signin

# Verify
op whoami

# Enable SSH agent in 1Password app preferences
# Then run:
./scripts/setup-1password-ssh.sh
```

### Git Signing

The dotfiles automatically configure Git to use SSH signing via 1Password:

1. Add your SSH key to 1Password
2. Enable SSH agent in 1Password preferences
3. Add your public key to GitHub/GitLab
4. Commits will be automatically signed

## 📂 File Structure

```
.dotfiles/
├── .chezmoi.toml.tmpl                    # Chezmoi config with platform detection
├── .chezmoiignore                        # Files to ignore
├── Brewfile                              # Package definitions
├── dot_gitconfig.tmpl                    # Git configuration
├── dot_ssh/
│   └── config.tmpl                       # SSH configuration
├── dot_config/
│   ├── fish/                             # Fish shell config
│   ├── kitty/                            # Kitty terminal config
│   └── ...
├── run_once_before_install-prerequisites.sh.tmpl
├── run_once_before_macos-defaults.sh.tmpl
├── run_onchange_install-packages.sh.tmpl
├── run_once_after_setup-shell.sh.tmpl
├── scripts/
│   └── setup-1password-ssh.sh
└── README.md
```

## 🚨 Troubleshooting

### Reset Chezmoi State

```bash
chezmoi state reset
chezmoi init --apply
```

### Re-run Scripts

```bash
# Force re-run of run_once scripts
rm ~/.config/chezmoi/chezmoistate.boltdb
chezmoi apply
```

## 🔄 Migrating from Dotbot

See `TODO.md` for the full migration checklist. The key differences:

- **Dotbot**: Uses symlinks, manual `install` script
- **Chezmoi**: Copies files, automatic templating, built-in scripts
- **No more**: install.conf.yaml, dotbot submodules
- **Now using**: `run_once_*` scripts, chezmoi templates

## 📄 License

Personal dotfiles - feel free to fork and adapt!
