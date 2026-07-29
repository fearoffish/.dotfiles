# Mark shells spawned by coding agents so scripts and prompts can detect them.
if set -q CLAUDECODE; or set -q CLAUDE_CODE_ENTRYPOINT; or set -q CLAUDE_CODE_SESSION_ID; or set -q CODEX_CI; or set -q CODEX_THREAD_ID; or set -q CODEX_TUI_SESSION_LOG_PATH
    set -gx CODING_AGENT_SHELL 1
end
