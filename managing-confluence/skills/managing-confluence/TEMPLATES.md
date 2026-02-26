# Learned Page Templates

Learn page structures from your frequently-created pages and suggest them for similar content.

## Purpose

When you create similar pages repeatedly, the skill can:
1. Recognize the pattern
2. Save the structure as a template
3. Suggest it when creating similar pages

## Config Structure

```json
{
  "learnedTemplates": {
    "meetingNotes": {
      "name": "Meeting Notes",
      "description": "Standard meeting notes with attendees, agenda, and action items",
      "semanticTriggers": ["meeting notes", "meeting summary", "sync notes"],
      "structure": {
        "sections": ["Attendees", "Agenda", "Discussion", "Action Items", "Next Meeting"],
        "storage": "<h2>Attendees</h2><p>{attendees}</p><h2>Agenda</h2><ul><li>{agenda}</li></ul><h2>Discussion</h2><p>{discussion}</p><h2>Action Items</h2><ac:task-list><ac:task><ac:task-status>incomplete</ac:task-status><ac:task-body>{action}</ac:task-body></ac:task></ac:task-list><h2>Next Meeting</h2><p>{nextMeeting}</p>"
      },
      "usageCount": 5,
      "lastUsed": "2026-01-23T10:00:00Z",
      "createdAt": "2026-01-15T09:00:00Z"
    },
    "apiEndpoint": {
      "name": "API Endpoint Documentation",
      "description": "REST API endpoint documentation with request/response examples",
      "semanticTriggers": ["api endpoint", "api docs", "endpoint documentation"],
      "structure": {
        "sections": ["Overview", "Endpoint", "Request", "Response", "Examples", "Errors"],
        "storage": "<h2>Overview</h2><p>{overview}</p><h2>Endpoint</h2><ac:structured-macro ac:name=\"code\"><ac:parameter ac:name=\"language\">text</ac:parameter><ac:plain-text-body><![CDATA[{method} {path}]]></ac:plain-text-body></ac:structured-macro><h2>Request</h2><h3>Headers</h3><table><tr><th>Header</th><th>Value</th></tr><tr><td>{header}</td><td>{value}</td></tr></table><h3>Body</h3><ac:structured-macro ac:name=\"code\"><ac:parameter ac:name=\"language\">json</ac:parameter><ac:plain-text-body><![CDATA[{requestBody}]]></ac:plain-text-body></ac:structured-macro><h2>Response</h2><ac:structured-macro ac:name=\"code\"><ac:parameter ac:name=\"language\">json</ac:parameter><ac:plain-text-body><![CDATA[{responseBody}]]></ac:plain-text-body></ac:structured-macro><h2>Examples</h2><p>{examples}</p><h2>Error Codes</h2><table><tr><th>Code</th><th>Description</th></tr><tr><td>{code}</td><td>{description}</td></tr></table>"
      },
      "usageCount": 3,
      "lastUsed": "2026-01-22T14:00:00Z",
      "createdAt": "2026-01-10T11:00:00Z"
    }
  },
  "templateSuggestions": [
    {
      "pattern": {
        "sections": ["Background", "Requirements", "Implementation", "Testing"],
        "titlePattern": "RFC:*"
      },
      "occurrences": 2,
      "pageIds": ["111", "222"],
      "firstSeen": "2026-01-20T10:00:00Z"
    }
  ]
}
```

## Learning: Pattern Detection

When a page is created, Claude analyzes its structure:

1. Extract headings (h1, h2, h3)
2. Identify structural elements (tables, code blocks, task lists)
3. Compare against recent page structures
4. If similar structure seen 3+ times, suggest saving as template

### Detect Page Structure

```bash
# Extract structure from page content
python3 << 'EOF'
import json, re

# Example page content (storage format)
content = """
<h2>Attendees</h2><p>John, Jane</p>
<h2>Agenda</h2><ul><li>Topic 1</li></ul>
<h2>Discussion</h2><p>Notes here</p>
<h2>Action Items</h2><ac:task-list><ac:task>...</ac:task></ac:task-list>
"""

# Extract h2 sections
sections = re.findall(r'<h2>([^<]+)</h2>', content)

# Detect special elements
has_task_list = '<ac:task-list>' in content
has_code_block = '<ac:structured-macro ac:name="code">' in content
has_table = '<table>' in content

structure = {
    "sections": sections,
    "hasTaskList": has_task_list,
    "hasCodeBlock": has_code_block,
    "hasTable": has_table
}

print(json.dumps(structure, indent=2))
EOF
```

### Track Pattern for Learning

