---
description: "List all workspaces across all onboarded repositories"
argument-hint: "[--repo <repo>]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*:*)", "Read", "Glob"]
---
List all workspaces across all onboarded repositories.

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Run the list script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/workspaces/list-workspaces.sh
   ```
3. If the user specified a repo filter, add `--repo <repo>`:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/workspaces/list-workspaces.sh --repo <repo>
   ```
4. Format the output as a clean grouped listing:
   - Group by repo
   - For each workspace show: name, type, purpose, owner, active/retired, reference count
5. If filtering requested (e.g., "active only", "spike", specific repo), apply filters.
6. Show a summary count at the end (e.g., "3 repos, 12 active, 4 retired").

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- The list script scans `<metarepo>/repos/` for `.repo.json` files (discovers repos) and `<metarepo>/notes/<repo>/*/workspace.json` for workspace metadata.
- Retired workspaces may have notes but no live JJ workspace directory.
- The trunk workspace is special — it mirrors the default branch.
