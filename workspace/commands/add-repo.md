---
description: "Onboard a new repository into the metarepo"
argument-hint: "<org/repo> or <github-url>"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*:*)", "Bash(gh:*)", "Bash(git:*)", "Read", "Glob", "AskUserQuestion"]
---
Onboard a new repository into the universal metarepo.

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Parse the user's input for the repository source:
   - Full GitHub URL: `https://github.com/org/repo`
   - Shorthand: `org/repo` (e.g., `acme/my-project`)
   - Just an org name: use `gh repo list <org> --limit 20 --json name,url` to discover repos and let user pick
3. Check if the repo is already onboarded:
   - Look for `<metarepo>/repos/<name>/.repo.json`
   - If found, inform the user and suggest `/workspace:new` instead
4. Run the add-repo script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/workspaces/add-repo.sh <url-or-org/repo>
   ```
   The script handles: cloning, JJ init, .repo.json, trunk workspace.json, symlinks, .git/info/exclude.
5. Commit the new notes to the metarepo:
   ```
   cd <metarepo> && git add notes/<repo>/ && git commit -m "Onboard <repo> repository"
   ```
6. Report success and suggest next steps:
   - `/workspace:new <repo> <name>` to create first workspace
   - `/workspace:list` to see all workspaces

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- This clones a potentially large repository. Warn the user it may take a while.
- Repos are cloned to `<metarepo>/repos/<name>/trunk/` (gitignored).
- Notes/metadata go to `<metarepo>/notes/<name>/trunk/` (git-tracked).
- Handle errors: auth failures, non-existent repos, network issues.
- If `gh` is not authenticated, suggest `gh auth login`.
