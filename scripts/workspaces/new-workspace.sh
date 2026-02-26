#!/usr/bin/env bash
# new-workspace.sh - Create a new JJ workspace within an onboarded repo
#
# Usage: new-workspace.sh <repo> <name> [--type <type>] [--purpose <purpose>] [--owner <owner>]
#
# Name must match: epic-<kebab>, spike-<kebab>, or pr-<number>

set -euo pipefail

# --- Helpers ---

die() { echo "ERROR: $*" >&2; exit 1; }

resolve_metarepo() {
  local config="$HOME/.claude/workspace-config.json"
  [[ -f "$config" ]] || die "Config not found: $config"
  local raw
  raw=$(jq -r '.metarepo' "$config")
  [[ "$raw" != "null" && -n "$raw" ]] || die "metarepo not set in $config"
  echo "${raw/#\~/$HOME}"
}

usage() {
  echo "Usage: new-workspace.sh <repo> <name> [--type <type>] [--purpose <purpose>] [--owner <owner>]"
  echo ""
  echo "Name must match: epic-<kebab>, spike-<kebab>, or pr-<number>"
  exit 1
}

# --- Parse arguments ---

REPO=""
WS_NAME=""
WS_TYPE=""
WS_PURPOSE=""
WS_OWNER="${USER:-unknown}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)    WS_TYPE="$2"; shift 2 ;;
    --purpose) WS_PURPOSE="$2"; shift 2 ;;
    --owner)   WS_OWNER="$2"; shift 2 ;;
    --help|-h) usage ;;
    *)
      if [[ -z "$REPO" ]]; then
        REPO="$1"
      elif [[ -z "$WS_NAME" ]]; then
        WS_NAME="$1"
      else
        die "Unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

[[ -n "$REPO" && -n "$WS_NAME" ]] || usage

# --- Resolve metarepo ---

METAREPO=$(resolve_metarepo)
[[ -d "$METAREPO" ]] || die "Metarepo directory not found: $METAREPO"

# --- Validate repo exists ---

REPO_JSON="$METAREPO/repos/$REPO/.repo.json"
[[ -f "$REPO_JSON" ]] || die "Repo '$REPO' not found. Expected: $REPO_JSON\nRun add-repo.sh first."

TRUNK_DIR="$METAREPO/repos/$REPO/trunk"
[[ -d "$TRUNK_DIR" ]] || die "Trunk directory not found: $TRUNK_DIR"

# --- Validate workspace name ---

