---
description: "Retire a workspace (mark as retired, forget JJ workspace, preserve notes)"
argument-hint: "[<repo>/]<workspace>"
allowed-tools: ["Bash(jj:*)", "Bash(jq:*)", "Bash(rm:*)", "Read", "Glob", "AskUserQuestion"]
---
Retire a workspace (mark as retired, forget JJ workspace, preserve notes).

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Determine which workspace to retire:
   - If `<repo>/<workspace>` specified, use it
   - If just `<workspace>`, search across repos
   - If no argument, infer from cwd
   - If unable to determine, list workspaces and ask
3. Read `<metarepo>/notes/<repo>/<workspace>/workspace.json` to get current state.
4. **Confirm with the user before proceeding.** Show:
   - Workspace name, repo, type, purpose
   - What will happen: `retired` date set in workspace.json, JJ workspace forgotten
   - Notes preserved at `<metarepo>/notes/<repo>/<workspace>/`
   - Ask explicitly: "Proceed with retiring `<repo>/<workspace>`?"
5. After confirmation:
   a. Update workspace.json — set `"retired": "<today's date>"` using jq:
      ```
      jq --arg date "$(date +%Y-%m-%d)" '.retired = $date' workspace.json > tmp && mv tmp workspace.json
      ```
   b. Forget the JJ workspace from the trunk:
      ```
      cd <metarepo>/repos/<repo>/trunk && jj workspace forget <workspace-name>
      ```
   c. Ask the user if they also want to delete the workspace directory:
      - If yes: remove `<metarepo>/repos/<repo>/<workspace>/`
      - If no: leave it (stale but harmless)
      - Either way, notes survive at `<metarepo>/notes/<repo>/<workspace>/`
6. Report what was done.

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- ALWAYS confirm with the user before making changes.
- Never delete the notes directory — notes survive retirement.
- The `trunk` workspace should NEVER be retired. Refuse if the user tries.
- Handle cases where the workspace directory is already gone.
- workspace.json is the source of truth, located at `notes/<repo>/<workspace>/workspace.json`.
