---
description: "Import an existing git checkout into the metarepo workspace system"
argument-hint: "<path-to-git-checkout>"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*:*)", "Bash(jj:*)", "Bash(gh:*)", "Bash(git:*)", "Read", "Glob", "AskUserQuestion"]
---
Import an existing git checkout into the metarepo workspace system.

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Validate the source path:
   - Expand `~` to `$HOME` in the provided path
   - Verify `.git` exists in the source directory
   - If `.git` is a file (not a directory), warn the user that the source is a git worktree — import may have unexpected results
   - Refuse if the source path is already inside `<metarepo>/repos/`
3. Preflight the source — run git commands to collect information:
   - Remote URL: `git -C <path> remote get-url origin` (fallback to first available remote)
   - Current branch: `git -C <path> branch --show-current`
   - All local branches: `git -C <path> branch --format='%(refname:short)'`
   - Dirty state: `git -C <path> status --porcelain`
   - Unpushed commits per branch: `git -C <path> log origin/<branch>..<branch> --oneline` for each branch
   - Stash list: `git -C <path> stash list` — if non-empty, warn that stashes will NOT be imported
4. Resolve repo mapping — parse the origin URL to determine `org/repo`, then check if `repos/<name>/.repo.json` exists:
   - If onboarded: verify the URL matches. If it doesn't match (fork scenario), warn the user.
   - If not onboarded: run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/workspaces/add-repo.sh <origin-url>` to onboard it first.
5. Ask the user via `AskUserQuestion` about import scope:
   - Current branch only
   - Select from branches (list them)
   - All local branches
   - Always skip the default branch (it maps to the existing `trunk` workspace).
6. For each branch to import, propose a workspace name:
   - Branch prefix mapping: `feature/*` → `epic-*`, `bugfix/*`/`hotfix/*` → `spike-*`, `pr-*` passthrough
   - Otherwise: kebab-case the branch name, type = `import`
   - Ask the user via `AskUserQuestion` to confirm or override each workspace name
   - Check for collisions against existing `repos/<repo>/` and `notes/<repo>/` directories
7. For each branch, run the import script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/workspaces/import-workspace.sh \
     <repo> <name> --branch <branch> --source <path> \
     --type <type> [--purpose "<purpose>"] [--dirty] [--local-commits]
   ```
   Pass `--dirty` only for the current branch workspace when the source has dirty state (staged + unstaged changes).
   Pass `--local-commits` when the branch has unpushed commits (i.e., `git log origin/<branch>..<branch>` is non-empty).
8. Run validation:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/workspaces/validate.sh --repo <repo>
   ```
9. Report a summary of what was imported and suggest next steps:
   - `/workspace:cd <repo>/<workspace>` to switch to an imported workspace
   - `/workspace:list` to see all workspaces

## Important

- The source checkout is **read-only** — never modify it. All data is read via `git` commands or file copies.
- The default branch (e.g., `main`, `master`) maps to the existing `trunk` workspace — never create a duplicate.
- In JJ, staged and unstaged changes collapse into a single working copy. Warn the user about this.
- Git stashes are **not** imported. Warn the user if stashes exist.
- Out of scope: move mode (deleting the source), batch import of multiple repos, non-GitHub remotes.
