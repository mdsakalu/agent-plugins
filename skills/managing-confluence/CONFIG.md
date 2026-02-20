# Configuration

## Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `CONFLUENCE_EMAIL` | Your Atlassian account email | `user@company.com` |
| `CONFLUENCE_API_TOKEN` | API token from Atlassian | `ATATT3xFfGF0...` |
| `CONFLUENCE_DOMAIN` | Your Confluence domain | `mycompany.atlassian.net` |

## Setup

### 1. Generate API Token

1. Go to https://id.atlassian.com/manage-api-tokens
2. Click **Create API token**
3. Copy the token (you can't see it again)

### 2. Add to Shell Config

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Using macOS Keychain (recommended)
export CONFLUENCE_EMAIL=$(security find-generic-password -a "$USER" -s "confluence-email" -w 2>/dev/null)
export CONFLUENCE_API_TOKEN=$(security find-generic-password -a "$USER" -s "confluence-api-token" -w 2>/dev/null)
export CONFLUENCE_DOMAIN=$(security find-generic-password -a "$USER" -s "confluence-domain" -w 2>/dev/null)

# Or direct (less secure)
export CONFLUENCE_EMAIL="your.email@company.com"
export CONFLUENCE_API_TOKEN="your-token"
export CONFLUENCE_DOMAIN="yourcompany.atlassian.net"
```

### 3. Store in Keychain (macOS)

```bash
security add-generic-password -a "$USER" -s "confluence-email" -w 'your.email@company.com' -U
security add-generic-password -a "$USER" -s "confluence-api-token" -w 'your-api-token' -U
security add-generic-password -a "$USER" -s "confluence-domain" -w 'yourcompany.atlassian.net' -U
```

## Config File (Space Caching)

Location: `~/.config/claude-skills/managing-confluence/config.json`

### Purpose

Caches space key → ID mappings to avoid slow API lookups every time.

### Structure

```json
{
  "defaultSpaceKey": "MYSPACE",
  "spaces": {
    "MYSPACE": "123456789",
    "DOCS": "987654321"
  },

  "savedQueries": {
    "myRecentEdits": {
      "cql": "contributor = currentUser() AND type = page ORDER BY lastmodified DESC",
      "description": "Pages I recently edited",
      "semanticTriggers": ["my recent edits", "pages I changed", "my work"],
      "usageCount": 0,
      "lastUsed": null
    }
  },
  "querySuggestions": [],

  "spaceConfig": {
    "primary": ["MYSPACE"],
    "secondary": ["DOCS", "ARCHIVE"],
    "all": ["MYSPACE", "DOCS", "ARCHIVE"],
    "interactionCounts": {}
  },

  "recentPages": [],
  "discoveredSpaces": [],
  "knownContributors": [],
  "spacePurposes": {},
  "learnedTemplates": {}
}
```

### Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `defaultSpaceKey` | string | Default space key when none specified |
| `spaces` | object | Space key → space ID cache |
| `savedQueries` | object | Named CQL queries with semantic triggers |
| `querySuggestions` | array | Frequently-used queries pending save |
| `spaceConfig` | object | Multi-space tier configuration |
| `recentPages` | array | Last 50 page interactions |
| `discoveredSpaces` | array | Spaces found via Map Confluence |
| `knownContributors` | array | Discovered active contributors |
| `spacePurposes` | object | AI-generated space descriptions |
| `learnedTemplates` | object | Page templates learned from usage |

See detailed documentation:
- [QUERIES.md](QUERIES.md) - Saved queries and semantic matching
- [SPACES.md](SPACES.md) - Multi-space configuration
- [RECENT.md](RECENT.md) - Recent pages tracking
- [DISCOVERY.md](DISCOVERY.md) - Discovery and mapping
- [TEMPLATES.md](TEMPLATES.md) - Learned templates

### Create Config

```bash
mkdir -p ~/.config/claude-skills/managing-confluence
cat > ~/.config/claude-skills/managing-confluence/config.json << 'EOF'
{
  "defaultSpaceKey": "YOUR_DEFAULT_SPACE",
  "spaces": {}
}
EOF
```

### Add a Space to Cache

```bash
# Look up the space ID
SPACE_KEY="MYSPACE"
export CONFLUENCE_AUTH="Basic $(echo -n "$CONFLUENCE_EMAIL:$CONFLUENCE_API_TOKEN" | base64)"
SPACE_ID=$(curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/spaces?keys=$SPACE_KEY" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "import sys,json; r=json.load(sys.stdin)['results']; print(r[0]['id'] if r else '')")

# Add to config
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

### List All Spaces

```bash
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/spaces?limit=100" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "import sys,json; [print(f'{s[\"key\"]:25} {s[\"id\"]:15} {s[\"name\"]}') for s in json.load(sys.stdin)['results']]"
```

## Test Authentication

```bash
export CONFLUENCE_AUTH="Basic $(echo -n "$CONFLUENCE_EMAIL:$CONFLUENCE_API_TOKEN" | base64)"
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/spaces?limit=1" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "import sys,json; r=json.load(sys.stdin); print('OK' if r.get('results') else 'FAILED')"
```

## Troubleshooting

### "401 Unauthorized"
- Verify email matches your Atlassian account
- Regenerate the API token
- Check token hasn't expired

### "403 Forbidden"
- Your account may not have access to that space
- Check space permissions in Confluence

### "404 Not Found"
- Verify `CONFLUENCE_DOMAIN` is correct (no `https://`, no trailing `/`)
- Check the page/space ID exists

### Environment variables not loading
- Ensure they're in your shell's startup file (`~/.zshrc`)
- Restart Claude Code after changes
