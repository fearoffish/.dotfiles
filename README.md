# Chezmoi Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/), for macOS.

## 🚀 Quick Start

### Fresh Machine Setup

Clone the repo and run one script:

```bash
git clone https://github.com/fearoffish/.dotfiles.git ~/a/dotfiles
cd ~/a/dotfiles && ./setup.sh
```

The first `git` on a bare Mac prompts to install the command line tools.
Accept, wait, then run the clone again. HTTPS because no SSH keys exist yet;
`setup.sh` switches the remote to SSH once 1Password is verified.

It walks through, in order:

1. Which Mac this is. A Mac whose name isn't in `hosts/` gets a menu of the
   known hosts and is renamed to the one you pick
2. Xcode command line tools
3. Homebrew
4. A pause to sign in to the App Store, so the `mas` apps are not skipped
5. Every package in the Brewfile plus this host's `hosts/<name>/Brewfile`,
   which takes a while and needs no input
6. A pause to sign in to 1Password and turn on its SSH agent
7. Dotfiles, macOS defaults, fish as the login shell, then fisher plugins,
   mise runtimes, and nvim plugins
8. `1p-check`, looping until the 1Password chain verifies, then the dotfiles
   remote is switched to SSH

Safe to re-run. Every step checks before it acts.

Left to you afterwards: log out and back in for the macOS defaults, and sign
in to Claude Code the first time you run `claude`.

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
- **CLI utilities**: bat, fzf, ripgrep, eza, etc.
- **Desktop apps** (macOS): Ghostty, Kitty, Tuna, Zed, 1Password, etc.
- **Fonts**: Nerd Fonts, Ioskeley Mono, JetBrains Mono, Iosevka, etc.
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
4. **`run_once_after_bootstrap-tools.sh`** - Installs fisher plugins from `fish_plugins`, mise runtimes from `mise/config.toml` and `mise/conf.d/host.toml`, and nvim plugins via lazy.nvim
5. **`run_once_after_poof-defaults.sh`** - Points Poof at `~/.config/poof`, where its managed snippets land
6. **`run_onchange_install-packages.sh`** - Installs packages from the Brewfile and this host's `hosts/<name>/Brewfile` (re-runs when either changes)
7. **`run_once_after_setup-shell.sh`** - Sets fish as default shell, reminds about 1Password setup

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

Shared packages go in `Brewfile`. Packages only one Mac should get go in that
host's `hosts/<name>/Brewfile` instead (see [Per-host differences](#-per-host-differences)).

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

The `run_onchange_install-packages.sh` script will automatically detect that either Brewfile changed and run `brew bundle` on both together.

### Keeping the Brewfiles in step with what's installed

In fish, `brew` is wrapped: after a successful `brew install` or
`brew uninstall`, it runs `brewsync` for just those packages. A new package
goes into this host's `hosts/<name>/Brewfile` unless you choose the shared
`Brewfile`. An uninstalled one is offered for removal from whichever file
tracks it.

Anything installed some other way (agents running brew from bash, `mas`, the
App Store) is caught by running `brewsync` with no arguments. It compares
`brew bundle dump`, which
lists only packages installed on request, against the shared and host
Brewfiles. For each installed package nobody tracks, it asks whether it
belongs to this host, the shared `Brewfile` or this host's skip list. For each
tracked package that isn't installed, it offers to drop or install it.

`brew bundle install` never uninstalls, so removing a package from the shared
`Brewfile` on one Mac leaves it on the other. Running `brewsync` there shows it
as untracked.

If an untracked package is already in another host's Brewfile, it now belongs
on both Macs, so the default moves it to the shared `Brewfile`. Packages listed
in both hosts' files are offered the same move.

`misesync` does the same for mise. `mise use -g` and `mise unuse -g` edit
`~/.config/mise/config.toml`, which chezmoi owns, so the next apply would undo
them. `misesync` asks where each added, changed or removed tool belongs (this
host's `hosts/<name>/mise.toml` by default, or the shared
`dot_config/mise/config.toml`). It offers to move tools listed in both hosts'
files to the shared config, then applies both mise files. If you haven't
edited the live file since the last apply, it just applies.

Neither command commits. Review with `git -C ~/a/dotfiles diff`.

## 🖥️ Per-host differences

Each Mac has a directory under `hosts/`, named after its `LocalHostName`
(`scutil --get LocalHostName`):

| Host | Machine |
|---|---|
| `fearofair` | Personal laptop |
| `fearofwork` | Work laptop |

`chezmoi init` refuses to run on a Mac with no matching directory, and exposes
the name to templates as `.host`. Inside a host's directory, every file is
optional:

| File | Effect |
|---|---|
| `Brewfile` | Installed on top of the shared `Brewfile` |
| `brew-ignore` | Packages `brewsync` leaves untracked on this host, one Brewfile entry per line (`cask "moom"`) |
| `mise.toml` | Written to `~/.config/mise/conf.d/host.toml`, which mise loads alongside `config.toml` |

For anything else that differs by host, branch in a template:
`{{ if eq .host "fearofwork" }}…{{ end }}`.

To add a Mac, create `hosts/<name>/` with at least one file in it, then run
`setup.sh` on the new machine.

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
├── .chezmoi.toml.tmpl                    # Name, email, host, editor, git
├── .chezmoiignore                        # Repo files never applied to home
├── Brewfile                              # Shared package definitions
├── hosts/                                # Per-host packages and mise tools
│   ├── fearofair/Brewfile                # Personal laptop
│   └── fearofwork/                       # Work laptop
│       ├── Brewfile
│       └── mise.toml
├── dot_gitconfig.tmpl                    # Git configuration
├── private_dot_ssh/
│   ├── config                            # SSH configuration
│   └── allowed_signers                   # Public keys trusted for signing
├── private_dot_local/bin/
│   └── executable_1p-check               # Verifies the 1Password SSH chain
├── dot_config/
│   ├── fish/                             # Fish shell config
│   ├── private_1Password/ssh/            # Which vaults offer SSH keys
│   └── ...
├── run_once_before_install-prerequisites.sh.tmpl
├── run_once_before_macos-defaults.sh.tmpl
├── run_once_after_bootstrap-tools.sh.tmpl
├── run_once_after_poof-defaults.sh.tmpl
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
