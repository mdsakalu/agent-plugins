# Plugin Development Guide

## Architecture

```
Source of truth (development):
  <metarepo>/plugin/              ← edit here

Distribution (GitHub marketplace):
  <marketplace-repo>/workspace/   ← pushed from metarepo via publish script

Claude Code loading (runtime):
  ~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/
    ↑ symlink to metarepo/plugin/ on dev machines
    ↑ real copy on normal installs
```

## Normal Install

```bash
# In Claude Code — add the marketplace that distributes this plugin:
/plugin marketplace add <org>/<repo>
/plugin install workspace@<marketplace-name>
```

Claude caches the plugin at `~/.claude/plugins/cache/<marketplace>/workspace/<version>/`.

## Editable Install (dev machine)

After normal install, replace the cache directory with a symlink to your local source:

```bash
# Find the cache path (check ~/.claude/plugins/installed_plugins.json for installPath)
CACHE_PATH=~/.claude/plugins/cache/<marketplace>/workspace/<version>

# Back up the cached copy
mv "$CACHE_PATH" "${CACHE_PATH}.bak"

# Symlink to your local plugin source
ln -s /path/to/metarepo/plugin "$CACHE_PATH"
```

Restart Claude. Edits to the plugin source take effect on next Claude restart.

### Why this works

Claude Code resolves plugins by checking `cache/<marketplace>/<plugin>/<version>/`.
The OS transparently follows the symlink. Claude never re-caches unless you explicitly
run `/plugin update`, so the symlink is stable.

### What breaks it

Only user-initiated actions:
- Running `/plugin update workspace@<marketplace>`
- Manually deleting the cache directory
- Changing the version in `plugin.json` and re-installing

If the symlink breaks, just re-run the backup + symlink commands above.

## Publishing Changes

Publishing is managed from the metarepo root (outside this plugin directory).
See the metarepo's `PUBLISHING.md` for multi-target distribution instructions.

## Updating on other machines

Recipients pick up changes with:
```bash
# In Claude Code:
/plugin marketplace update
/plugin update
```