if [[ "$WS_NAME" =~ ^epic-[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  INFERRED_TYPE="epic"
elif [[ "$WS_NAME" =~ ^spike-[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  INFERRED_TYPE="spike"
elif [[ "$WS_NAME" =~ ^pr-[0-9]+$ ]]; then
  INFERRED_TYPE="pr"
else
  die "Invalid workspace name: '$WS_NAME'\nMust match: epic-<kebab>, spike-<kebab>, or pr-<number>"
fi

# Use inferred type if not explicitly set
WS_TYPE="${WS_TYPE:-$INFERRED_TYPE}"

# --- Check workspace doesn't already exist ---

WS_DIR="$METAREPO/repos/$REPO/$WS_NAME"
NOTES_DIR="$METAREPO/notes/$REPO/$WS_NAME"

if [[ -d "$WS_DIR" ]]; then
  die "Workspace directory already exists: $WS_DIR"
fi

if [[ -d "$NOTES_DIR" ]]; then
  die "Notes directory already exists: $NOTES_DIR"
fi

echo "Creating workspace: $REPO/$WS_NAME"
echo "  Type:    $WS_TYPE"
echo "  Purpose: ${WS_PURPOSE:-<not set>}"

# --- Create notes directory ---

mkdir -p "$NOTES_DIR"

# --- Create workspace.json ---

TODAY=$(date +%Y-%m-%d)

# For PR workspaces, try to get PR info
PR_TITLE=""
PR_URL=""
PR_BRANCH=""
JIRA_LINKS="none"

if [[ "$WS_TYPE" == "pr" ]]; then
  PR_NUMBER="${WS_NAME#pr-}"
  GITHUB_OWNER=$(jq -r '.github_owner' "$REPO_JSON")
  GITHUB_REPO=$(jq -r '.github_repo' "$REPO_JSON")

  if [[ -n "$GITHUB_OWNER" && "$GITHUB_OWNER" != "null" && -n "$GITHUB_REPO" && "$GITHUB_REPO" != "null" ]]; then
    echo "  Fetching PR #$PR_NUMBER info..."
    if PR_INFO=$(gh pr view "$PR_NUMBER" --repo "$GITHUB_OWNER/$GITHUB_REPO" --json headRefName,title,url 2>/dev/null); then
      PR_BRANCH=$(echo "$PR_INFO" | jq -r '.headRefName')
      PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
      PR_URL=$(echo "$PR_INFO" | jq -r '.url')
      echo "  PR: $PR_TITLE"
      echo "  Branch: $PR_BRANCH"

      # Extract Jira ticket from PR title (e.g., "PROJ-123" or "TEAM-456")
      if [[ "$PR_TITLE" =~ ([A-Z]+-[0-9]+) ]]; then
        JIRA_LINKS="${BASH_REMATCH[1]}"
      fi

      # Auto-set purpose from PR title if not provided
      if [[ -z "$WS_PURPOSE" ]]; then
        WS_PURPOSE="PR #$PR_NUMBER: $PR_TITLE"
      fi
    else
      echo "  WARNING: Could not fetch PR info (gh may not be available)"
    fi
  fi
fi

WS_PURPOSE="${WS_PURPOSE:-$WS_TYPE workspace}"

# Build references array
REFERENCES="[]"
if [[ -n "$PR_URL" ]]; then
  REFERENCES=$(jq -n \
    --arg url "$PR_URL" \
    --arg title "$PR_TITLE" \
    '[{ type: "pr", url: $url, title: $title }]')
fi

jq -n \
  --arg repo "$REPO" \
  --arg name "$WS_NAME" \
  --arg type "$WS_TYPE" \
  --arg purpose "$WS_PURPOSE" \
  --arg owner "$WS_OWNER" \
  --arg created "$TODAY" \
  --argjson references "$REFERENCES" \
  '{
    repo: $repo,
    name: $name,
    type: $type,
    purpose: $purpose,
    owner: $owner,
    created: $created,
    retired: null,
    references: $references
  }' > "$NOTES_DIR/workspace.json"

echo "  Created workspace.json"

# --- Create README.md from template ---

TEMPLATE="$METAREPO/plugin/templates/workspace-readme.md"
if [[ -f "$TEMPLATE" ]]; then
  sed \
    -e "s/{{workspace-name}}/$WS_NAME/g" \
    -e "s/{{repo-name}}/$REPO/g" \
    -e "s/{{owner}}/$WS_OWNER/g" \
    -e "s/{{type}}/$WS_TYPE/g" \
    -e "s/{{created-date}}/$TODAY/g" \
    -e "s|{{jira-links}}|$JIRA_LINKS|g" \
    "$TEMPLATE" > "$NOTES_DIR/README.md"
  echo "  Created README.md"
else
  echo "  WARNING: Template not found at $TEMPLATE, skipping README."
fi

# --- Create JJ workspace ---

echo "  Creating JJ workspace..."

# Fetch latest before creating workspace
(cd "$TRUNK_DIR" && jj git fetch 2>/dev/null) || echo "  WARNING: jj git fetch failed (may be offline)"

if [[ "$WS_TYPE" == "pr" && -n "$PR_BRANCH" ]]; then
  # For PR workspaces, try to create at the PR branch revision
  echo "  Targeting branch: $PR_BRANCH"
  (cd "$TRUNK_DIR" && jj workspace add "../$WS_NAME" -r "$PR_BRANCH@origin") \
    || die "Failed to create JJ workspace at branch $PR_BRANCH"
else
  (cd "$TRUNK_DIR" && jj workspace add "../$WS_NAME") \
    || die "Failed to create JJ workspace"
fi

echo "  JJ workspace created."

# --- Create symlinks ---

REL_NOTES="../../../notes/$REPO/$WS_NAME"

if [[ ! -L "$WS_DIR/.workspace.json" ]]; then
  ln -s "$REL_NOTES/workspace.json" "$WS_DIR/.workspace.json"
  echo "  Created .workspace.json symlink"
fi

if [[ ! -L "$WS_DIR/.notes" ]]; then
  ln -s "$REL_NOTES/" "$WS_DIR/.notes"
  echo "  Created .notes symlink"
fi

# --- Add to .git/info/exclude ---

# JJ workspaces share the .git, find it
if [[ -f "$WS_DIR/.git" ]]; then
  # .git is a file pointing to the shared gitdir
  GITDIR=$(sed -n 's/^gitdir: //p' "$WS_DIR/.git")
  if [[ -n "$GITDIR" ]]; then
    EXCLUDE_DIR="$WS_DIR/$GITDIR/info"
  else
    EXCLUDE_DIR="$WS_DIR/.git/info"
  fi
elif [[ -d "$WS_DIR/.git" ]]; then
  EXCLUDE_DIR="$WS_DIR/.git/info"
else
  # Fallback: use trunk's exclude file
  EXCLUDE_DIR="$TRUNK_DIR/.git/info"
fi

EXCLUDE_FILE="$EXCLUDE_DIR/exclude"
mkdir -p "$EXCLUDE_DIR"
touch "$EXCLUDE_FILE"

for pattern in ".workspace.json" ".notes"; do
  if ! grep -qxF "$pattern" "$EXCLUDE_FILE" 2>/dev/null; then
    echo "$pattern" >> "$EXCLUDE_FILE"
  fi
done

# --- Done ---

echo ""
echo "Workspace '$WS_NAME' created successfully!"
echo "  Workspace: $WS_DIR"
echo "  Notes:     $NOTES_DIR"
echo "  Type:      $WS_TYPE"
