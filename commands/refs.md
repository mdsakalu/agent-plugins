---
description: "Search and display references across all workspaces"
argument-hint: "[--type pr|jira] [--repo <repo>]"
allowed-tools: ["Bash(gh:*)", "Read", "Glob"]
---
Search and display references across all workspaces (PRs, Jira tickets).

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Scan all workspace metadata files: `<metarepo>/notes/**/workspace.json`
   - This covers all repos and all workspaces (active + retired)
3. For each workspace.json, extract the `references` array.
4. Build a combined list with workspace context: repo name, workspace name, active/retired status.
5. If the user requested filtering:
   - By type: `--type pr` or `--type jira`
   - By repo: `--repo my-repo`
   - By status: active-only or retired-only (check `retired` field in workspace.json)
   - By search term: filter refs matching a keyword
6. Optionally enrich PR references with live status:
   - For each repo, read `.repo.json` for GitHub owner/repo
   - Run: `gh pr view <number> --json state,title --repo <owner>/<repo>` (limit to 10 PRs)
   - Show state: OPEN, CLOSED, MERGED
7. Format output grouped by workspace:
   ```
   my-repo/epic-auth-refactor (active)
     - PR #42: Add user authentication [MERGED]
     - Jira PROJ-100

   my-repo/pr-99 (retired)
     - PR #99: Fix pagination bug [CLOSED]
   ```
8. Show summary: total references, breakdown by type, breakdown by repo.

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- References are in `notes/<repo>/<workspace>/workspace.json` (source of truth).
- Scan all repos and workspaces, not just the current one.
- Limit `gh pr view` calls to avoid rate limiting (max 10 enrichment calls).
- Handle cases where workspace.json exists but has no references.
