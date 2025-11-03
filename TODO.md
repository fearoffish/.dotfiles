# Dotbot to Chezmoi Conversion Plan

## Phase 1: Core Configuration Files (SKIPPED)

### 1. Git Configuration
- [x] Skip this (already configured)

### 2. Shell Configuration (zsh)
- [x] Skip this (already configured)

## Phase 2: Application Configs

### 3. Neovim
- [x] Skip this (already configured)

### 4. Terminal Emulators
- [ ] Add Ghostty config: `~/dotfiles/ghost/config` → `dot_config/ghostty/config`
- [ ] Duplicate the Ghostty config into an equivalent Kitty one

### 5. Other Application Configs
- [ ] Lazygit: Merge `~/dotfiles/lazygit.yml` with existing `dot_config/lazygit/config.yml`
- [ ] Patat: Copy `~/dotfiles/patat/config.yaml` → `dot_config/patat/config.yaml`
- [ ] Colima: Copy `~/dotfiles/colima/` directory → `dot_config/colima/`
- [ ] Ruby gems: Copy `~/dotfiles/gemrc` → `dot_gemrc`
- [ ] IRB: Copy `~/dotfiles/irbrc` → `dot_irbrc`

## Phase 3: Package Management

### 6. Brewfile Consolidation
- [ ] Update the old Brewfile with currently installed brews
- [ ] Add missing taps from old Brewfile to new one
- [ ] Add missing brew packages (check for version differences)
- [ ] Add missing casks
- [ ] Add missing mas apps
- [ ] Remove any deprecated or unwanted packages
- [ ] Test Brewfile is valid: `brew bundle check --file=Brewfile`

## Phase 4: Scripts & Automation ✅

### 7. macOS Settings Script
- [x] Convert `~/dotfiles/.macos` to `run_once_before_macos-defaults.sh.tmpl`
- [x] Add keyboard repeat settings (KeyRepeat: 1, InitialKeyRepeat: 10)
- [x] Add OS detection using chezmoi template variables
- [x] Make script executable

### 8. Installation Scripts - CONVERTED TO CHEZMOI
- [x] Create `run_once_before_install-prerequisites.sh.tmpl` (Homebrew, tools, 1Password CLI)
- [x] Create `run_onchange_install-packages.sh.tmpl` (brew bundle)
- [x] Create `run_once_after_setup-shell.sh.tmpl` (shell configuration)
- [x] Create `.chezmoiignore` file
- [x] Mark old `install.sh` and `bootstrap.sh` as deprecated

## Phase 5: Chezmoi-Specific Features ✅

### 9. Templates & Conditionals
- [x] `.chezmoi.toml.tmpl` reviewed - already has OS/arch detection
- [ ] Add work/personal context variables if needed
- [ ] Template any files that differ between machines

### 10. Ignore Patterns
- [x] Create `.chezmoiignore` file
- [x] Add patterns for `.DS_Store`, `*.lock.json`, editor files
- [x] Exclude documentation and bootstrap scripts

## Phase 6: Testing & Cleanup

### 11. Testing & Validation
- [ ] Run `chezmoi diff` to preview all changes
- [ ] Review the diff output carefully
- [ ] Run `chezmoi apply --dry-run --verbose` for detailed preview
- [ ] Apply changes: `chezmoi apply`
- [ ] Verify critical functionality:
  - [ ] Git config and signing works
  - [ ] Shell aliases and exports work
  - [ ] Neovim launches and plugins work
  - [ ] Terminal emulator configs applied
  - [ ] All application configs in correct locations
- [ ] Source shell config and test: `source ~/.zshrc`

### 12. Cleanup & Documentation
- [ ] Create backup of old dotfiles: `mv ~/dotfiles ~/dotfiles.backup`
- [ ] Update README.md with new setup instructions
- [ ] Document any machine-specific setup required
- [ ] Commit all changes to git
- [ ] Consider: Push to remote repository

## Notes & Decisions

### Excluded from Migration
- Fish shell configuration (keeping in old dotfiles for now)
- Dotbot submodules (no longer needed)
- `.github/` directory (may add later if needed)

### Key Differences
- Chezmoi manages files directly in `~`, no symlinks needed
- `dotbot` shell commands → `run_once_` scripts
- File naming: `dot_filename` → `.filename` in home directory
- Directories: `dot_config/` → `~/.config/`

### Tools Replaced
- `dotbot-asdf` → using `mise` instead (already in Brewfile)
- `dotbot-brew` → using Brewfile + install.sh
