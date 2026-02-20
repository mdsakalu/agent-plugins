# Jira REST API Workarounds

When ACLI has limitations (custom fields, certain transitions, Epic creation), use the Jira REST API directly.

## Getting Credentials

Credentials are stored in your config file. See [CONFIG.md](CONFIG.md#api-credentials) for setup.

## Authentication

**Load credentials from config and set up auth header:**

```bash
# Load from config
CONFIG=~/.config/claude-skills/managing-jira/config.json
EMAIL=$(jq -r '.api.email' "$CONFIG")
TOKEN=$(jq -r '.api.token' "$CONFIG")
BASE_URL=$(jq -r '.api.baseUrl' "$CONFIG")
AUTH=$(echo -n "${EMAIL}:${TOKEN}" | base64)

# Use in requests
curl --request GET \
  --url "${BASE_URL}/rest/api/3/myself" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json"
```

**One-liner for quick setup:**

```bash
AUTH=$(jq -r '"\(.api.email):\(.api.token)"' ~/.config/claude-skills/managing-jira/config.json | base64)
BASE_URL=$(jq -r '.api.baseUrl' ~/.config/claude-skills/managing-jira/config.json)
```

## Common Workarounds

### Creating an Epic (with custom required fields)

ACLI Epic creation often fails due to required custom fields (e.g., "Capitalize is required").

1. First, find the custom field ID and allowed values:

```bash
# Get field metadata for a specific field
curl --request GET \
  --url "https://yourcompany.atlassian.net/rest/api/3/field" \
  --header "Authorization: Basic ${AUTH}" | jq '.[] | select(.name == "Capitalize")'

# Get allowed values for a custom field
curl --request GET \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/createmeta/PROJ/issuetypes/10000" \
  --header "Authorization: Basic ${AUTH}" | jq '.fields.customfield_12467'
```

2. Create the Epic with the custom field:

```bash
curl --request POST \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json" \
  --data '{
    "fields": {
      "project": {"key": "PROJ"},
      "issuetype": {"id": "10000"},
      "summary": "Epic summary",
      "customfield_12467": {"id": "15143"},
      "description": {
        "type": "doc",
        "version": 1,
        "content": [
          {
            "type": "paragraph",
            "content": [{"type": "text", "text": "Epic description"}]
          }
        ]
      }
    }
  }'
```

**Note:** Issue type ID `10000` is typically Epic, but verify with:
```bash
curl --request GET \
  --url "https://yourcompany.atlassian.net/rest/api/3/issuetype" \
  --header "Authorization: Basic ${AUTH}" | jq '.[] | select(.name == "Epic")'
```

### Setting Custom Fields

Some fields can't be set via ACLI (e.g., Actual Points, Story Points):

```bash
curl --request PUT \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/PROJ-123" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json" \
  --data '{
    "fields": {
      "customfield_10042": 0
    }
  }'
```

### Setting Parent (Epic) on a Ticket

To set a ticket's parent to an Epic (this is NOT the same as creating an issue link):

```bash
curl --request PUT \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/PROJ-456" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json" \
  --data '{
    "fields": {
      "parent": {"key": "PROJ-123"}
    }
  }'
```

### Setting Sprint on a Ticket

ACLI cannot set sprints. Use the REST API instead.

#### 1. Find the sprint field ID

```bash
curl -s --request GET \
  --url "https://yourcompany.atlassian.net/rest/api/3/field" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json" | jq '.[] | select(.name == "Sprint") | {id, name}'
```

The sprint field is typically `customfield_10020`.

#### 2. Find the board for your project

```bash
# Use ACLI to list boards and find one associated with your project
acli jira board search | grep -i "your-project"
```

#### 3. Find the current sprint

List active sprints for the board and identify the current one by checking dates:

```bash
# List active sprints
acli jira board list-sprints --id BOARD_ID --state active
```

**To determine the "current sprint"**: Look at the `startDate` and `endDate` fields. The current sprint is the active sprint whose date range includes today. If multiple sprints are active, choose the one most relevant to your team/project.

#### 4. Set the sprint on a ticket

```bash
curl -s --request PUT \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/PROJ-123" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json" \
  --data '{
    "fields": {
      "customfield_10020": SPRINT_ID
    }
  }'
```

Replace `SPRINT_ID` with the numeric sprint ID (e.g., `17063`), not the sprint name.

#### 5. Verify the sprint was set

```bash
curl -s --request GET \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/PROJ-123?fields=customfield_10020" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json" | jq '.fields.customfield_10020'
```

### Transitions with Required Fields

When a transition requires custom fields that ACLI can't set:

1. First, set the required field:

```bash
curl --request PUT \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/PROJ-123" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json" \
  --data '{
    "fields": {
      "customfield_10042": 0,
      "assignee": {"accountId": "your-account-id"}
    }
  }'
```

2. Then perform the transition:

```bash
# First, get available transitions
curl --request GET \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/PROJ-123/transitions" \
  --header "Authorization: Basic ${AUTH}" | jq '.transitions[] | {id, name}'

# Then execute the transition
curl --request POST \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/PROJ-123/transitions" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json" \
  --data '{
    "transition": {"id": "181"}
  }'
```

## Finding Field IDs

### List All Fields

```bash
curl --request GET \
  --url "https://yourcompany.atlassian.net/rest/api/3/field" \
  --header "Authorization: Basic ${AUTH}" | jq '.[] | {id, name, custom}'
```

### Get Create Metadata for a Project/Issue Type

```bash
# Get issue types for a project
curl --request GET \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/createmeta/PROJ/issuetypes" \
  --header "Authorization: Basic ${AUTH}"

# Get fields for a specific issue type
curl --request GET \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/createmeta/PROJ/issuetypes/10000" \
  --header "Authorization: Basic ${AUTH}"
```

## Custom Field IDs (From Config)

Custom field IDs are specific to your Jira instance. Store them in your config file:

```bash
# View your configured custom fields
jq '.customFields' ~/.config/claude-skills/managing-jira/config.json
```

Common fields to configure:

| Field | Description | How to Find |
|-------|-------------|-------------|
| `sprint` | Sprint field (ACLI cannot set sprints) | Search for "Sprint" in field list |
| `storyPoints` | Story points estimate | Search for "Story Points" |
| `actualPoints` | Actual points (if used) | Search for "Actual Points" |

See [CONFIG.md](CONFIG.md#custom-fields) for configuration details.

## Tips

1. **Always use jq** to parse JSON responses - they can be large
2. **Test with GET first** before making PUT/POST changes
3. **Check transitions** before attempting them - IDs vary by project/workflow
4. **ADF format** is required for description fields (see [ADF.md](ADF.md))
5. **Account IDs** are required for assignee, not email addresses
