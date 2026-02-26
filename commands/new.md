---
description: "Create a new workspace for any onboarded repository"
argument-hint: "[<repo>] <name> [--purpose <text>]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*:*)", "Bash(jj:*)", "Bash(gh:*)", "Read", "Glob", "AskUserQuestion", "Skill"]
---
Create a new workspace for any onboarded repository.

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Parse the user's request for:
   - **Repo name** — which onboarded repository (e.g., `my-repo`)
   - **Workspace name** — must match: `epic-<kebab>`, `spike-<kebab>`, or `pr-<number>`
   - **Purpose** (optional) — short description of the workspace's goal
   - **Owner** (optional) — defaults to the user
3. Discover available repos by scanning `<metarepo>/repos/` for directories with `.repo.json`.
4. If the repo is ambiguous or missing:
   - List available repos and ask the user via `AskUserQuestion`
   - If no repos are onboarded, suggest `/workspace:add-repo`
5. If the repo is not onboarded, suggest: `/workspace:add-repo <org/repo>`
6. Validate the workspace name (must match `epic-*`, `spike-*`, or `pr-*` pattern).
7. Run the creation script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/workspaces/new-workspace.sh <repo> <name> --type <type> --purpose "<purpose>" --owner "<owner>"
   ```
8. Show the output and the workspace path: `<metarepo>/repos/<repo>/<name>/`
9. Ask the user what to do next using `AskUserQuestion`:
   - **Stay here** — don't cd, remain in the current directory
   - **cd (keep context)** — invoke `/workspace:cd <repo>/<name>` to switch while preserving the current conversation
   - **cd (fresh session)** — invoke `/workspace:cd <repo>/<name>` to switch with a fresh Claude session (zmx respawn)
   If the user picks "cd (keep context)" or "cd (fresh session)", invoke the `workspace:cd` skill with the appropriate workspace path. For "cd (fresh session)", pass `--fresh` as an additional argument.

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- Workspace directories live under `<metarepo>/repos/<repo>/<name>/`.
- Notes live under `<metarepo>/notes/<repo>/<name>/` (git-tracked).
- The script creates JJ workspace, workspace.json, README.md, and symlinks.
- For `pr-*` workspaces, the script auto-fetches PR branch info via `gh pr view`.
- Infer type from name prefix: `epic-*` → epic, `spike-*` → spike, `pr-*` → pr.
