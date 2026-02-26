#!/usr/bin/env bash
# list-workspaces.sh - List all workspaces across repos
#
# Usage: list-workspaces.sh [--json] [--repo <repo>]

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

# --- Parse arguments ---

OUTPUT_JSON=false
FILTER_REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) OUTPUT_JSON=true; shift ;;
    --repo) FILTER_REPO="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: list-workspaces.sh [--json] [--repo <repo>]"
      exit 0
      ;;
    *) die "Unknown argument: $1" ;;
  esac
done

# --- Resolve metarepo ---

METAREPO=$(resolve_metarepo)
[[ -d "$METAREPO" ]] || die "Metarepo directory not found: $METAREPO"

# --- Discover repos ---

declare -a REPOS=()

for repo_json in "$METAREPO"/repos/*/.repo.json; do
  [[ -f "$repo_json" ]] || continue
  repo_name=$(jq -r '.name' "$repo_json")
  if [[ -n "$FILTER_REPO" && "$repo_name" != "$FILTER_REPO" ]]; then
    continue
  fi
  REPOS+=("$repo_name")
done

if [[ ${#REPOS[@]} -eq 0 ]]; then
  if [[ -n "$FILTER_REPO" ]]; then
    die "Repo not found: $FILTER_REPO"
  fi
  echo "No repos onboarded yet. Run add-repo.sh to get started."
  exit 0
fi

# --- Collect workspace data ---

# JSON output accumulator
JSON_OUTPUT="[]"

for repo in "${REPOS[@]}"; do
  TRUNK_DIR="$METAREPO/repos/$repo/trunk"

  # Get active JJ workspaces
  declare -A JJ_WORKSPACES=()
  if [[ -d "$TRUNK_DIR/.jj" ]]; then
    while IFS= read -r line; do
      # jj workspace list output: "name: changeid commitid (stuff)"
      ws_id=$(echo "$line" | sed -n 's/^\([^:]*\):.*/\1/p' | tr -d '* ')
      if [[ -n "$ws_id" ]]; then
        JJ_WORKSPACES["$ws_id"]=1
      fi
    done < <(cd "$TRUNK_DIR" && jj workspace list 2>/dev/null || true)
  fi

  # Scan notes directories for workspace.json files
  declare -a WS_ENTRIES=()

  for ws_json in "$METAREPO"/notes/"$repo"/*/workspace.json; do
    [[ -f "$ws_json" ]] || continue

    ws_name=$(jq -r '.name' "$ws_json")
    ws_type=$(jq -r '.type // "unknown"' "$ws_json")
    ws_purpose=$(jq -r '.purpose // ""' "$ws_json")
    ws_owner=$(jq -r '.owner // ""' "$ws_json")
    ws_created=$(jq -r '.created // ""' "$ws_json")
    ws_retired=$(jq -r '.retired // empty' "$ws_json" 2>/dev/null || echo "")

    # Check if JJ workspace exists
    jj_active="no"
    if [[ -n "${JJ_WORKSPACES[$ws_name]+x}" ]]; then
      jj_active="yes"
    fi

    # Check if live directory exists
    live_dir="$METAREPO/repos/$repo/$ws_name"
    has_dir="no"
    if [[ -d "$live_dir" ]]; then
      has_dir="yes"
    fi

    # Status
    status="active"
    if [[ -n "$ws_retired" && "$ws_retired" != "null" ]]; then
      status="retired"
    fi

    if $OUTPUT_JSON; then
      entry=$(jq -n \
        --arg repo "$repo" \
        --arg name "$ws_name" \
        --arg type "$ws_type" \
        --arg purpose "$ws_purpose" \
        --arg owner "$ws_owner" \
        --arg created "$ws_created" \
        --arg retired "$ws_retired" \
        --arg status "$status" \
        --arg jj_active "$jj_active" \
        --arg has_dir "$has_dir" \
        '{
          repo: $repo,
          name: $name,
          type: $type,
          purpose: $purpose,
          owner: $owner,
          created: $created,
          retired: (if $retired == "" then null else $retired end),
          status: $status,
          jj_active: ($jj_active == "yes"),
          has_directory: ($has_dir == "yes")
        }')
      JSON_OUTPUT=$(echo "$JSON_OUTPUT" | jq --argjson entry "$entry" '. + [$entry]')
    else
      WS_ENTRIES+=("$ws_name|$ws_type|$ws_purpose|$ws_owner|$ws_created|$status|$jj_active")
    fi
  done

  if ! $OUTPUT_JSON; then
    if [[ ${#WS_ENTRIES[@]} -gt 0 ]]; then
      echo "=== $repo ==="
      printf "  %-25s %-8s %-45s %-10s %-12s %-8s %-4s\n" "NAME" "TYPE" "PURPOSE" "OWNER" "CREATED" "STATUS" "JJ"
      printf "  %-25s %-8s %-45s %-10s %-12s %-8s %-4s\n" "----" "----" "-------" "-----" "-------" "------" "--"
      for entry in "${WS_ENTRIES[@]}"; do
        IFS='|' read -r name type purpose owner created status jj_active <<< "$entry"
        # Truncate purpose if too long
        if [[ ${#purpose} -gt 45 ]]; then
          purpose="${purpose:0:42}..."
        fi
        printf "  %-25s %-8s %-45s %-10s %-12s %-8s %-4s\n" "$name" "$type" "$purpose" "$owner" "$created" "$status" "$jj_active"
      done
      echo ""
    fi
  fi

  # Clear associative arrays for next repo
  unset JJ_WORKSPACES
  declare -A JJ_WORKSPACES=()
  unset WS_ENTRIES
done

if $OUTPUT_JSON; then
  echo "$JSON_OUTPUT" | jq .
fi
