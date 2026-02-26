# Recent Pages Memory

Track pages you've created, edited, or viewed for quick lookups.

## Purpose

Enables queries like:
- "What was that page I was looking at yesterday?"
- "Find the page I created last week"
- "Show my recent work"

## Config Structure

```json
{
  "recentPages": [
    {
      "pageId": "123456",
      "title": "API Documentation",
      "spaceKey": "DOCS",
      "interaction": "edited",
      "timestamp": "2026-01-23T10:30:00Z",
      "url": "/wiki/spaces/DOCS/pages/123456"
    },
    {
      "pageId": "789012",
      "title": "Sprint Planning",
      "spaceKey": "PROJ",
      "interaction": "created",
      "timestamp": "2026-01-22T15:00:00Z",
      "url": "/wiki/spaces/PROJ/pages/789012"
    }
  ]
}
```

## Interaction Types

| Type | When Recorded |
|------|---------------|
| `created` | After successfully creating a page |
| `edited` | After successfully updating a page |
| `viewed` | After fetching page content for display |
| `searched` | After finding page via search |

## Recording Interactions

### After Creating a Page

```bash
python3 << 'EOF'
import json, os
from datetime import datetime, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

page = {
    "pageId": "123456",
    "title": "API Documentation",
    "spaceKey": "DOCS",
    "interaction": "created",
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "url": "/wiki/spaces/DOCS/pages/123456"
}

if 'recentPages' not in config:
    config['recentPages'] = []

# Add to front (most recent first)
config['recentPages'].insert(0, page)

# Keep only last 50
config['recentPages'] = config['recentPages'][:50]

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

### After Editing a Page

```bash
python3 << 'EOF'
import json, os
from datetime import datetime, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

page_id = "123456"
title = "API Documentation"
space_key = "DOCS"
now = datetime.now(timezone.utc).isoformat()

if 'recentPages' not in config:
    config['recentPages'] = []

# Remove any existing entry for this page
config['recentPages'] = [p for p in config['recentPages'] if p['pageId'] != page_id]

# Add new entry at front
config['recentPages'].insert(0, {
    "pageId": page_id,
    "title": title,
    "spaceKey": space_key,
    "interaction": "edited",
    "timestamp": now,
    "url": f"/wiki/spaces/{space_key}/pages/{page_id}"
})

# Keep only last 50
config['recentPages'] = config['recentPages'][:50]

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

### After Viewing a Page

```bash
python3 << 'EOF'
import json, os
from datetime import datetime, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

page_id = "123456"
title = "API Documentation"
space_key = "DOCS"
now = datetime.now(timezone.utc).isoformat()

if 'recentPages' not in config:
    config['recentPages'] = []

# Check if already in recent (within last hour)
existing = next((p for p in config['recentPages'][:10] if p['pageId'] == page_id), None)
if existing:
    # Update timestamp if viewing same page again
    existing['timestamp'] = now
    existing['interaction'] = 'viewed'
else:
    # Add new entry
    config['recentPages'].insert(0, {
        "pageId": page_id,
        "title": title,
        "spaceKey": space_key,
        "interaction": "viewed",
        "timestamp": now,
        "url": f"/wiki/spaces/{space_key}/pages/{page_id}"
    })

# Keep only last 50
config['recentPages'] = config['recentPages'][:50]

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

## Querying Recent Pages

### Find by Title (Fuzzy)

```bash
# Search recent pages by title
python3 << 'EOF'
import json, os

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

search = "api"  # User's search term
search_lower = search.lower()

matches = [
    p for p in config.get('recentPages', [])
    if search_lower in p['title'].lower()
]

for p in matches[:10]:
    print(f"{p['interaction']:10} {p['spaceKey']:10} {p['title']}")
    print(f"           Page ID: {p['pageId']}")
    print(f"           {p['timestamp']}")
    print()
EOF
```

### Find by Interaction Type

```bash
# Find pages I created
python3 << 'EOF'
import json, os

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

interaction_type = "created"

matches = [
    p for p in config.get('recentPages', [])
    if p['interaction'] == interaction_type
]

for p in matches[:10]:
    print(f"{p['spaceKey']:10} {p['title']}")
    print(f"           {p['timestamp']}")
    print()
EOF
```

### Find by Time Range

```bash
# Find pages from last 7 days
python3 << 'EOF'
import json, os
from datetime import datetime, timedelta, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

cutoff = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()

matches = [
    p for p in config.get('recentPages', [])
    if p['timestamp'] >= cutoff
]

for p in matches:
    print(f"{p['interaction']:10} {p['spaceKey']:10} {p['title']}")
EOF
```

## Example Queries

| User Says | How Claude Uses Recent Pages |
|-----------|------------------------------|
| "What was that page about deployment?" | Search titles for "deployment" |
| "Show pages I created last week" | Filter by `interaction=created` and date |
| "Find the page I was editing yesterday" | Filter by `interaction=edited` and date |
| "What have I been working on?" | Show most recent 10 entries |
| "Go back to that API page" | Search titles for "API", return most recent |

## Graceful Degradation

If `recentPages` is empty or missing:
- Cannot answer "what was that page?" queries
- Fall back to CQL search: `contributor = currentUser() ORDER BY lastmodified DESC`
- Still record new interactions going forward
