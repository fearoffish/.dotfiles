# config.nu
#
# Installed by:
# version = "0.113.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

use std "path add"
# nushell never runs macOS path_helper, so anything outside launchd's default
# PATH (/usr/bin:/bin:/usr/sbin:/sbin) has to be added by hand. `op` is in /usr/local/bin.
path add "/opt/homebrew/bin"
path add "/usr/local/bin"
path add ([$env.home, ".local", "bin"] | str join '/')

$env.config.show_banner = false
$env.config.rm.always_trash = true
$env.config.completions.algorithm = "fuzzy"
$env.config.buffer_editor = ["zed", "-w"]

# External completions: carapace for most commands, fish for git (nicer remote/branch completion)
let fish_completer = {|spans|
  ^fish --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
  | from tsv --flexible --noheaders --no-infer
  | rename value description
}

let carapace_completer = {|spans|
  carapace $spans.0 nushell ...$spans | from json
}

$env.config.completions.external = {
  enable: true
  max_results: 100
  completer: {|spans|
    let expanded_alias = (scope aliases | where name == $spans.0 | get -o 0.expansion)
    let spans = if $expanded_alias != null {
      $spans | skip 1 | prepend ($expanded_alias | split row ' ' | take 1)
    } else { $spans }
    match $spans.0 {
      git => $fish_completer
      nu => $fish_completer
      _ => $carapace_completer
    } | do $in $spans
  }
}

# Use 1Password SSH agent (git commit signing + SSH auth)
$env.SSH_AUTH_SOCK = ($env.HOME | path join "Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock")

# GitHub Packages token, read from 1Password on first use rather than at startup:
# resolving it eagerly would add an `op` round-trip to every new tab.
# This is the same item the `gh` shell plugin is wired to.
const GITHUB_PAT_REF = "op://Private/GitHub Personal Access Token/token"

# Cached in $env after the first call, so 1Password unlocks at most once per shell.
def --env load-github-token [] {
  if ($env.GITHUB_TOKEN? | is-not-empty) { return }
  let result = (^op read $GITHUB_PAT_REF | complete)
  if $result.exit_code != 0 {
    # Warn instead of failing: `bundle exec` and most gem subcommands don't touch
    # the registry, and erroring here would break them whenever 1Password is locked.
    print -e $"warning: no GitHub token from 1Password: ($result.stderr | str trim)"
    return
  }
  let token = ($result.stdout | str trim)
  $env.BUNDLE_RUBYGEMS__PKG__GITHUB__COM = $token
  # The nevaya .npmrc files interpolate ${GITHUB_PACKAGES_TOKEN}; one older repo
  # uses ${GITHUB_TOKEN}. NODE_AUTH_TOKEN is the GitHub Actions convention.
  $env.GITHUB_PACKAGES_TOKEN = $token
  $env.GITHUB_TOKEN = $token
  $env.NODE_AUTH_TOKEN = $token
}

# Anything that resolves packages from *.pkg.github.com needs the token loaded first.
def --env --wrapped bundle [...args] { load-github-token; ^bundle ...$args }
def --env --wrapped gem [...args] { load-github-token; ^gem ...$args }
def --env --wrapped npm [...args] { load-github-token; ^npm ...$args }
def --env --wrapped yarn [...args] { load-github-token; ^yarn ...$args }
def --env --wrapped pnpm [...args] { load-github-token; ^pnpm ...$args }

# AWS defaults
$env.AWS_PROFILE = "staging"
$env.AWS_REGION = "eu-west-1"

# EDITOR
$env.EDITOR = "zed -w"

# Mise
mkdir ($nu.data-dir | path join "vendor/autoload")
^mise activate nu | save -f ($nu.data-dir | path join "vendor/autoload/mise.nu")

# Starship prompt. Config lives at the default ~/.config/starship.toml.
^starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# iTerm tab title: show the current directory name.
# nushell's built-in osc2 only sets the *window* title; OSC 1 sets the *tab* title.
$env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt | append {||
  let title = ($env.PWD | path basename)
  print -rn $"\e]1;($title)\u{7}"
})

# Aliases
$env.config.abbreviations = {
  gs: "git status",
  ll: "ls -l",
  ptop: "ps | sort-by -r cpu | first 10",
  be: "bundle exec",
  bi: "bundle install",
  pi: "with-env { AWS_PROFILE: "" } { omp }"
}

alias lg = lazygit

# Rewrite every commit on the current branch so each one gets signed (1Password SSH key).
def gsign [base?: string] {
  let onto = if ($base | is-not-empty) { $base } else {
    git merge-base HEAD origin/HEAD | str trim
  }
  git rebase --force-rebase --gpg-sign $onto
}

# Jump to a project under ~/a/personal or ~/a/nevaya via fzf (1 or 2 levels deep)
def --env j [] {
  # Use `ls` (one level at a time) rather than `glob "*/*"`: nushell's glob
  # walks the entire recursive tree (node_modules, .git, build output) before
  # filtering, which made this take ~30s. `ls` only reads the levels we want.
  # `ls` also hides dotfiles by default, so .git/.zed are already excluded.
  let dirs = (
    [~/a/personal ~/a/nevaya]
    | each {|root|
        let base = ($root | path expand)
        # symlink included: repos moved to the sandvault shared folder leave symlinks here
        let lvl1 = (ls $base | where type in [dir symlink] | get name)
        let lvl2 = ($lvl1 | each {|d| ls $d | where type in [dir symlink] | get name } | flatten)
        $lvl1 | append $lvl2
      }
    | flatten
  )
  let result = (
    $dirs
    | str join (char nl)
    | fzf --height 40% --reverse --prompt "project> "
    | complete
  )
  if $result.exit_code == 0 {
    cd ($result.stdout | str trim)
  }
}

# Ctrl+G: run the project picker without typing `j`
$env.config.keybindings = ($env.config.keybindings | append {
  name: jump_project
  modifier: control
  keycode: char_g
  mode: [emacs vi_insert vi_normal]
  event: { send: executehostcommand, cmd: "j" }
})
