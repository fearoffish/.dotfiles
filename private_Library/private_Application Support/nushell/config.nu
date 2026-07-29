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
path add "/opt/homebrew/bin"
path add ([$env.home, ".local", "bin"] | str join '/')

$env.config.show_banner = false
$env.config.rm.always_trash = true
$env.config.completions.algorithm = "fuzzy"
$env.config.buffer_editor = ["zed", "-w"]

# Use 1Password SSH agent (git commit signing + SSH auth)
$env.SSH_AUTH_SOCK = ($env.HOME | path join "Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock")

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
  bi: "bundle install"
}

# jj describe with a -m message, no quotes needed: jjdm something I wrote
def jjdm [...message: string] {
  jj describe -m ($message | str join " ")
}

# jj commit with a -m message, no quotes needed: jjcm something I wrote
def jjcm [...message: string] {
  jj commit -m ($message | str join " ")
}

# Jump to a project under ~/a/personal or ~/a/nevaya via fzf (1 or 2 levels deep)
def --env j [] {
  let dirs = (
    [~/a/personal ~/a/nevaya]
    | each {|root|
        let base = ($root | path expand)
        glob $"($base)/*" --no-file
        | append (glob $"($base)/*/*" --no-file)
      }
    | flatten
    | where $it !~ "/\\."          # skip hidden dirs like .git, .zed
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
