---
description: "Add a reference (PR, Jira ticket) to the current workspace"
argument-hint: "<PR#|Jira-key|PR-URL>"
allowed-tools: ["Bash(jj:*)", "Bash(gh:*)", "Bash(jq:*)", "Read", "AskUserQuestion"]
---
Add a reference (PR, Jira ticket) to the current workspace.

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Determine the current workspace:
   - Infer from cwd: match `*/repos/<repo>/<workspace>*` to extract repo and workspace
   - Or use `.workspace.json` symlink if it exists in cwd
   - If unable to determine, ask the user
3. Read `<metarepo>/notes/<repo>/<workspace>/workspace.json` (or via `.workspace.json` symlink).
4. Read `<metarepo>/repos/<repo>/.repo.json` for GitHub owner/repo info.
5. Parse the user's input for the reference:
   - **PR**: `#1234`, `1234`, `PR #1234`, or a full GitHub PR URL
   - **Jira ticket**: `PROJ-1234`, `TEAM-123`, `WORK-456` (uppercase project key + dash + number)
6. For PR references:
   - Resolve full URL using .repo.json: `https://github.com/<owner>/<repo>/pull/<number>`
   - Get PR title: `gh pr view <number> --json title -q '.title' --repo <owner>/<repo>`
   - Capture JJ change ID: `jj log -r @ --no-graph -T change_id` (from workspace directory)
   - Capture branch: `jj log -r @ --no-graph -T 'bookmarks'`
   - Check for duplicates in workspace.json references
   - Append to references array using jq:
     ```
     jq --arg url "$URL" --argjson num $NUMBER --arg change_id "$CHANGE_ID" --arg branch "$BRANCH" --arg added "$(date +%Y-%m-%d)" \
       '.references += [{"type":"pr","number":$num,"url":$url,"jj_change_id":$change_id,"branch":$branch,"added":$added}]' \
       workspace.json > tmp && mv tmp workspace.json
     ```
7. For Jira references:
   - Check for duplicates
   - Append using jq:
     ```
     jq --arg key "$KEY" --arg added "$(date +%Y-%m-%d)" \
       '.references += [{"type":"jira","key":$key,"added":$added}]' \
       workspace.json > tmp && mv tmp workspace.json
     ```
8. Confirm what was added and show the updated references.

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- References are stored in `workspace.json` (the source of truth), not README.md.
- The `.workspace.json` symlink in the workspace directory points to the real file in `notes/`.
- Deduplicate: check existing references before adding.
- Handle `gh` failures gracefully.
