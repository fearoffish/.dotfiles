# Chezmoi Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/), for macOS.

## 🚀 Quick Start

### Fresh Machine Setup

Clone the repo and run one script:

```bash
git clone https://github.com/fearoffish/.dotfiles.git ~/a/dotfiles
cd ~/a/dotfiles && ./setup.sh
```

It walks through, in order:

1. Xcode command line tools
2. Homebrew
3. A pause to sign in to the App Store, so the `mas` apps are not skipped
4. Every package in the Brewfile, which takes a while and needs no input
5. A pause to sign in to 1Password and turn on its SSH agent
6. Dotfiles, macOS defaults, and fish as the login shell
7. `1p-check`, looping until the 1Password chain verifies

Safe to re-run. Every step checks before it acts.

### On a machine that is already set up

```bash
chezmoi apply
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
brew bundle dump --file=~/a/dotfiles/Brewfile --force

# Review the changes
chezmoi diff

# Add and commit the updated Brewfile
cd ~/a/dotfiles
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
cd ~/a/dotfiles
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

1Password's own settings are tamper-protected, so turning on the SSH agent
cannot be scripted. Everything either side of it is:

- `.config/1Password/ssh/agent.toml` picks which vaults offer keys
- `.ssh/config` points `IdentityAgent` at the agent socket
- `.ssh/allowed_signers` and `.gitconfig` wire up SSH commit signing

After signing in, turn on **Settings → Developer → Use the SSH agent**, then
quit and reopen 1Password so it re-reads `agent.toml`.

### Checking it works

```bash
1p-check
```

Verifies the whole chain: socket, loaded keys, `agent.toml`, allowed signers,
that Git's signing key is actually in the agent, and that GitHub accepts it.
Prints a fix for anything that fails, and exits non-zero, so it is safe to
loop on.

Note that commits are signed, so `git commit` and any `chezmoi add` or
`chezmoi edit` will fail until this passes.

## 📂 File Structure

```
.dotfiles/
├── setup.sh                              # Entry point for a new Mac
├── .chezmoi.toml.tmpl                    # Name, email, editor, git
├── .chezmoiignore                        # Repo files never applied to home
├── Brewfile                              # Package definitions
├── dot_gitconfig.tmpl                    # Git configuration
├── private_dot_ssh/
│   ├── config                            # SSH configuration
│   └── allowed_signers                   # Public keys trusted for signing
├── private_dot_local/bin/
│   └── executable_1p-check               # Verifies the 1Password SSH chain
├── dot_config/
│   ├── fish/                             # Fish shell config
│   ├── kitty/                            # Kitty terminal config
│   ├── private_1Password/ssh/            # Which vaults offer SSH keys
│   └── ...
├── run_once_before_install-prerequisites.sh.tmpl
├── run_once_before_macos-defaults.sh.tmpl
├── run_onchange_install-packages.sh.tmpl
├── run_once_after_setup-shell.sh.tmpl
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
