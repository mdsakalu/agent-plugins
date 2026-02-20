# Saved CQL Queries

Store frequently-used CQL queries with semantic triggers for natural language matching.

## How It Works

1. **Semantic Matching**: Claude reads `savedQueries` from config and matches user intent against `semanticTriggers` and `description`
2. **Confidence Levels**:
   - High (90%+): Execute directly
   - Medium: Confirm with user before executing
   - Low: Ask for clarification
3. **Learning**: After execution, update `usageCount` and `lastUsed`

## Config Structure

```json
{
  "savedQueries": {
    "queryName": {
      "cql": "CQL query string with {placeholders}",
      "description": "Human-readable description",
      "semanticTriggers": ["trigger phrase 1", "trigger phrase 2"],
      "usageCount": 0,
      "lastUsed": null
    }
  },
  "querySuggestions": [
    {
      "cql": "query that was run multiple times",
      "runCount": 3,
      "firstRun": "2026-01-20T10:00:00Z",
      "lastRun": "2026-01-23T14:30:00Z"
    }
  ]
}
```

## Default Queries

These should be present in a fresh config:

```json
{
  "savedQueries": {
    "myRecentEdits": {
      "cql": "contributor = currentUser() AND type = page ORDER BY lastmodified DESC",
      "description": "Pages I recently edited",
      "semanticTriggers": ["my recent edits", "pages I changed", "my work", "what I edited"],
      "usageCount": 0,
      "lastUsed": null
    },
    "spacePages": {
      "cql": "space = {space} AND type = page ORDER BY lastmodified DESC",
      "description": "Pages in a specific space",
      "semanticTriggers": ["pages in space", "what's in space", "space content"],
      "usageCount": 0,
      "lastUsed": null
    },
    "recentlyUpdated": {
      "cql": "space IN ({primary}) AND type = page ORDER BY lastmodified DESC",
      "description": "Recently updated pages in primary spaces",
      "semanticTriggers": ["recently updated", "what's new", "recent changes", "latest updates"],
      "usageCount": 0,
      "lastUsed": null
    },
    "myDrafts": {
      "cql": "creator = currentUser() AND label = 'draft' AND type = page",
      "description": "My draft pages",
      "semanticTriggers": ["my drafts", "unpublished pages", "draft pages"],
      "usageCount": 0,
      "lastUsed": null
    }
  }
}
```

## Placeholders

Use these in CQL queries:

| Placeholder | Replaced With |
|-------------|---------------|
| `{space}` | User-specified space key |
| `{primary}` | Comma-separated primary space keys |
| `{all}` | Comma-separated all space keys |
| `{user}` | User-specified username/email |

## Learning: Auto-Suggest Saving

When Claude notices a CQL query has been run 3+ times:

1. Add to `querySuggestions` array (if not already present)
2. After 3rd run, suggest saving:
   ```
   I've noticed you run this query frequently:
   `space = DOCS AND label = 'api-reference'`

   Would you like to save it with a name like "apiDocs"?
   ```
3. If user agrees, move from `querySuggestions` to `savedQueries`

### Update Config After Query Execution

```bash
# Increment usage count and update lastUsed
python3 << 'EOF'
import json, os
from datetime import datetime, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

query_name = "myRecentEdits"  # The query that was just executed
if query_name in config.get('savedQueries', {}):
    config['savedQueries'][query_name]['usageCount'] += 1
    config['savedQueries'][query_name]['lastUsed'] = datetime.now(timezone.utc).isoformat()

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

### Track Query for Suggestion

```bash
# Track a CQL query that was run (for learning)
python3 << 'EOF'
import json, os
from datetime import datetime, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

cql = "space = DOCS AND label = 'api-reference'"
now = datetime.now(timezone.utc).isoformat()

if 'querySuggestions' not in config:
    config['querySuggestions'] = []

# Find existing or create new
existing = next((q for q in config['querySuggestions'] if q['cql'] == cql), None)
if existing:
    existing['runCount'] += 1
    existing['lastRun'] = now
else:
    config['querySuggestions'].append({
        'cql': cql,
        'runCount': 1,
        'firstRun': now,
        'lastRun': now
    })

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

## Semantic Matching Examples

| User Says | Matches | Confidence |
|-----------|---------|------------|
| "show me my recent edits" | `myRecentEdits` | High |
| "what have I worked on lately?" | `myRecentEdits` | High |
| "pages I've changed" | `myRecentEdits` | High |
| "what's new in DOCS?" | `recentlyUpdated` (with space=DOCS) | High |
| "find my drafts" | `myDrafts` | High |
| "search for meeting notes" | None (use raw CQL) | - |

## Graceful Degradation

If `savedQueries` is missing or empty:
- Claude uses normal CQL interpretation
- No suggestions offered
- Queries still tracked in `querySuggestions` for future learning
