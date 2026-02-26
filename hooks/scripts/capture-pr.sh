#!/usr/bin/env bash
# Hook: PostToolUse (Bash)
# Captures GitHub PR URLs from Bash tool output and records them in workspace.json

set -euo pipefail

# Read stdin JSON from Claude hook system
INPUT=$(cat)

# Extract tool_result - check both stdout and raw output
TOOL_RESULT=$(echo "$INPUT" | jq -r '
  (.tool_result.stdout // "") + "\n" + (.tool_result // "" | if type == "string" then . else "" end)
')

# Search for GitHub PR URL pattern
PR_URL=$(echo "$TOOL_RESULT" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 || true)

if [[ -z "$PR_URL" ]]; then
  exit 0
fi

# Parse PR number from URL
PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')

# Determine workspace from cwd
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
if [[ -z "$CWD" ]]; then
  exit 0
fi

# Match pattern: */repos/<repo>/<workspace>*
if [[ "$CWD" =~ /repos/([^/]+)/([^/]+) ]]; then
  REPO="${BASH_REMATCH[1]}"
  WORKSPACE="${BASH_REMATCH[2]}"
else
  exit 0
fi

# Read metarepo path from config
CONFIG_FILE="$HOME/.claude/workspace-config.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0
fi

METAREPO=$(jq -r '.metarepo // ""' "$CONFIG_FILE")
METAREPO="${METAREPO/#\~/$HOME}"

if [[ -z "$METAREPO" || ! -d "$METAREPO" ]]; then
  exit 0
fi

WORKSPACE_JSON="$METAREPO/notes/$REPO/$WORKSPACE/workspace.json"

if [[ ! -f "$WORKSPACE_JSON" ]]; then
  exit 0
fi

# Check if this PR is already in references (deduplicate by number)
EXISTING=$(jq -r --argjson num "$PR_NUMBER" '
  .references // [] | map(select(.type == "pr" and .number == $num)) | length
' "$WORKSPACE_JSON")

if [[ "$EXISTING" -gt 0 ]]; then
  exit 0
fi

# Capture JJ change ID from workspace cwd
JJ_CHANGE_ID=$(cd "$CWD" && jj log -r @ --no-graph -T change_id 2>/dev/null || echo "")

# Capture branch/bookmark name
JJ_BRANCH=$(cd "$CWD" && jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null || echo "")

# Get current date
TODAY=$(date +%Y-%m-%d)

# Append PR reference to workspace.json using jq
jq --arg url "$PR_URL" \
   --argjson num "$PR_NUMBER" \
   --arg change_id "$JJ_CHANGE_ID" \
   --arg branch "$JJ_BRANCH" \
   --arg added "$TODAY" \
   '.references = (.references // []) + [{
     type: "pr",
     number: $num,
     url: $url,
     jj_change_id: $change_id,
     branch: $branch,
     added: $added
   }]' "$WORKSPACE_JSON" > "${WORKSPACE_JSON}.tmp" && mv "${WORKSPACE_JSON}.tmp" "$WORKSPACE_JSON"

# Output system message
echo "{\"systemMessage\": \"Auto-captured PR #${PR_NUMBER} reference in workspace ${WORKSPACE}\"}"
