---
description: "Set up the workspace plugin (dependencies, config, zmx wrapper, statusline)"
allowed-tools: ["Bash(command:*)", "Bash(ls:*)", "Bash(cat:*)", "Bash(ln:*)", "Bash(mkdir:*)", "Bash(rm:*)", "Bash(chmod:*)", "Bash(grep:*)", "Bash(jq:*)", "Bash(cp:*)", "Read", "Write", "Edit", "Glob", "AskUserQuestion"]
---
Set up the workspace plugin — walk the user through dependencies, configuration, and optional features.

This is an interactive onboarding wizard. Use `AskUserQuestion` for every decision point. Explain **why** each step matters before doing it. The command is idempotent — safe to re-run.

The user's request: $ARGUMENTS

## Key Variables

- **Plugin root**: `${CLAUDE_PLUGIN_ROOT}`
- **Metarepo root**: parent directory of plugin root. Resolve it:
  ```bash
  METAREPO=$(cd "${CLAUDE_PLUGIN_ROOT}/.." && pwd)
  ```
  Do NOT read `~/.claude/workspace-config.json` — this command creates that file.

If the user passes `--check`, run in **check-only mode**: report status of all phases without making any changes.

---

## Phase 1: Dependencies

Explain: "Let me check the tools this plugin needs. Required tools are used by every command; optional tools enable specific features."

### Required tools

Check each with `command -v <tool>`. For each, show the path if found, or install instructions if missing:

| Tool | Purpose | Install if missing |
|------|---------|-------------------|
| `jj` | Jujutsu version control — the workspace system is built on JJ workspaces | `brew install jj` |
| `jq` | JSON processing — used by hooks and scripts for metadata | `brew install jq` |
| `gh` | GitHub CLI — fetches PR info, discovers repos | `brew install gh`, then `gh auth login` |
| `git` | Git — underlying VCS for colocated repos | `xcode-select --install` |

