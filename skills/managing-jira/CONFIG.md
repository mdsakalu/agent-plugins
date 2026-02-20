# Configuration

This skill uses a config file to store your organization-specific values. The config file is **not** part of the skill and should remain local to your machine.

## Config Location

`~/.config/claude-skills/managing-jira/config.json`

## Setup

Create the config file:

```bash
mkdir -p ~/.config/claude-skills/managing-jira
cat > ~/.config/claude-skills/managing-jira/config.json << 'EOF'
{
  "defaultProject": "PROJ",
  "defaultBoardId": 123,
  "api": {
    "email": "you@company.com",
    "token": "your-api-token-here",
    "baseUrl": "https://yourcompany.atlassian.net"
  },
  "customFields": {
    "sprint": "customfield_10020",
    "storyPoints": "customfield_10021"
  },
  "epicPatterns": [
    {
      "workType": "On-call / reactive / prod support",
      "pattern": "Q[N] '[YY] Reactive Work",
      "example": "Q1 '26 Reactive Work"
    },
    {
      "workType": "Tech debt / stability",
      "pattern": "Tech Modernization & Stability Improvements",
      "example": "Tech Modernization & Stability Improvements"
    }
  ]
}
EOF
```

**Important:** Replace the `api` values with your actual credentials. See [API Credentials](#api-credentials) below.

## Config Values

### API Credentials

The `api` object stores your Jira REST API credentials (used when ACLI has limitations):

| Key | Description | How to Get |
|-----|-------------|------------|
| `email` | Your Atlassian account email | Your login email |
| `token` | Jira API token | [Create at Atlassian](https://id.atlassian.com/manage-profile/security/api-tokens) |
| `baseUrl` | Your Jira instance URL | e.g., `https://yourcompany.atlassian.net` |

**Example:**
```json
"api": {
  "email": "you@company.com",
  "token": "your-api-token-here",
  "baseUrl": "https://yourcompany.atlassian.net"
}
```

**To create an API token:**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Give it a label (e.g., "Claude Code")
4. Copy the token (it won't be shown again)

### Basic Settings

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `defaultProject` | string | Your default Jira project key | `"TEAM"`, `"BACKEND"` |
| `defaultBoardId` | number | Your default board ID for sprint operations | `123` |

### Custom Fields

The `customFields` object maps logical field names to your Jira instance's custom field IDs:

| Key | Description | How to Find |
|-----|-------------|-------------|
| `sprint` | Sprint field ID | See [REST-API.md](REST-API.md#finding-field-ids) |
| `storyPoints` | Story points field | Search fields for "Story Points" |
| `actualPoints` | Actual points (if used) | Search fields for "Actual Points" |
| Any custom field | Your org's custom fields | Use the field discovery commands |

**Example:**
```json
"customFields": {
  "sprint": "customfield_10020",
  "storyPoints": "customfield_10021",
  "actualPoints": "customfield_10042",
  "capitalize": "customfield_12467"
}
```

### Custom Field Values

Some custom fields have specific allowed values. Store these in `capitalizeValues` or similar objects:

```json
"capitalizeValues": {
  "yes": "15142",
  "no": "15143"
}
```

To find allowed values for a custom field, see [REST-API.md](REST-API.md#finding-field-ids).

### Epic Patterns

The `epicPatterns` array defines your organization's epic naming conventions for different work types:

| Field | Description |
|-------|-------------|
| `workType` | Type of work (displayed to user) |
| `pattern` | Naming pattern (with placeholders like `[N]`, `[YY]`) |
| `example` | Concrete example of the pattern |

**Example:**
```json
"epicPatterns": [
  {
    "workType": "On-call / reactive / prod support",
    "pattern": "Q[N] '[YY] Reactive Work",
    "example": "Q1 '26 Reactive Work"
  },
  {
    "workType": "Incident remediation",
    "pattern": "Q[N] [YYYY] Incident Response",
    "example": "Q4 2025 Incident Response"
  },
  {
    "workType": "Tech debt / stability",
    "pattern": "[Descriptive Name]",
    "example": "Tech Modernization & Stability Improvements"
  },
  {
    "workType": "Feature work",
    "pattern": "[Feature Name]",
    "example": "Search Performance Optimization"
  }
]
```

## Finding Your Values

### Project Key

Your project key is the prefix on your ticket IDs (e.g., `TEAM-123` → project key is `TEAM`).

Or list all projects:
```bash
acli jira project list
```

### Board ID

Find your board ID:
```bash
acli jira board search
acli jira board search --name "Your Board Name"
```

## Reading Config

Claude will read your config automatically when needed:

```bash
cat ~/.config/claude-skills/managing-jira/config.json
```

To extract specific values:
```bash
# Get default project
jq -r '.defaultProject' ~/.config/claude-skills/managing-jira/config.json

# Get default board ID
jq -r '.defaultBoardId' ~/.config/claude-skills/managing-jira/config.json

# Get a custom field ID
jq -r '.customFields.sprint' ~/.config/claude-skills/managing-jira/config.json

# List all epic patterns
jq -r '.epicPatterns[] | "\(.workType): \(.example)"' ~/.config/claude-skills/managing-jira/config.json
```

## Config File Privacy

The config file at `~/.config/claude-skills/managing-jira/config.json` is **local to your machine** and is not part of the skill. This allows you to:

- Share the skill publicly without exposing organization-specific details
- Store custom field IDs specific to your Jira instance
- Define epic patterns that match your team's conventions

**Never commit your config.json to version control** if it contains sensitive organizational information.

## Intelligent Features Schema

The config file supports additional fields for intelligent features. These are optional and the skill degrades gracefully when they're missing.

### Saved Queries

Store frequently-used JQL queries with semantic triggers for natural language matching:

```json
"savedQueries": {
  "myInProgress": {
    "jql": "assignee = currentUser() AND status = 'In Progress'",
    "description": "My tickets currently in progress",
    "semanticTriggers": ["what am I working on", "my current work", "in progress", "active tasks"],
    "usageCount": 0,
    "lastUsed": null
  },
  "myBacklog": {
    "jql": "assignee = currentUser() AND status = 'To Do'",
    "description": "My tickets waiting to be started",
    "semanticTriggers": ["my backlog", "what's next", "to do", "pending work", "queued"],
    "usageCount": 0,
    "lastUsed": null
  },
  "myReview": {
    "jql": "assignee = currentUser() AND status = 'In Review'",
    "description": "My tickets in review",
    "semanticTriggers": ["my review", "in review", "waiting for review", "code review"],
    "usageCount": 0,
    "lastUsed": null
  },
  "teamSprint": {
    "jql": "project in ({primary}) AND sprint in openSprints()",
    "description": "All tickets in current sprint",
    "semanticTriggers": ["sprint items", "current sprint", "what's in the sprint", "sprint board"],
    "usageCount": 0,
    "lastUsed": null
  },
  "sprintBacklog": {
    "jql": "project in ({primary}) AND sprint is EMPTY AND status = 'To Do'",
    "description": "Tickets not yet in a sprint",
    "semanticTriggers": ["sprint backlog", "unassigned to sprint", "backlog items", "not in sprint"],
    "usageCount": 0,
    "lastUsed": null
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `jql` | string | The JQL query (supports `{primary}` and `{all}` project placeholders) |
| `description` | string | Human-readable description |
| `semanticTriggers` | string[] | Phrases that should match this query |
| `usageCount` | number | Times this query has been used |
| `lastUsed` | string | ISO timestamp of last use |

See [QUERIES.md](QUERIES.md) for semantic matching details.

### Query Suggestions

Tracks queries that may be worth saving:

```json
"querySuggestions": [
  {
    "jql": "project = PROJ AND labels = 'on-call'",
    "useCount": 3,
    "lastUsed": "2026-01-23T10:30:00Z",
    "suggested": false
  }
]
```

### Sprint Cache

Cache current sprint info to avoid repeated API calls:

```json
"sprintCache": {
  "boardId": 123,
  "currentSprint": {
    "id": 456,
    "name": "Sprint 23",
    "startDate": "2026-01-15",
    "endDate": "2026-01-29"
  },
  "cachedAt": "2026-01-23T10:30:00Z",
  "ttlMinutes": 60
}
```

See [SPRINTS.md](SPRINTS.md) for sprint helper details.

### Personal Metrics

Track workload and performance:

```json
"metrics": {
  "wipLimit": null,
  "completionTracking": {
    "thisWeek": ["PROJ-123", "PROJ-124"],
    "thisMonth": ["PROJ-120", "PROJ-121", "PROJ-123", "PROJ-124"]
  },
  "cycleTimeEstimates": {
    "Bug": 2.5,
    "Task": 1.5,
    "Story": 5.0
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `wipLimit` | number\|null | Max concurrent in-progress items (null = disabled) |
| `completionTracking.thisWeek` | string[] | Tickets completed this week |
| `completionTracking.thisMonth` | string[] | Tickets completed this month |
| `cycleTimeEstimates` | object | Average days to complete by issue type |

See [METRICS.md](METRICS.md) for workload tracking details.

### Learned Epics

Epics learned from user confirmations:

```json
"learnedEpics": {
  "on-call": {
    "epicKey": "PROJ-1330",
    "epicName": "Q1 '26 Reactive Work",
    "keywords": ["on-call", "production", "incident", "alert", "page"],
    "confidence": 95,
    "lastConfirmed": "2026-01-23T10:30:00Z"
  },
  "tech-debt": {
    "epicKey": "PROJ-800",
    "epicName": "Tech Modernization",
    "keywords": ["refactor", "cleanup", "technical debt", "maintenance"],
    "confidence": 85,
    "lastConfirmed": "2026-01-20T14:00:00Z"
  }
}
```

See [EPICS.md](EPICS.md) for epic learning details.

### Multi-Project Configuration

Configure project tiers and track interaction frequency:

```json
"projects": {
  "primary": ["PROJ"],
  "secondary": ["TEAM", "DATA"],
  "all": ["PROJ", "TEAM", "DATA"],
  "interactionCounts": {
    "PROJ": 150,
    "TEAM": 25,
    "DATA": 8
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `primary` | string[] | Projects searched by default |
| `secondary` | string[] | Projects available but not default |
| `all` | string[] | All known projects (primary + secondary) |
| `interactionCounts` | object | How many times each project was used |

See [PROJECTS.md](PROJECTS.md) for multi-project details.

### Discovered Projects and People

Information gathered by the "Map Jira" discovery command:

```json
"discoveredProjects": [
  {
    "key": "INFRA",
    "name": "Infrastructure",
    "discoveredVia": "epic link from PROJ-100",
    "discoveredAt": "2026-01-20T14:00:00Z"
  }
],
"knownPeople": [
  {
    "email": "user@example.com",
    "displayName": "Jane Doe",
    "projects": ["PROJ", "TEAM"],
    "lastSeen": "2026-01-23T10:30:00Z"
  }
],
"projectPurposes": {
  "PROJ": "Core product platform - user management, workflows, integrations",
  "TEAM": "Team collaboration - shared resources, cross-team features",
  "DATA": "Data analytics - reporting, dashboards, BI integrations"
}
```

See [DISCOVERY.md](DISCOVERY.md) for the discovery command details.

### Recent Tickets

Track recently interacted tickets for quick reference:

```json
"recentTickets": [
  {
    "key": "PROJ-123",
    "summary": "Fix OOM error in production",
    "interaction": "created",
    "timestamp": "2026-01-23T10:30:00Z"
  },
  {
    "key": "PROJ-124",
    "summary": "Investigate memory spike",
    "interaction": "commented",
    "timestamp": "2026-01-22T15:45:00Z"
  }
]
```

| Field | Type | Description |
|-------|------|-------------|
| `key` | string | Ticket key |
| `summary` | string | Ticket summary for reference |
| `interaction` | string | Type: "created", "commented", "viewed", "edited", "transitioned" |
| `timestamp` | string | ISO timestamp of interaction |

The list maintains up to 50 recent tickets, sorted by recency. See [RECENT.md](RECENT.md) for details.

## Full Extended Schema

Here's a complete example showing all intelligent feature fields:

```json
{
  "defaultProject": "PROJ",
  "defaultBoardId": 123,
  "api": {
    "email": "you@company.com",
    "token": "your-api-token-here",
    "baseUrl": "https://yourcompany.atlassian.net"
  },
  "customFields": {
    "sprint": "customfield_10020",
    "storyPoints": "customfield_10021"
  },
  "epicPatterns": [
    {
      "workType": "On-call / reactive / prod support",
      "pattern": "Q[N] '[YY] Reactive Work",
      "example": "Q1 '26 Reactive Work"
    }
  ],
  "savedQueries": {
    "myInProgress": {
      "jql": "assignee = currentUser() AND status = 'In Progress'",
      "description": "My tickets currently in progress",
      "semanticTriggers": ["what am I working on", "my current work"],
      "usageCount": 0,
      "lastUsed": null
    }
  },
  "querySuggestions": [],
  "sprintCache": {
    "boardId": 123,
    "currentSprint": { "id": null, "name": null, "startDate": null, "endDate": null },
    "cachedAt": null,
    "ttlMinutes": 60
  },
  "metrics": {
    "wipLimit": null,
    "completionTracking": { "thisWeek": [], "thisMonth": [] },
    "cycleTimeEstimates": {}
  },
  "learnedEpics": {},
  "projects": {
    "primary": ["PROJ"],
    "secondary": ["TEAM", "DATA"],
    "all": ["PROJ", "TEAM", "DATA"],
    "interactionCounts": {}
  },
  "discoveredProjects": [],
  "knownPeople": [],
  "projectPurposes": {},
  "recentTickets": []
}
```

## Graceful Degradation

All intelligent features degrade gracefully when config fields are missing:

| Missing Field | Fallback Behavior |
|---------------|-------------------|
| `savedQueries` | Normal query interpretation (no semantic matching) |
| `sprintCache` | Fetch sprint info fresh each time |
| `metrics` | No WIP warnings or completion tracking |
| `learnedEpics` | Use `epicPatterns` only, always ask for confirmation |
| `projects` | Use `defaultProject` only |
| `discoveredProjects` | No cross-project intelligence |
| `recentTickets` | No recent ticket suggestions |

## Updating Config Programmatically

Use `jq` to update specific fields without overwriting the entire file:

```bash
# Update usage count
jq '.savedQueries.myInProgress.usageCount += 1' config.json > tmp && mv tmp config.json

# Add a learned epic
jq '.learnedEpics["on-call"] = {"epicKey": "PROJ-1330", "epicName": "Q1 Reactive", "confidence": 95}' config.json > tmp && mv tmp config.json

# Add to recent tickets (prepend and limit to 50)
jq '.recentTickets = [{"key": "PROJ-125", "summary": "New ticket", "interaction": "created", "timestamp": "2026-01-23T12:00:00Z"}] + .recentTickets | .recentTickets = .recentTickets[:50]' config.json > tmp && mv tmp config.json

# Increment project interaction count
jq '.projects.interactionCounts.PROJ = (.projects.interactionCounts.PROJ // 0) + 1' config.json > tmp && mv tmp config.json
```
