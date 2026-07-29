#!/bin/sh
# Claude Code status line — mirrors your Starship prompt segments:
#   directory (3-segment truncated) | git branch | model | time | ctx% | rate limits
input=$(cat)

GREEN=$'\033[0;32m'
PINK=$'\033[38;5;212m'
PURPLE=$'\033[38;5;97m'
ORANGE=$'\033[38;5;214m'
GREY=$'\033[38;5;59m'
WHITE=$'\033[0;37m'
RESET=$'\033[0m'
SEP="${GREY} │ ${RESET}"

# Directory — truncate to last 3 segments
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
short_path=$(echo "$cwd" | awk -F/ '{
  n=split($0,a,"/");
  if(n<=3) { print $0 }
  else { printf "…/%s/%s/%s", a[n-2], a[n-1], a[n] }
}')
dir_text="${GREEN}${short_path}${RESET}"

# git branch (or detached short sha) plus dirty file count
git_text=""
if git -C "${cwd:-.}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "${cwd:-.}" branch --show-current 2>/dev/null)
  [ -n "$branch" ] || branch=$(git -C "${cwd:-.}" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "${cwd:-.}" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ -n "$branch" ]; then
    git_text="${PINK} ${branch}${RESET}"
    [ "${dirty:-0}" -gt 0 ] 2>/dev/null && git_text="${git_text}${PINK} ±${dirty}${RESET}"
  fi
fi

# Model
model=$(echo "$input" | jq -r '.model.display_name // ""')
model_text=""
[ -n "$model" ] && model_text="${PURPLE}${model}${RESET}"

# Time
time_text="${GREY}$(date +%H:%M)${RESET}"

# Context usage
ctx_text=""
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  # Color: green → orange → red based on usage
  if [ "$used_int" -le 50 ]; then
    ctx_color="$GREEN"
  elif [ "$used_int" -le 75 ]; then
    ctx_color="$ORANGE"
  else
    ctx_color="$WHITE"
  fi
  ctx_text="${ctx_color}ctx:${used_int}%${RESET}"
fi

# Rate limits — show remaining %, coloured like ctx as they run down
rate_segment() {
  used_pct=$1
  label=$2
  [ -n "$used_pct" ] || return
  left=$(awk "BEGIN { printf \"%.0f\", 100 - $used_pct }")
  if [ "$left" -ge 50 ]; then
    color="$GREY"
  elif [ "$left" -ge 25 ]; then
    color="$ORANGE"
  else
    color="$WHITE"
  fi
  printf '%s' "${color}${label}:${left}%${RESET}"
}
five_text=$(rate_segment "$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')" "5h")
week_text=$(rate_segment "$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')" "wk")

# Assemble with separators
output="${dir_text}"
[ -n "$git_text" ]   && output="${output}${SEP}${git_text}"
[ -n "$model_text" ] && output="${output}${SEP}${model_text}"
output="${output}${SEP}${time_text}"
[ -n "$ctx_text" ]   && output="${output}${SEP}${ctx_text}"
[ -n "$five_text" ]  && output="${output}${SEP}${five_text}"
[ -n "$week_text" ]  && output="${output}${SEP}${week_text}"

printf "%s\n" "$output"
