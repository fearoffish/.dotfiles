# env.nu
#
# Installed by:
# version = "0.113.1"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

# Mark shells spawned by coding agents so scripts and prompts can detect them.
if ([CLAUDECODE CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_SESSION_ID CODEX_CI CODEX_THREAD_ID CODEX_TUI_SESSION_LOG_PATH] | any {|v| $v in $env }) {
    $env.CODING_AGENT_SHELL = "1"
}
