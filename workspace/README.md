# workspace plugin

A Claude Code plugin for managing JJ workspaces across multiple git repositories. Onboard repos, create typed workspaces, track notes in git, and auto-capture PR/Jira references as you work.

## Layout

```
plugin/
├── .claude-plugin/plugin.json   # Plugin manifest
├── commands/                    # Slash commands (Claude skills)
├── hooks/                       # Lifecycle hooks + scripts
├── scripts/workspaces/          # Shell scripts backing the commands
├── templates/                   # Workspace README template
└── docs/                        # Additional guides (statusline, etc.)
```

## Commands

All commands are invoked as `/workspace:<name>` inside Claude Code.

| Command | Args | Description |
|---------|------|-------------|
| `add-repo` | `<org/repo>` or `<github-url>` | Onboard a new repository into the metarepo |
| `new` | `[<repo>] <name> [--purpose <text>]` | Create a workspace (`epic-*`, `spike-*`, `pr-*`) |
| `list` | `[--repo <repo>]` | List all workspaces across all onboarded repos |
| `status` | `[<repo>/]<workspace>` | Show detailed workspace status |
| `cd` | `[<repo>/]<workspace>` | Switch to a workspace directory (zmx respawn) |
| `open` | `[<repo>/]<workspace>` | Open a workspace in VS Code with notes sidebar |
| `sync` | `[<repo>/]<workspace>` | Fetch and rebase onto trunk |
| `notes` | `[<repo>/]<workspace>` | Show or manage workspace notes |
| `ref` | `<PR#\|Jira-key\|PR-URL>` | Add a reference to the current workspace |
| `refs` | `[--type pr\|jira] [--repo <repo>]` | Search references across all workspaces |
| `import` | `<path-to-git-checkout>` | Import an existing git checkout into the workspace system |
| `retire` | `[<repo>/]<workspace>` | Retire a workspace (preserves notes) |

## Hooks

The plugin registers three lifecycle hooks that run automatically:

| Hook | Trigger | What it does |
|------|---------|--------------|
| **capture-pr** | After any Bash command | Detects GitHub PR URLs in output and records them in `workspace.json` |
| **capture-jira** | After any Bash command | Detects Jira ticket patterns (e.g. `PROJ-123`) in output and records them |
| **workspace-boundary** | Before file edits/writes | Warns when editing files outside the current workspace |
| **session-context** | First prompt of a session | Injects workspace metadata and README into the initial prompt |

## Concepts

### Repos

Repositories are onboarded via `/workspace:add-repo`. Each gets:
- A clone at `repos/<name>/trunk/` (gitignored)
- A `.repo.json` with GitHub metadata
- A notes directory at `notes/<name>/trunk/`

### Workspaces

Workspaces are JJ workspaces within a repo. Names must follow a type convention:

| Prefix | Purpose |
|--------|---------|
| `trunk` | Canonical workspace, mirrors default branch |
| `epic-*` | Multi-PR feature work |
| `spike-*` | Experiments and investigations |
| `pr-*` | Single PR review or fix |

Each workspace has:
- **`workspace.json`** in `notes/<repo>/<workspace>/` — source of truth (type, purpose, owner, references)
- **`README.md`** in `notes/<repo>/<workspace>/` — goals, status, handoff checklist
- **Symlinks** in the live workspace (`.workspace.json`, `.notes`) pointing to the notes directory

### References

PRs and Jira tickets are tracked in `workspace.json` under the `references` array. They're captured automatically by hooks or added manually via `/workspace:ref`.

## Prerequisites

- **jj** — [Jujutsu](https://martinvonz.github.io/jj/) for workspace and version control
- **jq** — JSON processing
- **gh** — GitHub CLI (for PR info and repo operations)
- **zmx** — Terminal multiplexer (required for `/workspace:cd` respawn)

## Setup

Run the setup script from the metarepo root:

```bash
./setup.sh
```

This will:
1. Check that dependencies are installed
2. Create `~/.claude/workspace-config.json` pointing to the metarepo
3. Add a Claude wrapper function to your shell RC for zmx session support
4. Verify the plugin is enabled in `~/.claude/settings.json`

### Development mode

To develop the plugin locally with live reloading:

```bash
./dev.sh
```

This symlinks the plugin cache to your local source so changes take effect on Claude restart without publishing.

### Publishing

To push plugin changes to the marketplace:

```bash
./publish.sh
```

This syncs files, runs a proprietary-content scrub, and commits to the marketplace repo.

## Configuration

The metarepo location is stored in `~/.claude/workspace-config.json`:

```json
{ "metarepo": "~/Projects/metarepo" }
```

All scripts resolve paths from this file.

## Additional Docs

- [Statusline setup](docs/statusline.md) — Display your active workspace in the Claude Code statusline
