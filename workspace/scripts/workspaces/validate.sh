#!/usr/bin/env bash
# validate.sh - Validate metarepo workspace integrity
#
# Checks:
#   1. All workspace.json files are valid JSON
#   2. All symlinks (.workspace.json, .notes) in live workspaces are valid
#   3. All live JJ workspaces have corresponding notes directories
#   4. Reports any inconsistencies
#
# Usage: validate.sh [--repo <repo>]

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

FILTER_REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) FILTER_REPO="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: validate.sh [--repo <repo>]"
      exit 0
      ;;
    *) die "Unknown argument: $1" ;;
  esac
done

# --- Resolve metarepo ---

METAREPO=$(resolve_metarepo)
[[ -d "$METAREPO" ]] || die "Metarepo directory not found: $METAREPO"

# --- Counters ---

ERRORS=0
WARNINGS=0
CHECKS=0

ok() {
  CHECKS=$((CHECKS + 1))
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  echo "  WARNING: $*"
}

err() {
  ERRORS=$((ERRORS + 1))
  echo "  ERROR:   $*"
}

# --- Discover repos ---

declare -a REPOS=()

for repo_json in "$METAREPO"/repos/*/.repo.json; do
  [[ -f "$repo_json" ]] || continue
  repo_dir=$(dirname "$repo_json")
  repo_name=$(basename "$repo_dir")
  if [[ -n "$FILTER_REPO" && "$repo_name" != "$FILTER_REPO" ]]; then
    continue
  fi
  REPOS+=("$repo_name")
done

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "No repos found to validate."
  exit 0
fi

echo "Validating metarepo: $METAREPO"
echo ""

for repo in "${REPOS[@]}"; do
  echo "--- $repo ---"

  # 1. Validate .repo.json
  REPO_JSON="$METAREPO/repos/$repo/.repo.json"
  if jq . "$REPO_JSON" > /dev/null 2>&1; then
    ok
  else
    err ".repo.json is invalid JSON: $REPO_JSON"
  fi

  # 2. Validate all workspace.json files
  for ws_json in "$METAREPO"/notes/"$repo"/*/workspace.json; do
    [[ -f "$ws_json" ]] || continue
    ws_dir=$(dirname "$ws_json")
    ws_name=$(basename "$ws_dir")

    if jq . "$ws_json" > /dev/null 2>&1; then
      ok

      # Validate required fields
      for field in repo name type purpose owner created; do
        val=$(jq -r ".$field // empty" "$ws_json")
        if [[ -z "$val" ]]; then
          warn "$ws_name/workspace.json missing field: $field"
        fi
      done
    else
      err "$ws_name/workspace.json is invalid JSON: $ws_json"
    fi
  done

  # 3. Validate symlinks in live workspaces
  for ws_dir in "$METAREPO"/repos/"$repo"/*/; do
    [[ -d "$ws_dir" ]] || continue
    ws_name=$(basename "$ws_dir")

    # Skip .repo.json and non-directories
    [[ -d "$ws_dir" ]] || continue

    # Check .workspace.json symlink
    symlink="$ws_dir/.workspace.json"
    if [[ -L "$symlink" ]]; then
      if [[ -e "$symlink" ]]; then
        ok
      else
        err "$repo/$ws_name: .workspace.json symlink is broken (target: $(readlink "$symlink"))"
      fi
    else
      warn "$repo/$ws_name: missing .workspace.json symlink"
    fi

    # Check .notes symlink
    symlink="$ws_dir/.notes"
    if [[ -L "$symlink" ]]; then
      if [[ -e "$symlink" ]]; then
        ok
      else
        err "$repo/$ws_name: .notes symlink is broken (target: $(readlink "$symlink"))"
      fi
    else
      warn "$repo/$ws_name: missing .notes symlink"
    fi
  done

  # 4. Check JJ workspaces have corresponding notes
  TRUNK_DIR="$METAREPO/repos/$repo/trunk"
  if [[ -d "$TRUNK_DIR/.jj" ]]; then
    while IFS= read -r line; do
      # Parse workspace name from jj workspace list (format: "name: changeid commitid ...")
      ws_id=$(echo "$line" | sed -n 's/^\([^:]*\):.*/\1/p' | tr -d '* ')
      if [[ -n "$ws_id" ]]; then
        notes_dir="$METAREPO/notes/$repo/$ws_id"
        if [[ -d "$notes_dir" ]]; then
          ok
        else
          warn "JJ workspace '$ws_id' has no notes directory (expected: $notes_dir)"
        fi
      fi
    done < <(cd "$TRUNK_DIR" && jj workspace list 2>/dev/null || true)
  fi

  # 5. Check notes directories have corresponding live workspaces
  for notes_dir in "$METAREPO"/notes/"$repo"/*/; do
    [[ -d "$notes_dir" ]] || continue
    ws_name=$(basename "$notes_dir")
    ws_dir="$METAREPO/repos/$repo/$ws_name"
    if [[ -d "$ws_dir" ]]; then
      ok
    else
      warn "Notes exist for '$ws_name' but no live workspace directory"
    fi
  done

  echo ""
done

# --- Summary ---

echo "=== Validation Summary ==="
echo "  Checks passed: $CHECKS"
echo "  Warnings:      $WARNINGS"
echo "  Errors:        $ERRORS"

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo "FAILED: $ERRORS error(s) found."
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo ""
  echo "PASSED with $WARNINGS warning(s)."
  exit 0
else
  echo ""
  echo "ALL CHECKS PASSED."
  exit 0
fi
