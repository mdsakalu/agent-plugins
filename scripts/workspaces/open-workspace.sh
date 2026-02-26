#!/usr/bin/env bash
# open-workspace.sh - Open a workspace in VS Code with notes sidebar
#
# Usage: open-workspace.sh <repo> <workspace>

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
  echo "Usage: open-workspace.sh <repo> <workspace>"
  exit 1
}

# --- Parse arguments ---

REPO=""
WS_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
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

# --- Validate paths ---

WS_DIR="$METAREPO/repos/$REPO/$WS_NAME"
NOTES_DIR="$METAREPO/notes/$REPO/$WS_NAME"

[[ -d "$WS_DIR" ]] || die "Workspace directory not found: $WS_DIR"
[[ -d "$NOTES_DIR" ]] || die "Notes directory not found: $NOTES_DIR"

# --- Open in VS Code ---

echo "Opening workspace: $REPO/$WS_NAME"
echo "  Code:  $WS_DIR"
echo "  Notes: $NOTES_DIR"

# Open the workspace directory, then add the notes folder
code "$WS_DIR" && code --add "$NOTES_DIR"

echo "Done."
