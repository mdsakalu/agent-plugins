#!/usr/bin/env bash
# Hook: UserPromptSubmit
# Injects workspace context on first prompt of a session

set -euo pipefail

# Read stdin JSON from Claude hook system
INPUT=$(cat)

# Extract session_id and cwd
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

if [[ -z "$SESSION_ID" || -z "$CWD" ]]; then
  exit 0
fi

# Check flag file - only run once per session
FLAG_FILE="/tmp/workspace-context-${SESSION_ID}"
if [[ -f "$FLAG_FILE" ]]; then
  exit 0
fi

# Check if cwd matches workspace pattern: */repos/<repo>/<workspace>*
if [[ "$CWD" =~ /repos/([^/]+)/([^/]+) ]]; then
  REPO="${BASH_REMATCH[1]}"
  WORKSPACE="${BASH_REMATCH[2]}"
else
  # Not in a workspace, create flag and exit
  touch "$FLAG_FILE"
  exit 0
fi

# Read metarepo path from config
CONFIG_FILE="$HOME/.claude/workspace-config.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
  touch "$FLAG_FILE"
  exit 0
fi

METAREPO=$(jq -r '.metarepo // ""' "$CONFIG_FILE")
METAREPO="${METAREPO/#\~/$HOME}"

if [[ -z "$METAREPO" || ! -d "$METAREPO" ]]; then
  touch "$FLAG_FILE"
  exit 0
fi

WORKSPACE_JSON="$METAREPO/notes/$REPO/$WORKSPACE/workspace.json"
README_FILE="$METAREPO/notes/$REPO/$WORKSPACE/README.md"

# Build context string
CONTEXT="Workspace: ${WORKSPACE} (repo: ${REPO})"

# Read workspace.json if it exists
if [[ -f "$WORKSPACE_JSON" ]]; then
  WS_TYPE=$(jq -r '.type // "unknown"' "$WORKSPACE_JSON")
  WS_PURPOSE=$(jq -r '.purpose // ""' "$WORKSPACE_JSON")
  REF_COUNT=$(jq -r '.references // [] | length' "$WORKSPACE_JSON")

  CONTEXT="${CONTEXT}\nType: ${WS_TYPE}"
  if [[ -n "$WS_PURPOSE" ]]; then
    CONTEXT="${CONTEXT}\nPurpose: ${WS_PURPOSE}"
  fi
  if [[ "$REF_COUNT" -gt 0 ]]; then
    CONTEXT="${CONTEXT}\nReferences: ${REF_COUNT} tracked"
  fi
fi

# Read first 20 lines of README if it exists
if [[ -f "$README_FILE" ]]; then
  README_EXCERPT=$(head -20 "$README_FILE" 2>/dev/null || true)
  if [[ -n "$README_EXCERPT" ]]; then
    CONTEXT="${CONTEXT}\n\n--- Workspace Notes (first 20 lines) ---\n${README_EXCERPT}"
  fi
fi

# Get current JJ revision
JJ_STATUS=$(cd "$CWD" && jj log -r @ --no-graph --limit 1 2>/dev/null || echo "")
if [[ -n "$JJ_STATUS" ]]; then
  CONTEXT="${CONTEXT}\n\n--- Current Revision ---\n${JJ_STATUS}"
fi

# Create flag file so this doesn't run again
touch "$FLAG_FILE"

# Escape for JSON output - use jq to safely encode the string
SYSTEM_MSG=$(printf '%b' "$CONTEXT" | jq -Rs '.')
echo "{\"systemMessage\": ${SYSTEM_MSG}}"
