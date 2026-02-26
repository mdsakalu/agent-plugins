#!/usr/bin/env bash
# Hook: PostToolUse (Bash)
# Captures Jira ticket references from Bash tool output and records them in workspace.json

set -euo pipefail

# Read stdin JSON from Claude hook system
INPUT=$(cat)

# Extract tool_result - check both stdout and raw output
TOOL_RESULT=$(echo "$INPUT" | jq -r '
  (.tool_result.stdout // "") + "\n" + (.tool_result // "" | if type == "string" then . else "" end)
')

# Search for Jira ticket patterns: 2-6 uppercase letters, dash, 1-5 digits
TICKETS=$(echo "$TOOL_RESULT" | grep -oE '\b[A-Z]{2,6}-[0-9]{1,5}\b' || true)

if [[ -z "$TICKETS" ]]; then
  exit 0
fi

# Filter out common false positives (non-Jira patterns)
FILTERED_TICKETS=""
while IFS= read -r ticket; do
  [[ -z "$ticket" ]] && continue
  PREFIX="${ticket%%-*}"
  case "$PREFIX" in
    UTF|ISO|ASCII|ANSI|IEEE|HTTP|HTTPS|HTML|XHTML|JSON|YAML|TOML|XML|CSS|SHA|MD|RSA|AES|SSL|TLS|TCP|UDP|DNS|SSH|FTP|SMTP|IMAP|LDAP|SAML|OIDC|RFC|API|SDK|JDK|JRE|JVM|NPM|PIP|AWS|GCP|CPU|GPU|RAM|SSD|HDD|NFS|EXT|FAT|NTFS|ZFS|LVM|POM|JAR|WAR|ZIP|TAR|GIT|SVN|CVS|CVE|CWE)
      # Skip known non-Jira prefixes
      ;;
    *)
      FILTERED_TICKETS="${FILTERED_TICKETS}${ticket}"$'\n'
      ;;
  esac
done <<< "$TICKETS"

# Deduplicate
FILTERED_TICKETS=$(echo "$FILTERED_TICKETS" | sort -u | sed '/^$/d')

if [[ -z "$FILTERED_TICKETS" ]]; then
  exit 0
fi

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

TODAY=$(date +%Y-%m-%d)
NEW_TICKETS=""

while IFS= read -r TICKET_KEY; do
  [[ -z "$TICKET_KEY" ]] && continue

  # Check if this ticket is already in references (deduplicate by key)
  EXISTING=$(jq -r --arg key "$TICKET_KEY" '
    .references // [] | map(select(.type == "jira" and .key == $key)) | length
  ' "$WORKSPACE_JSON")

  if [[ "$EXISTING" -gt 0 ]]; then
    continue
  fi

  # Append Jira reference to workspace.json
  jq --arg key "$TICKET_KEY" \
     --arg added "$TODAY" \
     '.references = (.references // []) + [{
       type: "jira",
       key: $key,
       added: $added
     }]' "$WORKSPACE_JSON" > "${WORKSPACE_JSON}.tmp" && mv "${WORKSPACE_JSON}.tmp" "$WORKSPACE_JSON"

  NEW_TICKETS="${NEW_TICKETS}${TICKET_KEY} "
done <<< "$FILTERED_TICKETS"

# Trim trailing space
NEW_TICKETS="${NEW_TICKETS% }"

if [[ -z "$NEW_TICKETS" ]]; then
  exit 0
fi

echo "{\"systemMessage\": \"Auto-captured Jira ticket(s) ${NEW_TICKETS} in workspace ${WORKSPACE}\"}"
