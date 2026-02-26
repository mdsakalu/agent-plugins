#!/usr/bin/env bash
# Hook: PreToolUse (Edit|Write)
# Warns when editing files outside the current workspace boundary

set -euo pipefail

# Read stdin JSON from Claude hook system
INPUT=$(cat)

# Extract file_path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Extract cwd
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
if [[ -z "$CWD" ]]; then
  exit 0
fi

# Check if cwd is inside a workspace: match */repos/<repo>/<workspace>*
if [[ "$CWD" =~ /repos/([^/]+)/([^/]+) ]]; then
  REPO="${BASH_REMATCH[1]}"
  WORKSPACE="${BASH_REMATCH[2]}"
else
  # Not in a workspace, no warning needed
  exit 0
fi

# Read metarepo path from config
CONFIG_FILE="$HOME/.claude/workspace-config.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0
fi

METAREPO=$(jq -r '.metarepo // ""' "$CONFIG_FILE")
METAREPO="${METAREPO/#\~/$HOME}"

if [[ -z "$METAREPO" ]]; then
  exit 0
fi

# Build the workspace directory path
WORKSPACE_DIR="$METAREPO/repos/$REPO/$WORKSPACE"
NOTES_DIR="$METAREPO/notes/$REPO/$WORKSPACE"

# Check if file is inside the workspace directory
if [[ "$FILE_PATH" == "$WORKSPACE_DIR"* ]]; then
  exit 0
fi

# Allow edits to the notes directory (direct path)
if [[ "$FILE_PATH" == "$NOTES_DIR"* ]]; then
  exit 0
fi

# Allow edits to metarepo-level files (scripts, templates, CLAUDE.md, etc.)
if [[ "$FILE_PATH" == "$METAREPO"* ]]; then
  # Allow metarepo root files and scripts but still warn about other workspace dirs
  if [[ "$FILE_PATH" == "$METAREPO/repos/"* && "$FILE_PATH" != "$WORKSPACE_DIR"* ]]; then
    echo "{\"systemMessage\": \"Warning: You're editing a file in a DIFFERENT workspace. Current workspace: ${WORKSPACE} in ${REPO}. Target: ${FILE_PATH}\"}"
    exit 0
  fi
  # Metarepo root files (scripts, templates, etc.) are fine
  exit 0
fi

# File is outside workspace - warn
echo "{\"systemMessage\": \"Warning: You're editing a file outside your current workspace (${WORKSPACE} in ${REPO}). Target: ${FILE_PATH}\"}"
exit 0
