# Multi-Space Support

Organize spaces into tiers based on how frequently you use them.

## Tiers

| Tier | Description | Usage |
|------|-------------|-------|
| **Primary** | Your main working spaces | Searched by default, used for `{primary}` placeholder |
| **Secondary** | Spaces you access occasionally | Available but not default |
| **All** | Complete list | Used for `{all}` placeholder |

## Config Structure

```json
{
  "spaceConfig": {
    "primary": ["PROJ", "TEAM"],
    "secondary": ["DOCS", "ARCHIVE", "HR"],
    "all": ["PROJ", "TEAM", "DOCS", "ARCHIVE", "HR"],
    "interactionCounts": {
      "PROJ": 150,
      "TEAM": 85,
      "DOCS": 42,
      "ARCHIVE": 5,
      "HR": 18
    }
  },
  "spacePurposes": {
    "PROJ": "Main project documentation and sprint planning",
    "TEAM": "Team processes, onboarding, and meeting notes",
    "DOCS": "Public API documentation and user guides",
    "ARCHIVE": "Completed projects and historical records",
    "HR": "HR policies and employee resources"
  }
}
```

## Query Placeholders

Use these in saved CQL queries:

| Placeholder | Expands To | Example |
|-------------|------------|---------|
| `{primary}` | `PROJ, TEAM` | `space IN ({primary})` |
| `{all}` | `PROJ, TEAM, DOCS, ARCHIVE, HR` | `space IN ({all})` |

## Automatic Promotion

When a secondary space is used 20+ times, Claude suggests promotion:

```
I've noticed you frequently work in the DOCS space (25 interactions).
Would you like to promote it to a primary space?
```

### Track Space Interaction

```bash
# Increment interaction count for a space
python3 << 'EOF'
import json, os

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

space_key = "DOCS"

if 'spaceConfig' not in config:
    config['spaceConfig'] = {'primary': [], 'secondary': [], 'all': [], 'interactionCounts': {}}

counts = config['spaceConfig'].setdefault('interactionCounts', {})
counts[space_key] = counts.get(space_key, 0) + 1

# Check if promotion threshold reached
if space_key in config['spaceConfig'].get('secondary', []):
    if counts[space_key] >= 20:
        print(f"SUGGEST_PROMOTION: {space_key} has {counts[space_key]} interactions")

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

### Promote Space to Primary

```bash
# Move space from secondary to primary
python3 << 'EOF'
import json, os

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

space_key = "DOCS"
sc = config.setdefault('spaceConfig', {'primary': [], 'secondary': [], 'all': []})

if space_key in sc.get('secondary', []):
    sc['secondary'].remove(space_key)
if space_key not in sc.get('primary', []):
    sc['primary'].append(space_key)
if space_key not in sc.get('all', []):
    sc['all'].append(space_key)

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print(f"Promoted {space_key} to primary tier")
EOF
```

### Add New Space

```bash
# Add a new space (defaults to secondary tier)
python3 << 'EOF'
import json, os

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

space_key = "NEWSPACE"
space_id = "123456789"
tier = "secondary"  # or "primary"

# Add to spaces cache
config.setdefault('spaces', {})[space_key] = space_id

# Add to space config
sc = config.setdefault('spaceConfig', {'primary': [], 'secondary': [], 'all': []})
if space_key not in sc['all']:
    sc['all'].append(space_key)
if tier == "primary" and space_key not in sc['primary']:
    sc['primary'].append(space_key)
elif tier == "secondary" and space_key not in sc['secondary']:
    sc['secondary'].append(space_key)

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print(f"Added {space_key} to {tier} tier")
EOF
```

## Space Purposes

AI-generated descriptions help answer "where should I put this?" questions.

```bash
# Update space purpose
python3 << 'EOF'
import json, os

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

space_key = "PROJ"
purpose = "Main project documentation and sprint planning"

config.setdefault('spacePurposes', {})[space_key] = purpose

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

### Finding the Right Space

When user asks "where should I put [topic]?", Claude:

1. Reads `spacePurposes` from config
2. Matches topic against purpose descriptions
3. Suggests best-fit space with explanation

Example:
```
User: "Where should I put the API changelog?"
Claude: Based on space purposes:
  - DOCS: "Public API documentation and user guides" <- Best match
  - PROJ: "Main project documentation and sprint planning"

  I'd recommend DOCS since it's specifically for API documentation.
```

## Graceful Degradation

If `spaceConfig` is missing:
- Use `defaultSpaceKey` only
- No multi-space searching
- No promotion suggestions

If `spacePurposes` is missing:
- Cannot suggest spaces based on content
- Fall back to asking user directly
