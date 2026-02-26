# Recent Tickets Memory

This document describes how the skill tracks recently interacted tickets for quick reference.

## Overview

Recent tickets memory:
- **Tracks your interactions** - Created, commented, viewed, edited, transitioned
- **Persists across sessions** - Not a cache, a permanent record
- **Enables quick lookups** - "What was that ticket from yesterday?"
- **Maintains recency bias** - Most recent interactions first

## What Gets Tracked

### Interaction Types

| Interaction | Tracked When |
|-------------|--------------|
| `created` | You create a new ticket |
| `commented` | You add a comment to a ticket |
| `viewed` | You explicitly view/read a ticket |
| `edited` | You modify ticket fields |
| `transitioned` | You change ticket status |

### Data Stored

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
  },
  {
    "key": "PROJ-120",
    "summary": "Add retry logic to API calls",
    "interaction": "transitioned",
    "timestamp": "2026-01-22T09:00:00Z"
  }
]
```

## How It Works

### Adding to Recent

After any ticket interaction:

```bash
jq --arg key "PROJ-125" --arg summary "New ticket summary" --arg interaction "created" '
  .recentTickets = [{
    key: $key,
    summary: $summary,
    interaction: $interaction,
    timestamp: (now | todate)
  }] + .recentTickets |
  .recentTickets = .recentTickets[:50]
' config.json > tmp && mv tmp config.json
```

### Deduplication

If the same ticket is interacted with again:
1. Remove old entry
2. Add new entry at the top
3. This keeps the ticket at "most recent" position

```bash
jq --arg key "PROJ-123" --arg interaction "commented" '
  .recentTickets = (.recentTickets | map(select(.key != $key))) |
  .recentTickets = [{
    key: $key,
    summary: (.recentTickets[] | select(.key == $key) | .summary) // "Unknown",
    interaction: $interaction,
    timestamp: (now | todate)
  }] + .recentTickets |
  .recentTickets = .recentTickets[:50]
' config.json > tmp && mv tmp config.json
```

### List Size Limit

Maximum 50 tickets are kept. Oldest entries are automatically removed when limit is exceeded.

## Querying Recent Tickets

### "What was that ticket?"

**User request:** "What was that ticket I worked on yesterday?"

**Claude action:**
1. Read `recentTickets` from config
2. Filter by timestamp (yesterday)
3. Present matches

```bash
# Get tickets from yesterday
jq '[.recentTickets[] | select(.timestamp | startswith("2026-01-22"))]' config.json
```

### "My recent tickets"

**User request:** "Show my recent tickets" / "What have I been working on?"

**Claude response:**
```
Your recent ticket interactions:

Today:
- PROJ-123: Fix OOM error in production (created)
- PROJ-124: Investigate memory spike (commented)

Yesterday:
- PROJ-120: Add retry logic to API calls (transitioned to Done)
- PROJ-118: Update logging format (edited)

This week:
- PROJ-115: Refactor auth module (commented)
- PROJ-112: Add unit tests (created)
```

### "The OOM ticket"

**User request:** "What was the OOM ticket?"

**Claude action:**
1. Search summaries in `recentTickets` for "OOM"
2. Return match: PROJ-123

```bash
jq '[.recentTickets[] | select(.summary | test("OOM"; "i"))]' config.json
```

## Quick Actions on Recent

### Resume Work

```
User: Continue on the memory spike ticket

Claude: [finds PROJ-124 in recent]
You last commented on PROJ-124 "Investigate memory spike" yesterday.
Let me get the current status...
```

### Reference in New Ticket

```
User: Create a follow-up ticket for PROJ-123

Claude: [finds PROJ-123 in recent]
Creating follow-up for PROJ-123 "Fix OOM error in production"...
```

## Filtering Recent Tickets

### By Interaction Type

```bash
# Only tickets you created
jq '[.recentTickets[] | select(.interaction == "created")]' config.json

# Only tickets you commented on
jq '[.recentTickets[] | select(.interaction == "commented")]' config.json
```

### By Time Period

```bash
# Last 24 hours
jq --arg cutoff "$(date -d '24 hours ago' -Iseconds)" \
  '[.recentTickets[] | select(.timestamp > $cutoff)]' config.json

# This week (assuming ISO week)
jq '[.recentTickets[] | select(.timestamp | startswith("2026-01-"))]' config.json
```

### By Project

```bash
# Only PROJ tickets
jq '[.recentTickets[] | select(.key | startswith("PROJ-"))]' config.json
```

## Integration with Other Features

### Sprint Planning

Recent tickets inform sprint context:
```
You recently worked on PROJ-123 and PROJ-124 (both memory-related).
These are in sprint and in progress. Want to focus on those?
```

### Epic Assignment

Recent tickets help with epic matching:
```
Your recent ticket PROJ-123 was assigned to "Q1 Reactive Work" epic.
This new ticket seems similar. Use the same epic?
```

### Workload View

Recent tickets contribute to workload visualization:
```
Your workload includes 3 tickets you touched today:
- PROJ-123 (created, in progress)
- PROJ-124 (commented, in review)
- PROJ-125 (transitioned to done)
```

## Maintenance

### Clear Old Entries

To remove entries older than 30 days:

```bash
jq --arg cutoff "$(date -d '30 days ago' -Iseconds)" \
  '.recentTickets = [.recentTickets[] | select(.timestamp > $cutoff)]' config.json > tmp && mv tmp config.json
```

### Clear All

```bash
jq '.recentTickets = []' config.json > tmp && mv tmp config.json
```

### Update Summary

If a ticket's summary changes:

```bash
jq --arg key "PROJ-123" --arg summary "Updated summary text" \
  '.recentTickets = [.recentTickets[] | if .key == $key then .summary = $summary else . end]' config.json > tmp && mv tmp config.json
```

## Why Not a Cache?

Recent tickets is intentionally **not a cache**:

| Cache | Recent Memory |
|-------|---------------|
| Stores ticket data to avoid API calls | Stores interaction history |
| Invalidated after TTL | Persists indefinitely (up to limit) |
| Full ticket details | Just key, summary, interaction type |
| Performance optimization | User convenience feature |

The recent tickets list is a **memory of your activity**, not a performance cache.

## Fallback Behavior

If `recentTickets` is missing or empty:
- No "what was that ticket" suggestions
- No recent activity context
- Skill functions normally otherwise
- List builds naturally as you work
