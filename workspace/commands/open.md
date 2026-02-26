---
description: "Open a workspace in VS Code with notes sidebar"
argument-hint: "[<repo>/]<workspace>"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*:*)", "Bash(code:*)", "Read", "Glob", "AskUserQuestion"]
---
Open a workspace in VS Code with notes sidebar.

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Determine which workspace to open:
   - If `<repo>/<workspace>` specified, use it
   - If just `<workspace>`, search across repos
   - If no argument, infer from cwd
   - If unable to determine, list workspaces and ask
3. Verify workspace exists at `<metarepo>/repos/<repo>/<workspace>/`.
4. Run the open script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/workspaces/open-workspace.sh <repo> <workspace>
   ```
5. Report what was opened.

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- Workspaces live at `<metarepo>/repos/<repo>/<workspace>/`.
- Notes live at `<metarepo>/notes/<repo>/<workspace>/`.
- Requires VS Code CLI (`code`) in PATH.
- If `code` is not available: VS Code > Cmd+Shift+P > "Shell Command: Install code command in PATH".
