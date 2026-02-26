#!/usr/bin/env bash
# respawn-claude.sh - Kill Claude and restart it in a new directory via zmx
#
# Copies the current session file to the new project bucket, captures the
# original CLI flags (stripping --resume/--continue/--session-id), spawns a
# background watcher that restarts Claude after it dies, then kills the
# current instance.
#
# Usage: respawn-claude.sh <workspace-path> <claude-pid> [--fresh]
# Requires: ZMX_SESSION env var (must be inside a zmx session)
# Requires: /tmp/claude-session-<pid> file (written by statusline script)
# Options: --fresh  Start a fresh session instead of resuming the current one

set -euo pipefail

# --- Resolve metarepo from config ---

resolve_metarepo() {
  local config="$HOME/.claude/workspace-config.json"
  if [[ -f "$config" ]]; then
    local raw
    raw=$(jq -r '.metarepo' "$config" 2>/dev/null)
    if [[ "$raw" != "null" && -n "$raw" ]]; then
      echo "${raw/#\~/$HOME}"
      return 0
    fi
  fi
  echo ""
}

WORKSPACE_PATH="$1"
CLAUDE_PID="$2"
FRESH_SESSION=false
if [[ "${3:-}" == "--fresh" ]]; then
  FRESH_SESSION=true
fi
LOG="/tmp/claude-respawn.log"

# --- Validations ---

if [[ -z "${ZMX_SESSION:-}" ]]; then
  echo "ERROR: Not in a zmx session. Respawn requires zmx." >&2
  exit 1
fi

if ! kill -0 "$CLAUDE_PID" 2>/dev/null; then
  echo "ERROR: PID $CLAUDE_PID is not running." >&2
  exit 1
fi

if [[ ! -d "$WORKSPACE_PATH" ]]; then
  echo "ERROR: Workspace directory does not exist: $WORKSPACE_PATH" >&2
  exit 1
fi

# --- Get session metadata from statusline-written file ---
# The statusline script writes: line 1 = session ID, line 2 = transcript path

SESSION_META_FILE="/tmp/claude-session-${CLAUDE_PID}"
if [[ ! -f "$SESSION_META_FILE" ]]; then
  echo "ERROR: Session metadata file not found: $SESSION_META_FILE" >&2
  echo "The statusline script writes this file. Ensure statusline is configured." >&2
  exit 1
fi

SESSION_ID=$(sed -n '1p' "$SESSION_META_FILE")
TRANSCRIPT_PATH=$(sed -n '2p' "$SESSION_META_FILE")

if [[ -z "$SESSION_ID" ]]; then
  echo "ERROR: Session ID is empty in: $SESSION_META_FILE" >&2
  exit 1
fi

# --- Locate session file ---

if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
  SESSION_FILE="$TRANSCRIPT_PATH"
  SOURCE_PROJECT_DIR=$(dirname "$TRANSCRIPT_PATH")
else
  echo "ERROR: Transcript path not found or file missing: $TRANSCRIPT_PATH" >&2
  exit 1
fi

# --- Compute target project bucket ---
# Derive the encoding pattern from the source project dir name,
# then replace the source cwd suffix with the target workspace path.

SOURCE_DIR_NAME=$(basename "$SOURCE_PROJECT_DIR")
SOURCE_CWD="$(pwd)"

# Build target by replacing the source cwd portion in the encoded name
# with the target workspace path, using the same encoding Claude uses.
SOURCE_ENCODED=$(echo "$SOURCE_CWD" | sed 's/[^a-zA-Z0-9]/-/g')
TARGET_ENCODED=$(echo "$WORKSPACE_PATH" | sed 's/[^a-zA-Z0-9]/-/g')
TARGET_PROJECT_DIR="$HOME/.claude/projects/$TARGET_ENCODED"

# --- Copy session (skip if same directory or fresh) ---

if [[ "$FRESH_SESSION" == false && "$SOURCE_PROJECT_DIR" != "$TARGET_PROJECT_DIR" ]]; then
  mkdir -p "$TARGET_PROJECT_DIR"
  cp "$SESSION_FILE" "$TARGET_PROJECT_DIR/"

  # Copy companion directory if it exists (stores sub-agent data, etc.)
  if [[ -d "$SOURCE_PROJECT_DIR/$SESSION_ID" ]]; then
    cp -r "$SOURCE_PROJECT_DIR/$SESSION_ID" "$TARGET_PROJECT_DIR/"
  fi
fi

# --- Capture original CLI flags ---

ORIGINAL_CMD=$(ps -o args= -p "$CLAUDE_PID")

# Strip the binary name, then remove --resume/-r/--continue/-c/--session-id
# and their values to avoid double-resume. We add our own --resume.
FLAGS="$ORIGINAL_CMD"
# Remove binary name (first word)
FLAGS="${FLAGS#* }"
# Remove flags that would conflict with our --resume
FLAGS=$(echo " $FLAGS " | \
  sed -E 's/ --resume [^ ]*/ /g' | \
  sed -E 's/ -r [^ ]*/ /g' | \
  sed -E 's/ --continue / /g' | \
  sed -E 's/ -c / /g' | \
  sed -E 's/ --session-id [^ ]*/ /g' | \
  sed -E 's/ --fork-session / /g' | \
  sed -E 's/  +/ /g' | \
  sed -E 's/^ +//;s/ +$//')

# Build respawn command
if [[ "$FRESH_SESSION" == true ]]; then
  RESPAWN_CMD="cd $WORKSPACE_PATH && claude $FLAGS"
else
  RESPAWN_CMD="cd $WORKSPACE_PATH && claude $FLAGS --resume $SESSION_ID"
fi

# --- Log ---

echo "$(date): respawn starting" > "$LOG"
echo "session: $SESSION_ID" >> "$LOG"
echo "source: $SOURCE_CWD" >> "$LOG"
echo "target: $WORKSPACE_PATH" >> "$LOG"
echo "flags: $FLAGS" >> "$LOG"
echo "respawn_cmd: $RESPAWN_CMD" >> "$LOG"
echo "claude_pid: $CLAUDE_PID" >> "$LOG"

# --- Spawn background watcher and kill Claude ---

(
  echo "$(date): waiting for claude PID $CLAUDE_PID to die..." >> "$LOG"
  while kill -0 "$CLAUDE_PID" 2>/dev/null; do sleep 0.5; done
  echo "$(date): claude died, waiting 1s for shell to settle..." >> "$LOG"
  sleep 1
  echo "$(date): sending zmx run $ZMX_SESSION..." >> "$LOG"
  zmx run "$ZMX_SESSION" "$RESPAWN_CMD" >> "$LOG" 2>&1
  echo "$(date): zmx run exit code: $?" >> "$LOG"
) &
disown

echo "command sent" >> "$LOG"
kill "$CLAUDE_PID"
