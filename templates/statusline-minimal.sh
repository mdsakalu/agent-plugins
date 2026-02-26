#!/bin/bash
# Minimal workspace statusline for Claude Code
#
# Shows: workspace name (type-aware icons), model, context %
# Writes: session metadata to /tmp/claude-session-$PPID (required for /workspace:cd respawn)
#
# Install: copy to ~/.claude/statusline-jj-workspace.sh, set metarepo_root below,
# then add to ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-jj-workspace.sh" }

# ---- CONFIGURE THIS ----
metarepo_root="__METAREPO_ROOT__"
# -------------------------

# Read JSON input from stdin
input=$(cat)

# Write session metadata for respawn support (/workspace:cd)
_sid=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)
_tp=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
if [[ -n "$_sid" ]]; then
  printf '%s\n%s\n' "$_sid" "$_tp" > "/tmp/claude-session-${PPID}" 2>/dev/null
fi

# ANSI color codes
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
BLUE="\033[34m"
RED="\033[31m"

# Parse input fields in a single jq call
parsed=$(echo "$input" | jq -r '[
  .workspace.current_dir // "",
  .model.display_name // .model.id // "unknown",
  .context_window.current_usage.input_tokens // 0,
  .context_window.current_usage.cache_creation_input_tokens // 0,
  .context_window.current_usage.cache_read_input_tokens // 0,
  .context_window.context_window_size // 200000
] | @tsv' 2>/dev/null)

IFS=$'\t' read -r workspace_dir model_name input_tokens cache_create cache_read context_size <<< "$parsed"

# Calculate context usage percentage
total_input=$((input_tokens + cache_create + cache_read))
context_pct=0
[[ "$context_size" -gt 0 ]] && context_pct=$((total_input * 100 / context_size))

# Clean up model name
model_short="${model_name/Claude /}"

# Color context percentage by severity
color_context_pct() {
  local pct="$1"
  if [[ $pct -lt 50 ]]; then
    echo "${GREEN}${pct}%${RESET}"
  elif [[ $pct -lt 75 ]]; then
    echo "${YELLOW}${pct}%${RESET}"
  elif [[ $pct -lt 90 ]]; then
    echo "${MAGENTA}${pct}%${RESET}"
  else
    echo "${RED}${pct}%${RESET}"
  fi
}

# Detect workspace from current directory
workspace_name=""

if [[ "$workspace_dir" == "$metarepo_root" ]]; then
  workspace_name="metarepo"
elif [[ "$workspace_dir" == "$metarepo_root"/* ]]; then
  rel_path="${workspace_dir#$metarepo_root/}"
  top_dir="${rel_path%%/*}"
  if [[ "$top_dir" == "repos" || "$top_dir" == "notes" ]]; then
    remainder="${rel_path#*/}"
    repo_name="${remainder%%/*}"
    ws_remainder="${remainder#*/}"
    ws_name="${ws_remainder%%/*}"
    if [[ -n "$repo_name" && -n "$ws_name" && "$ws_name" != "$remainder" ]]; then
      workspace_name="${repo_name}/${ws_name}"
    elif [[ -n "$repo_name" ]]; then
      workspace_name="${repo_name}"
    fi
  else
    workspace_name="metarepo"
  fi
fi

# Build status line
status_line=""

# Workspace segment with type-aware icons and colors
if [[ -n "$workspace_name" ]]; then
  ws_suffix="${workspace_name##*/}"
  if [[ "$workspace_name" == "metarepo" ]]; then
    ws_color="${CYAN}"; ws_icon="📁"
  elif [[ "$ws_suffix" == spike-* ]]; then
    ws_color="${MAGENTA}"; ws_icon="🧪"
  elif [[ "$ws_suffix" == epic-* ]]; then
    ws_color="${GREEN}"; ws_icon="🚀"
  elif [[ "$ws_suffix" == pr-* ]]; then
    ws_color="${BLUE}"; ws_icon="🔀"
  elif [[ "$ws_suffix" == trunk ]]; then
    ws_color="${CYAN}"; ws_icon="🌳"
  else
    ws_color="${CYAN}"; ws_icon="📁"
  fi
  status_line="${ws_icon} ${BOLD}${ws_color}${workspace_name}${RESET}"
fi

# Model + context %
if [[ -n "$model_short" ]]; then
  [[ -n "$status_line" ]] && status_line="${status_line}${DIM}│${RESET}"
  status_line="${status_line}🤖 ${BLUE}${model_short}${RESET}"
  status_line="${status_line} 📜$(color_context_pct "$context_pct")"
fi

printf "%b" "$status_line"
