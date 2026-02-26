#!/usr/bin/env bash
# add-repo.sh - Onboard a new repository into the metarepo
#
# Usage: add-repo.sh <github-url-or-owner/repo> [--name <name>] [--path /existing/clone]
#
# Accepts:
#   https://github.com/org/repo.git
#   org/repo
#   --path /existing/clone  (use an existing local clone)

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
  echo "Usage: add-repo.sh <github-url-or-owner/repo> [--name <name>] [--path /existing/clone]"
  exit 1
}

# --- Parse arguments ---

GITHUB_URL=""
REPO_NAME=""
LOCAL_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)  REPO_NAME="$2"; shift 2 ;;
    --path)  LOCAL_PATH="$2"; shift 2 ;;
    --help|-h) usage ;;
    *)
      if [[ -z "$GITHUB_URL" ]]; then
        GITHUB_URL="$1"
      else
        die "Unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

[[ -n "$GITHUB_URL" || -n "$LOCAL_PATH" ]] || usage

# --- Resolve metarepo ---

METAREPO=$(resolve_metarepo)
[[ -d "$METAREPO" ]] || die "Metarepo directory not found: $METAREPO"

# --- Parse URL and determine repo name ---

CLONE_URL=""
GITHUB_OWNER=""
GITHUB_REPO_NAME=""

if [[ -n "$LOCAL_PATH" ]]; then
  # Using an existing local clone
  [[ -d "$LOCAL_PATH/.git" ]] || die "Not a git repository: $LOCAL_PATH"
  # Try to extract origin URL
  CLONE_URL=$(git -C "$LOCAL_PATH" remote get-url origin 2>/dev/null || echo "")
fi

if [[ -n "$GITHUB_URL" ]]; then
  # Normalize URL
  if [[ "$GITHUB_URL" =~ ^https://github\.com/([^/]+)/([^/.]+)(\.git)?$ ]]; then
    GITHUB_OWNER="${BASH_REMATCH[1]}"
    GITHUB_REPO_NAME="${BASH_REMATCH[2]}"
    CLONE_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO_NAME}.git"
  elif [[ "$GITHUB_URL" =~ ^([^/]+)/([^/]+)$ ]]; then
    GITHUB_OWNER="${BASH_REMATCH[1]}"
    GITHUB_REPO_NAME="${BASH_REMATCH[2]}"
    CLONE_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO_NAME}.git"
  else
    die "Unrecognized URL format: $GITHUB_URL (expected https://github.com/org/repo.git or org/repo)"
  fi
fi

# Determine repo name
if [[ -z "$REPO_NAME" ]]; then
  if [[ -n "$GITHUB_REPO_NAME" ]]; then
    REPO_NAME="$GITHUB_REPO_NAME"
  elif [[ -n "$LOCAL_PATH" ]]; then
    REPO_NAME=$(basename "$LOCAL_PATH")
  else
    die "Cannot determine repo name. Use --name to specify."
  fi
fi

