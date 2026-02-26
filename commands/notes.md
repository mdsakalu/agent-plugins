---
description: "Show or manage workspace notes"
argument-hint: "[<repo>/]<workspace>"
allowed-tools: ["Bash(~/Applications/marktext.app/Contents/MacOS/marktext:*)", "Read", "Edit", "Write", "Glob", "AskUserQuestion"]
---
Show or manage workspace notes.

Resolve the metarepo path by reading `~/.claude/workspace-config.json` and expanding `~` to `$HOME`.

The user's request: $ARGUMENTS

## Steps

1. Read `~/.claude/workspace-config.json` to get the metarepo path. Expand `~` to `$HOME`.
2. Determine which workspace's notes to show:
   - If `<repo>/<workspace>` specified, use it
   - If just `<workspace>`, search across repos
   - If no argument, infer from cwd (match `*/repos/<repo>/<workspace>*`)
   - If unable to determine, list workspaces and ask
3. Locate the notes directory at `<metarepo>/notes/<repo>/<workspace>/`.
4. If the notes directory exists:
   - Read and display `README.md` in full
   - Read and display `workspace.json` (references, metadata)
   - List all other files in the notes directory with sizes and modification dates
   - If the user asked about a specific file, read and display it
5. Open the notes directory in MarkText:
   ```
   ~/Applications/marktext.app/Contents/MacOS/marktext <notes-dir>/
   ```
   Run this in the background (append `&` and `disown`) so it doesn't block.
6. If the notes directory does not exist:
   - Inform the user
   - Offer to create it with README.md from `${CLAUDE_PLUGIN_ROOT}/templates/workspace-readme.md`
7. If the user asks to edit notes:
   - Edit the requested file using the Edit tool
   - Or create a new file in the notes directory
8. Notes are also accessible via the `.notes` symlink inside the workspace directory.

## Important

- Always resolve metarepo from `~/.claude/workspace-config.json`, never hardcode paths.
- Notes are git-tracked at `<metarepo>/notes/<repo>/<workspace>/`.
- Notes persist even after workspace retirement — they are the historical record.
- The `.notes` symlink in each workspace points to the notes directory.
- workspace.json in the notes directory is the source of truth for metadata and references.
