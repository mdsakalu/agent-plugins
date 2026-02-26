---
name: managing-confluence
description: Manages Confluence Cloud pages via REST API - create, read, update, delete pages, manage attachments, search content. Invoke when the user asks about Confluence pages, wiki content, documentation, or wants to interact with their Confluence instance.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
license: MIT
metadata:
  version: 3.0.0
  updated: 2026-01-23
  spec-version: agentskills.io/2026
compatibility: |
  Requires: curl, python3 (for JSON parsing), base64.
  Environment variables: CONFLUENCE_EMAIL, CONFLUENCE_API_TOKEN, CONFLUENCE_DOMAIN.
  Claude Code only - requires Bash execution for API calls.
---

# Managing Confluence

## Quick Start

```bash
# 1. Set up authentication (once per session)
export CONFLUENCE_AUTH="Basic $(echo -n "$CONFLUENCE_EMAIL:$CONFLUENCE_API_TOKEN" | base64)"

# 2. List spaces
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/spaces?limit=10" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" | python3 -m json.tool

# 3. Search for a page
curl -s "https://$CONFLUENCE_DOMAIN/wiki/rest/api/search?cql=title~keyword" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" | python3 -m json.tool
```

## Auto-Approved Tools

This skill has `allowed-tools: Bash, Read, Edit, Write, Glob, Grep` - these run WITHOUT permission prompts.

## Session Setup

Run once per session:

```bash
export CONFLUENCE_AUTH="Basic $(echo -n "$CONFLUENCE_EMAIL:$CONFLUENCE_API_TOKEN" | base64)"
```

## Cached Spaces

Read config with the Read tool (no prompt needed):

**Config path:** `~/.config/claude-skills/managing-confluence/config.json`

Use the Read tool to check this file for cached space IDs before making API calls.

## Space Lookup (with Caching)

**IMPORTANT:** Always check config cache first before API lookup.

### Get Space ID (Check Cache First)

```bash
# Check cache first
SPACE_KEY="MYSPACE"
SPACE_ID=$(cat ~/.config/claude-skills/managing-confluence/config.json 2>/dev/null | python3 -c "import sys,json; c=json.load(sys.stdin); print(c.get('spaces',{}).get('$SPACE_KEY',''))" 2>/dev/null)

# If not cached, look up and cache it
if [[ -z "$SPACE_ID" ]]; then
  SPACE_ID=$(curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/spaces?keys=$SPACE_KEY" \
    -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
    | python3 -c "import sys,json; r=json.load(sys.stdin)['results']; print(r[0]['id'] if r else '')")
  echo "Looked up $SPACE_KEY -> $SPACE_ID (consider caching)"
fi
echo "Space ID: $SPACE_ID"
```

### Cache a Space ID

```bash
# Add space to cache
SPACE_KEY="MYSPACE"
SPACE_ID="123456789"

mkdir -p ~/.config/claude-skills/managing-confluence
python3 << EOF
import json, os
config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
try:
    with open(config_path) as f: config = json.load(f)
except: config = {}
if 'spaces' not in config: config['spaces'] = {}
config['spaces']['$SPACE_KEY'] = '$SPACE_ID'
with open(config_path, 'w') as f: json.dump(config, f, indent=2)
print(f"Cached: $SPACE_KEY -> $SPACE_ID")
EOF
```

### List All Spaces (to find keys/IDs)

```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/spaces?limit=50" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "import sys,json; [print(f\"{s['key']:20} {s['id']:15} {s['name']}\") for s in json.load(sys.stdin)['results']]"
```

## Quick Reference Commands

All commands use `$CONFLUENCE_AUTH` (set once above). No sourcing needed.

### List Spaces
```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/spaces?limit=25" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" | python3 -m json.tool
```

### Get Page by ID
```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages/PAGE_ID?body-format=storage" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" | python3 -m json.tool
```

### Search Pages (CQL)
```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/rest/api/search?cql=title~keyword&limit=20" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" | python3 -m json.tool
```

### Create Page
```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages" -X POST \
  -H "Authorization: $CONFLUENCE_AUTH" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"spaceId":"SPACE_ID","status":"current","title":"Page Title","body":{"representation":"storage","value":"<p>Content</p>"}}'
```

### Create Child Page
```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages" -X POST \
  -H "Authorization: $CONFLUENCE_AUTH" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"spaceId":"SPACE_ID","parentId":"PARENT_PAGE_ID","status":"current","title":"Page Title","body":{"representation":"storage","value":"<p>Content</p>"}}'
```

### Update Page (requires version number)
```bash
# Get current version first
VERSION=$(curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages/PAGE_ID" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['version']['number'])")

# Update with version+1
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages/PAGE_ID" -X PUT \
  -H "Authorization: $CONFLUENCE_AUTH" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d "{\"id\":\"PAGE_ID\",\"status\":\"current\",\"title\":\"New Title\",\"version\":{\"number\":$((VERSION+1))},\"body\":{\"representation\":\"storage\",\"value\":\"<p>New content</p>\"}}"
```

### Delete Page
```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages/PAGE_ID" -X DELETE \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json"
```

### Get Page Children
```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages/PAGE_ID/children?limit=25" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" | python3 -m json.tool
```