If any required tool is missing, ask via `AskUserQuestion`:
- **"Continue anyway"** — proceed (some commands won't work)
- **"Stop here"** — abort so they can install first

### Optional tools

Check each. Report status but do not block:

| Tool | Check | Purpose | Install if missing |
|------|-------|---------|-------------------|
| `zmx` | `command -v zmx` | Terminal session multiplexer — required for `/workspace:cd` workspace switching | `brew install mdsakalu/tap/zmx` |
| `zsm` | `command -v zsm` | TUI for managing zmx sessions — list, attach, kill sessions visually | `brew install mdsakalu/tap/zsm` |
| MarkText | `ls ~/Applications/marktext.app/Contents/MacOS/marktext 2>/dev/null` | Markdown editor — opens notes in `/workspace:notes` | Download from https://github.com/marktext/marktext |
| VS Code | `command -v code` | Code editor — opens workspaces in `/workspace:open` | Install VS Code, then Cmd+Shift+P > "Shell Command: Install code command in PATH" |

Show a summary:
```
Dependencies: 4/4 required ✓, 2/4 optional available
  Required: jj ✓, jq ✓, gh ✓, git ✓
  Optional: zmx ✓, zsm ✗, MarkText ✗, code ✓
```

---

## Phase 2: Configuration

Explain: "The workspace config file tells every command where your metarepo lives. Without it, no commands work."

1. Resolve the metarepo path from `${CLAUDE_PLUGIN_ROOT}/..`
2. Check if `~/.claude/workspace-config.json` already exists:
   - If it exists and `metarepo` matches: report "Already configured" and skip
   - If it exists but points elsewhere: warn and ask via `AskUserQuestion`:
     - **"Update to <new-path>"** — overwrite
     - **"Keep existing"** — leave as-is
   - If it does not exist: create it
3. Create/update the file:
   ```json
   {
     "metarepo": "<resolved-metarepo-path>"
   }
   ```
4. Report: "Config: `~/.claude/workspace-config.json` → `<metarepo-path>`"

---

## Phase 3: Claude zmx Wrapper

Explain: "The zmx wrapper is a shell function that ensures Claude always runs inside a zmx session. This is what makes `/workspace:cd` work — it can kill the current Claude process and respawn it in a different workspace directory, all within the same terminal. If you're already inside a zmx session (nested call), it runs Claude directly."

1. If `zmx` is NOT installed (from Phase 1): say "Skipping — zmx is not installed. Install zmx and re-run `/workspace:onboard` to set this up." Skip to Phase 4.

2. Detect the shell config file:
   - Check `$SHELL` env var
   - If contains `zsh`: use `~/.zshrc`
   - If contains `bash`: use `~/.bashrc`

3. Check if already installed: read the shell config and search for `zmx attach`
   - If found: report "Claude zmx wrapper already installed in `<file>`" and skip

4. If NOT found, show the wrapper snippet and ask via `AskUserQuestion`:
   - **"Yes, add it to <file>"** — append the wrapper
   - **"No, I'll add it manually"** — show the snippet for copy-paste
   - **"Skip"** — skip entirely

5. The wrapper to add (append to end of file with a comment header):

   ```
   # Claude wrapper: run inside zmx for workspace switching support
   claude() {
     if [[ -n "${ZMX_SESSION:-}" ]]; then
       command claude "$@"
       return
     fi
     local name="claude-$$"
     local autostart_file="/tmp/claude-autostart-${name}"
     local cmd="command claude"
     for arg in "$@"; do
       cmd+=" $(printf '%q' "$arg")"
     done
     echo "$cmd" > "$autostart_file"
     zmx attach "$name"
     rm -f "$autostart_file"
   }
   ```

6. If added: report "Added to `<file>`. Restart your shell or run `source <file>` to activate."

---

## Phase 4: Statusline

Explain: "The statusline shows your active workspace in Claude Code's status bar with type-aware icons:

```
🔀 my-app/pr-42│🤖 Opus 4.6 📜12%
```

Icons: 🌳 trunk, 🔀 pr, 🚀 epic, 🧪 spike, 📁 metarepo root.

The statusline is also **required for `/workspace:cd`** — it writes session metadata that the respawn script needs to switch workspaces."

### Check current state

1. Check if `~/.claude/statusline-jj-workspace.sh` exists
2. If it exists, check if it contains workspace detection (search for `metarepo_root` or `workspace_name`):
   - If yes: report "Workspace statusline already installed" and check settings.json config (step 5 below)
   - If the file exists but does NOT contain workspace detection: this is the user's own statusline script — go to the **integration** path below

3. If no statusline script exists, ask via `AskUserQuestion`:
   - **"Install the workspace statusline"** — install the bundled template
   - **"Skip for now"** — skip (warn that `/workspace:cd` won't work without it)

### Install path

4. If installing:
   - Read the bundled template from `${CLAUDE_PLUGIN_ROOT}/templates/statusline-minimal.sh`
   - Replace the `__METAREPO_ROOT__` placeholder with the resolved metarepo path
   - Write to `~/.claude/statusline-jj-workspace.sh`
   - Make executable: `chmod +x ~/.claude/statusline-jj-workspace.sh`

### Integration path (user has their own statusline)

4. If the user has an existing statusline that doesn't have workspace detection:
   - Explain: "You already have a statusline script. To get workspace display and respawn support, you need to add two things to your script:"
   - Show the two required snippets:

   **Snippet 1 — Session metadata (add near the top, after reading input):**
   ```bash
   # Write session metadata for respawn support (/workspace:cd)
   _sid=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)
   _tp=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
   if [[ -n "$_sid" ]]; then
     printf '%s\n%s\n' "$_sid" "$_tp" > "/tmp/claude-session-${PPID}" 2>/dev/null
   fi
   ```

   **Snippet 2 — Workspace detection (add where you build your status line):**
   ```bash
   # See the full template at: ${CLAUDE_PLUGIN_ROOT}/templates/statusline-minimal.sh
   ```

   - Point them to the bundled template as a reference: "The full template is at `${CLAUDE_PLUGIN_ROOT}/templates/statusline-minimal.sh` — you can copy the workspace detection logic from there into your own script."

### Settings.json config

5. Read `~/.claude/settings.json` and check for the `statusLine` key:
   - If already configured with the correct command: report "statusLine config already in settings.json" and skip
   - If not configured: add/update it using the Edit tool:
     ```json
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/statusline-jj-workspace.sh"
     }
     ```
   - Report: "Added statusLine to `~/.claude/settings.json`. Restart Claude to see it."

---

## Phase 5: Dev Mode (optional)

Ask via `AskUserQuestion`:
- **"I'm a developer — set up dev mode"** — proceed
- **"Just using it — skip"** — skip to Phase 6

If developer:

Explain: "Dev mode replaces the cached copy of the plugin with a symlink to your local metarepo source. Edits to shell scripts take effect immediately; edits to commands and hooks take effect on Claude restart. No need to publish to test changes."

1. Detect which marketplace the workspace plugin was installed from:
   - Read `~/.claude/plugins/installed_plugins.json`
   - Look for entries matching `workspace@*` (e.g., `workspace@agent-plugins`, `workspace@mdsakalu-dotfiles`, `workspace@healthsource-scripts`)
   - Extract the `installPath` to find the cache directory
   - If multiple entries found, ask the user which one to symlink

2. Compute paths:
   - `PLUGIN_SRC=<metarepo>/plugin`
   - `CACHE_TARGET=<detected installPath from step 1>`

3. Check if already active: if `CACHE_TARGET` is a symlink pointing to `PLUGIN_SRC`, report "Dev mode already active" and skip

4. Set up the symlink:
   ```bash
   rm -rf <CACHE_TARGET>
   mkdir -p $(dirname <CACHE_TARGET>)
   ln -sf <metarepo>/plugin <CACHE_TARGET>
   ```

5. Verify and report: "Dev mode active. See `${CLAUDE_PLUGIN_ROOT}/docs/development.md` for the full development guide."

---

## Phase 6: Summary + First Steps

Show a setup summary:
```
Setup Complete!

  Config:      ~/.claude/workspace-config.json → <metarepo>
  Wrapper:     <installed in ~/.zshrc / not installed>
  Statusline:  <installed / not installed>
  Dev mode:    <active / inactive>

  Required:    jj ✓, jq ✓, gh ✓, git ✓
  Optional:    zmx ✓, zsm ✗, MarkText ✗, code ✓
```

Show a quick command reference:
```
Commands:
  /workspace:add-repo <org/repo>  Onboard a repository
  /workspace:new <repo> <name>    Create a workspace (epic-*, spike-*, pr-*)
  /workspace:list                 List all workspaces
  /workspace:cd <workspace>       Switch to a workspace
  /workspace:status               Show workspace details
  /workspace:notes                View/edit workspace notes
  /workspace:sync                 Fetch and rebase on trunk
  /workspace:onboard              Re-run this setup anytime
```

Ask via `AskUserQuestion`:
- **"Onboard a repo"** — tell them to run `/workspace:add-repo <org/repo>` and briefly explain the command
- **"I'm all set"** — end with "Run `/workspace:list` anytime to verify your setup."

---

## Important

- This command is **idempotent**. Every phase checks for existing correct configuration before making changes.
- Derive the metarepo path from `${CLAUDE_PLUGIN_ROOT}/..`, never from `workspace-config.json`.
- Use `AskUserQuestion` for every decision point.
- Explain WHY before each phase — this is an educational onboarding, not just a setup script.
- For the shell wrapper (Phase 3), the `printf '%q'` quoting is critical. Do not simplify it.
- If `--check` is passed, report status of all phases without making any changes.