# Extract owner/repo from clone URL if not already set
if [[ -z "$GITHUB_OWNER" && -n "$CLONE_URL" ]]; then
  if [[ "$CLONE_URL" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    GITHUB_OWNER="${BASH_REMATCH[1]}"
    GITHUB_REPO_NAME="${BASH_REMATCH[2]}"
  fi
fi

echo "Onboarding repo: $REPO_NAME"
echo "  Clone URL: ${CLONE_URL:-<local>}"
echo "  Metarepo:  $METAREPO"

# --- Clone or link repository ---

TRUNK_DIR="$METAREPO/repos/$REPO_NAME/trunk"

if [[ -d "$TRUNK_DIR" ]]; then
  echo "  Trunk directory already exists: $TRUNK_DIR"
  echo "  Using existing clone."
elif [[ -n "$LOCAL_PATH" ]]; then
  echo "  Copying from local path: $LOCAL_PATH"
  mkdir -p "$(dirname "$TRUNK_DIR")"
  cp -r "$LOCAL_PATH" "$TRUNK_DIR"
else
  echo "  Cloning repository..."
  mkdir -p "$(dirname "$TRUNK_DIR")"
  git clone "$CLONE_URL" "$TRUNK_DIR" || die "Clone failed"
fi

# --- Initialize JJ ---

if [[ -d "$TRUNK_DIR/.jj" ]]; then
  echo "  JJ already initialized."
else
  echo "  Initializing JJ (colocated)..."
  (cd "$TRUNK_DIR" && jj git init --colocate) || die "JJ init failed"
fi

# --- Detect default branch ---

DEFAULT_BRANCH=""
if git -C "$TRUNK_DIR" symbolic-ref refs/remotes/origin/HEAD &>/dev/null; then
  DEFAULT_BRANCH=$(git -C "$TRUNK_DIR" symbolic-ref refs/remotes/origin/HEAD | sed 's|refs/remotes/origin/||')
else
  # Fallback: check for common branch names
  for branch in main master; do
    if git -C "$TRUNK_DIR" rev-parse --verify "refs/remotes/origin/$branch" &>/dev/null; then
      DEFAULT_BRANCH="$branch"
      break
    fi
  done
fi

if [[ -z "$DEFAULT_BRANCH" ]]; then
  echo "  WARNING: Could not detect default branch. Defaulting to 'main'."
  DEFAULT_BRANCH="main"
fi

echo "  Default branch: $DEFAULT_BRANCH"

# --- Set JJ trunk alias ---
# jj config set doesn't handle () in key names, so write directly to TOML config

REPO_CONFIG="$TRUNK_DIR/.jj/repo/config.toml"
if [[ -f "$REPO_CONFIG" ]] && grep -q 'trunk()' "$REPO_CONFIG"; then
  echo "  JJ trunk alias already set."
else
  mkdir -p "$(dirname "$REPO_CONFIG")"
  cat >> "$REPO_CONFIG" <<EOF

[revset-aliases]
"trunk()" = "${DEFAULT_BRANCH}@origin"
EOF
  echo "  Set JJ trunk alias: trunk() = ${DEFAULT_BRANCH}@origin"
fi

# Track the default branch bookmark
(cd "$TRUNK_DIR" && jj bookmark track "$DEFAULT_BRANCH" --remote=origin 2>/dev/null) \
  || echo "  WARNING: Could not track $DEFAULT_BRANCH bookmark"

# --- Create .repo.json ---

REPO_JSON="$METAREPO/repos/$REPO_NAME/.repo.json"
if [[ -f "$REPO_JSON" ]]; then
  echo "  .repo.json already exists."
else
  TODAY=$(date +%Y-%m-%d)
  jq -n \
    --arg name "$REPO_NAME" \
    --arg url "${CLONE_URL:-}" \
    --arg default_branch "$DEFAULT_BRANCH" \
    --arg github_owner "${GITHUB_OWNER:-}" \
    --arg github_repo "${GITHUB_REPO_NAME:-}" \
    --arg added "$TODAY" \
    '{
      name: $name,
      url: $url,
      default_branch: $default_branch,
      github_owner: $github_owner,
      github_repo: $github_repo,
      added: $added
    }' > "$REPO_JSON"
  echo "  Created .repo.json"
fi

# --- Create notes directory for trunk ---

NOTES_DIR="$METAREPO/notes/$REPO_NAME/trunk"
mkdir -p "$NOTES_DIR"

# --- Create trunk workspace.json ---

WORKSPACE_JSON="$NOTES_DIR/workspace.json"
if [[ -f "$WORKSPACE_JSON" ]]; then
  echo "  trunk workspace.json already exists."
else
  TODAY=$(date +%Y-%m-%d)
  jq -n \
    --arg repo "$REPO_NAME" \
    --arg name "trunk" \
    --arg type "trunk" \
    --arg purpose "Canonical workspace tracking $DEFAULT_BRANCH" \
    --arg owner "${USER:-unknown}" \
    --arg created "$TODAY" \
    '{
      repo: $repo,
      name: $name,
      type: $type,
      purpose: $purpose,
      owner: $owner,
      created: $created,
      retired: null,
      references: []
    }' > "$WORKSPACE_JSON"
  echo "  Created trunk workspace.json"
fi

# --- Create trunk README.md from template ---

README="$NOTES_DIR/README.md"
if [[ -f "$README" ]]; then
  echo "  trunk README.md already exists."
else
  TEMPLATE="$METAREPO/plugin/templates/workspace-readme.md"
  if [[ -f "$TEMPLATE" ]]; then
    sed \
      -e "s/{{workspace-name}}/trunk/g" \
      -e "s/{{repo-name}}/$REPO_NAME/g" \
      -e "s/{{owner}}/${USER:-unknown}/g" \
      -e "s/{{type}}/trunk/g" \
      -e "s/{{created-date}}/$(date +%Y-%m-%d)/g" \
      -e "s/{{jira-links}}/none/g" \
      "$TEMPLATE" > "$README"
    echo "  Created trunk README.md"
  else
    echo "  WARNING: Template not found at $TEMPLATE, skipping README."
  fi
fi

# --- Create symlinks in trunk workspace ---

SYMLINK_JSON="$TRUNK_DIR/.workspace.json"
SYMLINK_NOTES="$TRUNK_DIR/.notes"

# Compute relative path from trunk workspace to notes
REL_NOTES="../../../notes/$REPO_NAME/trunk"

if [[ ! -L "$SYMLINK_JSON" ]]; then
  ln -s "$REL_NOTES/workspace.json" "$SYMLINK_JSON"
  echo "  Created .workspace.json symlink"
fi

if [[ ! -L "$SYMLINK_NOTES" ]]; then
  ln -s "$REL_NOTES/" "$SYMLINK_NOTES"
  echo "  Created .notes symlink"
fi

# --- Add to .git/info/exclude ---

EXCLUDE_FILE="$TRUNK_DIR/.git/info/exclude"
mkdir -p "$(dirname "$EXCLUDE_FILE")"
touch "$EXCLUDE_FILE"

for pattern in ".workspace.json" ".notes"; do
  if ! grep -qxF "$pattern" "$EXCLUDE_FILE" 2>/dev/null; then
    echo "$pattern" >> "$EXCLUDE_FILE"
  fi
done
echo "  Updated .git/info/exclude"

# --- Done ---

echo ""
echo "Repository '$REPO_NAME' onboarded successfully!"
echo "  Trunk workspace: $TRUNK_DIR"
echo "  Notes:           $NOTES_DIR"
echo "  Config:          $REPO_JSON"