### Upload Attachment (use v1 API)
```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/rest/api/content/PAGE_ID/child/attachment" -X POST \
  -H "Authorization: $CONFLUENCE_AUTH" -H "X-Atlassian-Token: nocheck" \
  -F "file=@/path/to/file.jpg"
```

### Get Page with Ancestors (for path)
```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/rest/api/content/PAGE_ID?expand=ancestors" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(' > '.join([a['title'] for a in d.get('ancestors',[])]))"
```

## Common Patterns

### Find Space ID and Cache It
```bash
SPACE_KEY="MYSPACE"
SPACE_ID=$(curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/spaces?keys=$SPACE_KEY" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "import sys,json; r=json.load(sys.stdin)['results']; print(r[0]['id'] if r else '')")
echo "$SPACE_KEY -> $SPACE_ID"

# Cache it for future use
mkdir -p ~/.config/claude-skills/managing-confluence
python3 -c "
import json,os
p='$HOME/.config/claude-skills/managing-confluence/config.json'
c=json.load(open(p)) if os.path.exists(p) else {}
c.setdefault('spaces',{})['$SPACE_KEY']='$SPACE_ID'
json.dump(c,open(p,'w'),indent=2)
"
```

### Create Page from Markdown with Images

1. Create page first
2. Upload images as attachments (v1 API)
3. Update page with image macros

**Image macro:**
```html
<ac:image ac:alt="Description"><ri:attachment ri:filename="image.jpg" /></ac:image>
```

**Markdown conversions:**
- `# Heading` → `<h1>Heading</h1>`
- `**bold**` → `<strong>bold</strong>`
- `![alt](path)` → `<ac:image><ri:attachment ri:filename="..." /></ac:image>`
- Code blocks → `<ac:structured-macro ac:name="code">...</ac:structured-macro>`
- `<details>` → `<ac:structured-macro ac:name="expand">...</ac:structured-macro>`

### Move Page to Different Parent (Same Space)
```bash
PAGE_ID="123"
NEW_PARENT_ID="456"
VERSION=$(curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages/$PAGE_ID" \
  -H "Authorization: $CONFLUENCE_AUTH" | python3 -c "import sys,json; print(json.load(sys.stdin)['version']['number'])")

curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages/$PAGE_ID" -X PUT \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Content-Type: application/json" \
  -d "{\"id\":\"$PAGE_ID\",\"status\":\"current\",\"title\":\"Same Title\",\"parentId\":\"$NEW_PARENT_ID\",\"version\":{\"number\":$((VERSION+1))}}"
```

### Move Page to Different Space (v1 API Required)

**Important:** The v2 API cannot move published pages between spaces. Use the v1 move endpoint instead.

```bash
PAGE_ID="123"
NEW_PARENT_ID="456"  # Parent page in target space

# Move page to be a child of NEW_PARENT_ID (automatically changes space)
curl -s "https://$CONFLUENCE_DOMAIN/wiki/rest/api/content/$PAGE_ID/move/append/$NEW_PARENT_ID" \
  -X PUT \
  -H "Authorization: $CONFLUENCE_AUTH" \
  -H "Content-Type: application/json"
```

**Move positions:**
- `append` - Add as last child of target
- `prepend` - Add as first child of target
- `before` - Add as sibling before target
- `after` - Add as sibling after target

## Intelligent Features

This skill learns from your usage to become faster and more helpful over time.

| Feature | Description | Reference |
|---------|-------------|-----------|
| **Saved Queries** | CQL queries with semantic matching - say "my recent edits" instead of writing CQL | [QUERIES.md](QUERIES.md) |
| **Multi-Space** | Primary/secondary space tiers, auto-promotion based on usage | [SPACES.md](SPACES.md) |
| **Recent Pages** | Track pages you've created, edited, viewed for quick lookups | [RECENT.md](RECENT.md) |
| **Map Confluence** | Discover spaces, hierarchies, and contributors | [DISCOVERY.md](DISCOVERY.md) |
| **Learned Templates** | Remember page structures you create frequently | [TEMPLATES.md](TEMPLATES.md) |

### Learning Triggers

| Trigger | What Happens |
|---------|--------------|
| Query run 3+ times | Suggest saving to `savedQueries` |
| Space used 20+ times | Suggest promotion to primary tier |
| Page created/edited/viewed | Added to `recentPages` (last 50) |
| Similar page structure 3x | Suggest saving as template |

All learning updates are stored in `~/.config/claude-skills/managing-confluence/config.json`.

## Reference

- **Configuration**: See [CONFIG.md](CONFIG.md)
- **Storage format & CQL**: See [REFERENCE.md](REFERENCE.md)
- **Intelligent features**: See [QUERIES.md](QUERIES.md), [SPACES.md](SPACES.md), [RECENT.md](RECENT.md), [DISCOVERY.md](DISCOVERY.md), [TEMPLATES.md](TEMPLATES.md)

## Known Limitations

- **Space ID vs Key**: V2 API uses numeric IDs. Cache them in config to avoid repeated lookups.
- **Version required for updates**: Always get current version first.
- **Attachments**: Use v1 API (`/rest/api/content/`) for uploads - more reliable.
- **Cross-space moves**: V2 API rejects moving published pages between spaces. Use v1 API `/rest/api/content/{id}/move/append/{targetId}` instead.