```bash
# Record a page structure for pattern learning
python3 << 'EOF'
import json, os
from datetime import datetime, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

page_id = "333"
sections = ["Attendees", "Agenda", "Discussion", "Action Items"]
title = "Team Sync 2026-01-23"

if 'templateSuggestions' not in config:
    config['templateSuggestions'] = []

# Check for similar patterns
def sections_match(s1, s2):
    return set(s1) == set(s2)

existing = next(
    (t for t in config['templateSuggestions']
     if sections_match(t['pattern']['sections'], sections)),
    None
)

if existing:
    existing['occurrences'] += 1
    if page_id not in existing['pageIds']:
        existing['pageIds'].append(page_id)

    if existing['occurrences'] >= 3:
        print(f"SUGGEST_TEMPLATE: Pattern seen {existing['occurrences']} times")
        print(f"Sections: {sections}")
else:
    config['templateSuggestions'].append({
        "pattern": {
            "sections": sections,
            "titlePattern": None
        },
        "occurrences": 1,
        "pageIds": [page_id],
        "firstSeen": datetime.now(timezone.utc).isoformat()
    })

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

## Saving a Template

When user agrees to save a template:

```bash
python3 << 'EOF'
import json, os
from datetime import datetime, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

template_key = "meetingNotes"
template = {
    "name": "Meeting Notes",
    "description": "Standard meeting notes with attendees, agenda, and action items",
    "semanticTriggers": ["meeting notes", "meeting summary", "sync notes", "standup notes"],
    "structure": {
        "sections": ["Attendees", "Agenda", "Discussion", "Action Items"],
        "storage": "<h2>Attendees</h2><p></p><h2>Agenda</h2><ul><li></li></ul><h2>Discussion</h2><p></p><h2>Action Items</h2><ac:task-list><ac:task><ac:task-status>incomplete</ac:task-status><ac:task-body></ac:task-body></ac:task></ac:task-list>"
    },
    "usageCount": 0,
    "lastUsed": None,
    "createdAt": datetime.now(timezone.utc).isoformat()
}

if 'learnedTemplates' not in config:
    config['learnedTemplates'] = {}

config['learnedTemplates'][template_key] = template

# Remove from suggestions if present
if 'templateSuggestions' in config:
    config['templateSuggestions'] = [
        t for t in config['templateSuggestions']
        if set(t['pattern']['sections']) != set(template['structure']['sections'])
    ]

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print(f"Saved template: {template_key}")
EOF
```

## Using Templates

### Semantic Matching

When user says "create a meeting notes page", Claude:

1. Reads `learnedTemplates` from config
2. Matches "meeting notes" against `semanticTriggers` and `name`
3. Offers to use the template

### Apply Template

```bash
# Create page using template structure
TEMPLATE_KEY="meetingNotes"
SPACE_ID="123456"
TITLE="Team Sync 2026-01-23"

# Get template from config
STORAGE=$(python3 << 'EOF'
import json, os
config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)
template = config.get('learnedTemplates', {}).get('meetingNotes', {})
print(template.get('structure', {}).get('storage', '<p>No template</p>'))
EOF
)

# Create page with template structure
curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages" -X POST \
  -H "Authorization: $CONFLUENCE_AUTH" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d "{\"spaceId\":\"$SPACE_ID\",\"status\":\"current\",\"title\":\"$TITLE\",\"body\":{\"representation\":\"storage\",\"value\":\"$STORAGE\"}}"
```

### Update Usage Stats

```bash
python3 << 'EOF'
import json, os
from datetime import datetime, timezone

config_path = os.path.expanduser('~/.config/claude-skills/managing-confluence/config.json')
with open(config_path) as f:
    config = json.load(f)

template_key = "meetingNotes"
if template_key in config.get('learnedTemplates', {}):
    config['learnedTemplates'][template_key]['usageCount'] += 1
    config['learnedTemplates'][template_key]['lastUsed'] = datetime.now(timezone.utc).isoformat()

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
EOF
```

## Example Interaction

```
User: "Create a new meeting notes page for today's standup"

Claude: I found a learned template "Meeting Notes" that matches your request.
        It has these sections:
        - Attendees
        - Agenda
        - Discussion
        - Action Items

        Would you like me to use this template, or create a blank page?

User: "Use the template"

Claude: [Creates page with template structure]
        Created "Standup 2026-01-23" in TEAM space using Meeting Notes template.
```

## Graceful Degradation

If `learnedTemplates` is empty or missing:
- Create pages with user-specified content only
- Still detect patterns in created pages
- Suggest saving templates after seeing similar structures 3x
