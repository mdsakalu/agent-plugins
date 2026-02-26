# Map Confluence Discovery

Discover spaces, page hierarchies, and contributors across your Confluence instance.

## Purpose

The "Map Confluence" command helps you:
- Find spaces you didn't know existed
- Understand what each space contains
- Discover who works on what
- Build a knowledge graph of your wiki

## Running Discovery

When user says "map confluence" or "discover spaces":

1. Start from primary spaces
2. Spider outward to find related content
3. Build contributor graph
4. Generate AI descriptions of each space
5. Store results in config

## Discovery Algorithm

```
1. List all accessible spaces
2. For each primary space:
   a. Get recent pages (last 30 days)
   b. Extract contributors
   c. Find cross-space links
3. For linked spaces not in config:
   a. Sample 10 recent pages
   b. Generate purpose description
   c. Add to discoveredSpaces
4. Build contributor graph
5. Update config
```

## Config Structure

```json
{
  "discoveredSpaces": [
    {
      "key": "INFRA",
      "id": "567890",
      "name": "Infrastructure",
      "discoveredFrom": "PROJ",
      "discoveredAt": "2026-01-23T10:30:00Z",
      "linkCount": 5,
      "samplePages": ["AWS Setup", "Monitoring Guide", "Deployment Pipeline"]
    }
  ],
  "knownContributors": [
    {
      "accountId": "abc123",
      "displayName": "Jane Smith",
      "email": "jane@company.com",
      "activeSpaces": ["PROJ", "TEAM"],
      "recentActivity": "2026-01-22T15:00:00Z"
    }
  ],
  "spacePurposes": {
    "PROJ": "Main project documentation and sprint planning",
    "INFRA": "Infrastructure setup, monitoring, and deployment guides"
  }
}
```

## Discovery Commands

### Full Discovery

```bash
# Get all spaces
export CONFLUENCE_AUTH="Basic $(echo -n "$CONFLUENCE_EMAIL:$CONFLUENCE_API_TOKEN" | base64)"

curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/spaces?limit=100" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "
import sys, json
spaces = json.load(sys.stdin)['results']
for s in spaces:
    print(f\"{s['key']:20} {s['id']:15} {s['name']}\")
"
```

### Find Cross-Space Links

```bash
# Find pages in PROJ that link to other spaces
PAGE_ID="123456"
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages/$PAGE_ID?body-format=storage" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "
import sys, json, re
data = json.load(sys.stdin)
body = data.get('body', {}).get('storage', {}).get('value', '')
# Find space links: ri:space-key=\"SPACE\"
spaces = re.findall(r'ri:space-key=\"([^\"]+)\"', body)
for s in set(spaces):
    print(s)
"
```

### Get Space Contributors

```bash
# Find contributors to a space (last 30 days)
SPACE_KEY="PROJ"
curl -s "https://$CONFLUENCE_DOMAIN/wiki/rest/api/search?cql=space=$SPACE_KEY+AND+lastModified>now('-30d')&limit=50" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "
import sys, json
results = json.load(sys.stdin).get('results', [])
contributors = {}
for r in results:
    if 'lastModified' in r:
        author = r.get('lastModified', {}).get('by', {})
        if author:
            aid = author.get('accountId', 'unknown')
            contributors[aid] = {
                'displayName': author.get('displayName', 'Unknown'),
                'accountId': aid
            }
for c in contributors.values():
    print(f\"{c['displayName']:30} {c['accountId']}\")
"
```

### Sample Space Content

```bash
# Get sample pages from a space for AI description
SPACE_KEY="INFRA"
SPACE_ID=$(cat ~/.config/claude-skills/managing-confluence/config.json | python3 -c "import sys,json; print(json.load(sys.stdin).get('spaces',{}).get('$SPACE_KEY',''))")

curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/spaces/$SPACE_ID/pages?limit=10&sort=-modified-date" \
  -H "Authorization: $CONFLUENCE_AUTH" -H "Accept: application/json" \
  | python3 -c "
import sys, json
pages = json.load(sys.stdin).get('results', [])
for p in pages:
    print(p['title'])
"
```

## Storing Discovery Results

```bash
# Add discovered space to config
python3 << 'EOF'
import json, os
from datetime import datetime, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

discovery = {
    "key": "INFRA",
    "id": "567890",
    "name": "Infrastructure",
    "discoveredFrom": "PROJ",
    "discoveredAt": datetime.now(timezone.utc).isoformat(),
    "linkCount": 5,
    "samplePages": ["AWS Setup", "Monitoring Guide", "Deployment Pipeline"]
}

if 'discoveredSpaces' not in config:
    config['discoveredSpaces'] = []

# Update or add
existing = next((s for s in config['discoveredSpaces'] if s['key'] == discovery['key']), None)
if existing:
    existing.update(discovery)
else:
    config['discoveredSpaces'].append(discovery)

# Also cache the space ID
config.setdefault('spaces', {})[discovery['key']] = discovery['id']

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

### Add Contributor

```bash
python3 << 'EOF'
import json, os
from datetime import datetime, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

contributor = {
    "accountId": "abc123",
    "displayName": "Jane Smith",
    "email": "jane@company.com",
    "activeSpaces": ["PROJ", "TEAM"],
    "recentActivity": datetime.now(timezone.utc).isoformat()
}

if 'knownContributors' not in config:
    config['knownContributors'] = []

# Update or add
existing = next((c for c in config['knownContributors'] if c['accountId'] == contributor['accountId']), None)
if existing:
    existing.update(contributor)
else:
    config['knownContributors'].append(contributor)

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

## AI-Generated Space Purposes

After sampling pages from a space, Claude generates a purpose description:

1. Read 10 recent page titles and snippets
2. Identify common themes
3. Generate 1-sentence purpose
4. Store in `spacePurposes`

Example output:
```
Based on the pages in INFRA:
- AWS Setup Guide
- Kubernetes Deployment
- Monitoring with Datadog
- CI/CD Pipeline Configuration
- Database Backup Procedures

Purpose: "Infrastructure setup, cloud deployment, monitoring, and DevOps procedures"
```

## Using Discovery Results

### Find Expert

```
User: "Who knows about the deployment pipeline?"
Claude: [Reads knownContributors, checks activeSpaces]
        Jane Smith has been active in INFRA where deployment docs live.
```

### Suggest Related Spaces

```
User: "I'm documenting our new AWS service"
Claude: [Reads spacePurposes]
        INFRA seems like the best fit - it's for "Infrastructure setup,
        cloud deployment, monitoring, and DevOps procedures"
```

## Graceful Degradation

If discovery hasn't been run:
- No `discoveredSpaces` - only use manually configured spaces
- No `knownContributors` - cannot suggest experts
- No `spacePurposes` - cannot match content to spaces
