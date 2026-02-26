---
description: "Sync a workspace with upstream (fetch and rebase onto trunk)"
argument-hint: "[<repo>/]<workspace>"
allowed-tools: ["Bash(jj:*)", "Read", "Glob", "AskUserQuestion"]
---
Sync a workspace with upstream (fetch and rebase onto trunk).

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Determine which workspace to sync:
   - If `<repo>/<workspace>` specified, use `<metarepo>/repos/<repo>/<workspace>/`
   - If just `<workspace>`, search across repos
   - If no argument, infer from cwd (match `*/repos/<repo>/<workspace>*`)
   - If unable to determine, list workspaces and ask
3. Verify the workspace directory exists and has JJ initialized.
4. Run from the workspace directory:
   ```
   jj git fetch
   ```
5. Rebase onto trunk using the repo's trunk alias:
   ```
   jj rebase -d trunk()
   ```
   If `trunk()` fails, fall back to reading default_branch from `<metarepo>/repos/<repo>/.repo.json` and use `<default_branch>@origin`.
6. Check for conflicts in the rebase output. If conflicts:
   - Report them clearly
   - Suggest `jj status` and `jj diff` to inspect
   - Suggest manual conflict resolution
7. Show the result:
   ```
   jj log --limit 5
   ```
8. Report success or issues.

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- Workspaces live at `<metarepo>/repos/<repo>/<workspace>/`.
- Use `trunk()` revset alias (set during add-repo) for the rebase destination.
- JJ handles uncommitted changes transparently during rebase.
- Conflicts are reported but don't stop the operation.
