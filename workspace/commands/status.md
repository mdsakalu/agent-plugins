---
description: "Show detailed status for a workspace"
argument-hint: "[<repo>/]<workspace>"
allowed-tools: ["Bash(jj:*)", "Bash(gh:*)", "Read", "Glob", "AskUserQuestion"]
---
Show detailed status for a workspace.

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Determine which workspace to report on:
   - If the user specified `<repo>/<workspace>`, use it directly
   - If just `<workspace>`, search across all repos
   - If no argument, try to infer from cwd: check if cwd matches `*/repos/<repo>/<workspace>*` and extract both
   - If unable to determine, list available workspaces and ask
3. Read workspace metadata from `<metarepo>/notes/<repo>/<workspace>/workspace.json`:
   - Show: repo, name, type, purpose, owner, created date, retired status
4. Show all references from workspace.json:
   - For PRs: show number, URL, JJ change_id, branch
   - Optionally get live PR status: `gh pr view <number> --json state,title --repo <github_owner>/<github_repo>`
   - For Jira tickets: show ticket key
5. Read notes summary from `<metarepo>/notes/<repo>/<workspace>/README.md` (first ~10 lines).
6. List other files in the notes directory.
7. If the workspace directory exists at `<metarepo>/repos/<repo>/<workspace>/`, run from it:
   ```
   jj log --limit 5
   jj status
   ```
8. Read `.repo.json` from `<metarepo>/repos/<repo>/` for GitHub owner/repo info (used for PR lookups).
9. Present all information in a well-organized format.

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- Workspace metadata is in `notes/<repo>/<workspace>/workspace.json` (source of truth).
- Workspace code lives at `repos/<repo>/<workspace>/`.
- Handle missing workspaces gracefully — if the directory is gone but notes exist, show available metadata.
- If jj commands fail, report the error but still show metadata from workspace.json.
- Read `.repo.json` for GitHub owner/repo to use with `gh pr view`.
