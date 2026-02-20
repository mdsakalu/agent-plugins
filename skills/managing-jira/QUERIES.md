# Saved Queries & Semantic Matching

This document describes how to use and manage intelligent saved queries that match natural language requests to JQL.

## Overview

Instead of remembering exact JQL syntax, you can ask questions in natural language:
- "What am I working on?" → matches `myInProgress` query
- "Show me the sprint backlog" → matches `sprintBacklog` query
- "What's in review?" → matches `myReview` query

## How Semantic Matching Works

### 1. Query Resolution

When you make a request, Claude:

1. Reads `savedQueries` from config
2. Compares your request against each query's:
   - `semanticTriggers` - explicit phrase matches
   - `description` - semantic similarity
3. Calculates confidence score (0-100%)
4. Takes action based on confidence:

| Confidence | Action |
|------------|--------|
| ≥90% | Execute query directly |
| 50-89% | Confirm with user before executing |
| <50% | Ask for clarification or interpret as new query |

### 2. After Execution

When a saved query is used:
- `usageCount` is incremented
- `lastUsed` is updated to current timestamp
- Higher usage queries get preference in ambiguous matches

## Default Saved Queries

These queries come pre-configured (add them to your config):

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

## JQL Placeholders

Queries support these placeholders that get replaced at runtime:

| Placeholder | Replaced With | Example |
|-------------|---------------|---------|
| `{primary}` | Primary projects | `PROJ` or `PROJ, TEAM` |
| `{all}` | All projects | `PROJ, TEAM, DATA` |
| `{board}` | Default board ID | `123` |

Example: `project in ({primary})` becomes `project in (PROJ)` if PROJ is your primary project.

## Query Learning

### Auto-Learning New Queries

When you run the same ad-hoc JQL query 3+ times:

1. The query is added to `querySuggestions` with usage tracking
2. After 3 uses, Claude suggests saving it
3. If you confirm, it's added to `savedQueries` with semantic triggers you provide

Example flow:

```
User: Search for tickets with label 'on-call' assigned to me
Claude: [runs JQL]

... later ...

User: Find my on-call tickets
Claude: [runs same JQL - 3rd time]

Claude: "I've noticed you run this query often. Would you like to save it?
         JQL: assignee = currentUser() AND labels = 'on-call'
         Suggested name: myOnCall
         What phrases should trigger this query?"

User: "my on-call", "on-call tickets", "pager duty"

Claude: [saves to config]
```

### Tracking Suggestions

Potential queries are tracked before promotion:

```json
"querySuggestions": [
  {
    "jql": "project = PROJ AND labels = 'on-call' AND assignee = currentUser()",
    "useCount": 3,
    "lastUsed": "2026-01-23T10:30:00Z",
    "suggested": false
  }
]
```

## Managing Saved Queries

### Add a New Query

Use jq to add queries:

```bash
jq '.savedQueries.myOnCall = {
  "jql": "assignee = currentUser() AND labels = '\''on-call'\''",
  "description": "My on-call tickets",
  "semanticTriggers": ["my on-call", "on-call tickets", "pager duty"],
  "usageCount": 0,
  "lastUsed": null
}' ~/.config/claude-skills/managing-jira/config.json > tmp && mv tmp ~/.config/claude-skills/managing-jira/config.json
```

### Update Semantic Triggers

Add more trigger phrases:

```bash
jq '.savedQueries.myInProgress.semanticTriggers += ["currently doing", "my tasks"]' config.json > tmp && mv tmp config.json
```

### Remove a Query

```bash
jq 'del(.savedQueries.oldQuery)' config.json > tmp && mv tmp config.json
```

### View Usage Stats

```bash
jq '.savedQueries | to_entries | sort_by(-.value.usageCount) | .[:5] | .[] | "\(.key): \(.value.usageCount) uses"' config.json
```

## Best Practices

### Writing Good Semantic Triggers

**Do:**
- Use common variations: "in progress", "currently working", "active"
- Include shortened forms: "WIP", "TODO"
- Add question forms: "what am I working on"

**Don't:**
- Make triggers too similar across queries (causes ambiguity)
- Use very long phrases (less likely to match)
- Use technical JQL terms as triggers

### Organizing Queries

Suggested naming convention:
- `my*` - Personal queries (myInProgress, myBacklog)
- `team*` - Team-wide queries (teamSprint, teamBlocked)
- `sprint*` - Sprint-related queries (sprintBacklog, sprintDone)
- `project*` - Project-specific queries (projectBugs, projectEpics)

## Fallback Behavior

If no saved query matches with sufficient confidence, Claude:

1. Interprets the request as a new JQL query
2. Runs the query
3. Tracks it in `querySuggestions` for potential future saving

This ensures the skill works normally even without saved queries configured.
