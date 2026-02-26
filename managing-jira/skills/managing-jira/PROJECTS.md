# Multi-Project Support

This document describes how the skill manages multiple Jira projects with tiered access and automatic promotion.

## Overview

Multi-project support provides:
- **Primary projects** - Searched by default, highest priority
- **Secondary projects** - Available but not searched by default
- **Interaction tracking** - Learn which projects you use most
- **Automatic promotion** - Suggest promoting frequently-used projects

## Project Tiers

### Primary Projects

Projects in `primary` are:
- Searched by default in queries using `{primary}` placeholder
- Used for ticket creation when no project specified
- Highest priority in cross-project searches

### Secondary Projects

Projects in `secondary` are:
- Not searched by default
- Available when explicitly mentioned
- Candidates for promotion based on usage

### All Projects

The `all` array contains all known projects (primary + secondary):
- Used for queries with `{all}` placeholder
- Reference for project validation

## Configuration

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

## Interaction Tracking

### What's Tracked

Interactions are counted when you:
- Create a ticket in a project
- Search within a project
- View a ticket from a project
- Comment on a ticket
- Transition a ticket

### How It Works

Each interaction increments the project's count:

```bash
jq '.projects.interactionCounts.PROJ = (.projects.interactionCounts.PROJ // 0) + 1' config.json > tmp && mv tmp config.json
```

### Viewing Stats

```bash
jq '.projects.interactionCounts | to_entries | sort_by(-.value) | .[] | "\(.key): \(.value) interactions"' config.json
```

## Automatic Promotion

### Promotion Threshold

When a secondary project reaches **20 interactions**, Claude suggests promotion:

```
I've noticed you've interacted with TEAM 20 times. Would you like to add it
to your primary projects? This means it will be searched by default.

[Yes, promote to primary] [No, keep as secondary]
```

### Promotion Logic

```bash
# Check for promotion candidates
jq '.projects.secondary as $secondary |
    .projects.interactionCounts |
    to_entries |
    map(select(.key as $k | $secondary | index($k))) |
    map(select(.value >= 20)) |
    .[].key' config.json
```

### Promoting a Project

```bash
jq '.projects.primary += ["TEAM"] | .projects.secondary -= ["TEAM"]' config.json > tmp && mv tmp config.json
```

### Demotion

To demote a project back to secondary:

```bash
jq '.projects.primary -= ["TEAM"] | .projects.secondary += ["TEAM"]' config.json > tmp && mv tmp config.json
```

## Query Placeholders

### Using {primary}

Queries with `{primary}` only search primary projects:

```json
"teamSprint": {
  "jql": "project in ({primary}) AND sprint in openSprints()"
}
```

Becomes: `project in (PROJ)` if PROJ is your only primary project.

### Using {all}

Queries with `{all}` search all known projects:

```json
"crossProjectSearch": {
  "jql": "project in ({all}) AND assignee = currentUser()"
}
```

Becomes: `project in (PROJ, TEAM, DATA)`

### Default Behavior

When no project specified:
- Ticket creation uses first primary project
- Searches default to primary projects
- User can override with explicit project mention

## Adding New Projects

### Discover a New Project

When you interact with an unknown project:

```
I see this ticket is in project INFRA, which isn't in your config.
Would you like to add it?

[Add as primary] [Add as secondary] [Don't add]
```

### Manual Addition

```bash
# Add as secondary
jq '.projects.secondary += ["INFRA"] | .projects.all += ["INFRA"] | .projects.interactionCounts.INFRA = 0' config.json > tmp && mv tmp config.json
```

## Cross-Project Workflows

### Sprint Planning Across Projects

```
User: Show me all my tickets across projects

Claude: [Uses {all} placeholder]
acli jira workitem search --jql "project in (PROJ, TEAM, DATA) AND assignee = currentUser()"
```

### Project-Specific Search

```
User: Search TEAM for open bugs

Claude: [Uses explicit project, increments TEAM interaction count]
acli jira workitem search --jql "project = TEAM AND type = Bug AND status != Done"
```

## Configuration Examples

### Single Project Setup

```json
"projects": {
  "primary": ["PROJ"],
  "secondary": [],
  "all": ["PROJ"],
  "interactionCounts": {}
}
```

### Multi-Team Setup

```json
"projects": {
  "primary": ["PROJ", "TEAM"],
  "secondary": ["TEAM", "DATA", "INFRA"],
  "all": ["PROJ", "TEAM", "TEAM", "DATA", "INFRA"],
  "interactionCounts": {
    "PROJ": 200,
    "TEAM": 150,
    "TEAM": 45,
    "DATA": 20,
    "INFRA": 5
  }
}
```

## Fallback Behavior

If `projects` config is missing:
- Uses `defaultProject` from basic config
- No multi-project features
- No interaction tracking
- Skill functions normally for single project
