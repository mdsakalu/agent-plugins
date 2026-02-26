---
description: "Switch to a workspace directory (with zmx respawn support)"
argument-hint: "[<repo>/]<workspace>"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*:*)", "Bash(jj:*)", "Read", "Glob", "AskUserQuestion"]
---
Switch to a workspace directory (with zmx respawn support).

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Parse the user's input. Accept:
   - `<repo>/<workspace>` — explicit: e.g., `my-repo/epic-foo`
   - `<workspace>` — search all repos for a match; if ambiguous, ask user
   - Partial/fuzzy name — search for matches and present options
   - `--fresh` flag — start a fresh Claude session instead of resuming context
3. Scan `<metarepo>/repos/*/` directories to discover repos. For each repo, check if a matching workspace directory exists under `repos/<repo>/<workspace>/`.
4. If no exact match found:
   - Search across all repos for partial matches
   - If multiple matches, present options via `AskUserQuestion`
   - If no matches, suggest `/workspace:new` or `/workspace:list`
5. Build the target path: `<metarepo>/repos/<repo>/<workspace>/`
6. Determine the switch method:
   - **If `ZMX_SESSION` env var exists** (inside zmx): Run the respawn script:
     ```
     bash ${CLAUDE_PLUGIN_ROOT}/scripts/workspaces/respawn-claude.sh <workspace-path> $PPID [--fresh]
     ```
     Pass `--fresh` if the user requested a fresh session.
     Warn the user that Claude will restart. If `--fresh`, note it will be a brand new session. Otherwise, note the session will resume.
   - **If NOT in zmx**: Show the workspace path and instruct the user to:
     1. Exit Claude or open a new session in that directory
     2. Run `cd <workspace-path>` in their terminal
     Warn that Claude cannot change its working directory mid-session.
7. Show the workspace path for reference.

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- Workspaces live at `<metarepo>/repos/<repo>/<workspace>/`.
- Handle ambiguous names gracefully — if a workspace name exists in multiple repos, ask which one.
- The respawn script requires zmx. Check for `ZMX_SESSION` env var before attempting respawn.
- `$PPID` is Claude's PID needed by the respawn script.
- Never run the respawn script outside of zmx.
