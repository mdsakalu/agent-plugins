# Statusline Setup

A Claude Code statusline script that displays your active metarepo workspace with type-aware icons and colors.

```
🔀 my-app/pr-42│ 🤖 Opus 4.6 📜12%│ ...
```

## Workspace Display

The workspace segment shows `<repo>/<workspace>` with an icon and color based on the workspace type:

| Prefix | Icon | Color | Example |
|--------|------|-------|---------|
| `trunk` | 🌳 | Cyan | `my-app/trunk` |
| `pr-*` | 🔀 | Blue | `my-app/pr-42` |
| `epic-*` | 🚀 | Green | `my-app/epic-auth-refactor` |
| `spike-*` | 🧪 | Magenta | `my-app/spike-caching` |
| metarepo root | 📁 | Cyan | `metarepo` |

## Prerequisites

- **jq** — for parsing the JSON input Claude Code sends to the statusline

## Installation

### 1. Create the statusline script

Save the script to `~/.claude/statusline-jj-workspace.sh` and make it executable. The script receives a JSON blob on stdin from Claude Code and writes the formatted statusline to stdout via `printf "%b"`.

### 2. Configure the metarepo root

Edit the script and set your metarepo path:

```bash
metarepo_root="/path/to/your/metarepo"
```

### 3. Enable in Claude Code settings

Add the `statusLine` key to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-jj-workspace.sh"
  }
}
```

Restart Claude Code to see the statusline.

## How Workspace Detection Works

The script compares `workspace.current_dir` from the JSON input against your metarepo root:

1. **Exact match** on metarepo root → `metarepo`
2. **Inside `repos/<repo>/<workspace>/...`** or **`notes/<repo>/<workspace>/...`** → `<repo>/<workspace>`
3. **Inside a top-level dir** (`scripts/`, `plugin/`, `templates/`) → `metarepo`
4. **Repo-level only** (`repos/my-app/` with no workspace) → `<repo>`

The workspace type prefix (the part after the last `/`) drives icon and color selection.

## Respawn Support

The script writes `session_id` and `transcript_path` to `/tmp/claude-session-$PPID`, which `respawn-claude.sh` uses to enable `workspace:cd` to switch workspaces within a running session.

## Customization

### Adding a new workspace type

Add an `elif` block in the icon/color section of the script:

```bash
elif [[ "$ws_suffix" == fix-* ]]; then
  ws_color="${RED}"
  ws_icon="🔧"
```

### Input format

Claude Code pipes a JSON object on every render. The fields used for workspace detection:

```json
{
  "session_id": "abc-123",
  "transcript_path": "/path/to/transcript",
  "workspace": {
    "current_dir": "/path/to/metarepo/repos/my-app/pr-42"
  }
}
```
