# Sprint Helpers

This document describes sprint-related helper commands and caching for faster sprint operations.

## Overview

Sprint helpers provide:
- **Cached sprint info** - Avoid repeated API calls for current sprint
- **Sprint summary** - Quick overview of sprint status
- **My sprint items** - Your tickets in the current sprint

## Sprint Cache

### How It Works

Current sprint information is cached in config to avoid repeated API calls:

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

### Cache Logic

When sprint info is needed:

1. Check if cache exists and is valid:
   ```
   cachedAt + ttlMinutes > current time
   ```
2. If valid: Use cached data
3. If invalid or missing: Fetch fresh and update cache

### Refresh Cache Command

To manually refresh the sprint cache:

```bash
# Get current sprint from board
SPRINT_JSON=$(acli jira board list-sprints --board-id 123 --json | jq '[.[] | select(.state == "active")][0]')

# Update config with new cache
jq --argjson sprint "$SPRINT_JSON" '
  .sprintCache.currentSprint = {
    id: $sprint.id,
    name: $sprint.name,
    startDate: $sprint.startDate,
    endDate: $sprint.endDate
  } |
  .sprintCache.cachedAt = (now | todate) |
  .sprintCache.boardId = 123
' config.json > tmp && mv tmp config.json
```

### TTL Configuration

Default TTL is 60 minutes. Adjust based on your sprint cadence:

```bash
jq '.sprintCache.ttlMinutes = 120' config.json > tmp && mv tmp config.json
```

## Sprint Helper Commands

### Current Sprint Detection

**User request:** "What sprint are we in?" / "Current sprint"

**Claude action:**
1. Check cache validity
2. If valid, return cached sprint name and dates
3. If invalid, fetch from API and update cache

```bash
# Check cache
CACHE=$(jq -r '.sprintCache' ~/.config/claude-skills/managing-jira/config.json)
CACHED_AT=$(echo "$CACHE" | jq -r '.cachedAt')
TTL=$(echo "$CACHE" | jq -r '.ttlMinutes')

# If cache is stale, refresh
acli jira board list-sprints --board-id 123 --state active
```

### Sprint Summary

**User request:** "Sprint summary" / "How's the sprint going?"

**Claude provides:**
- Sprint name and dates
- Days remaining
- Items by status (To Do, In Progress, In Review, Done)
- Total story points (if available)
- Burndown indicator

```bash
# Get sprint items grouped by status
acli jira workitem search \
  --jql "sprint = 456" \
  --fields "key,summary,status,assignee" \
  --json | jq 'group_by(.status) | map({status: .[0].status, count: length})'
```

**Example output:**
```
Sprint 23 (Jan 15 - Jan 29) - 6 days remaining

Status Breakdown:
- Done: 8 items
- In Review: 3 items
- In Progress: 5 items
- To Do: 4 items

Total: 20 items | Progress: 40% complete
```

### My Sprint Items

**User request:** "My sprint items" / "What do I have in the sprint?"

**Claude runs:**
```bash
acli jira workitem search \
  --jql "sprint in openSprints() AND assignee = currentUser()" \
  --fields "key,summary,status,priority"
```

### Sprint Backlog

**User request:** "Sprint backlog" / "What's not in a sprint?"

**Claude runs:**
```bash
acli jira workitem search \
  --jql "project in ({primary}) AND sprint is EMPTY AND status = 'To Do'" \
  --fields "key,summary,priority,created"
```

### Add to Sprint

**User request:** "Add PROJ-123 to current sprint"

**Claude action:**
1. Get current sprint ID from cache (or fetch)
2. Use REST API to set sprint field

```bash
# Get sprint ID from cache
SPRINT_ID=$(jq -r '.sprintCache.currentSprint.id' ~/.config/claude-skills/managing-jira/config.json)

# Set sprint via REST API
curl -s --request PUT \
  --url "${BASE_URL}/rest/api/3/issue/PROJ-123" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json" \
  --data "{\"fields\": {\"${SPRINT_FIELD}\": $SPRINT_ID}}"
```

See [REST-API.md](REST-API.md#setting-sprint-on-a-ticket) for full details.

## Sprint Metrics

### Days Remaining

Calculate from cached end date:

```bash
END_DATE=$(jq -r '.sprintCache.currentSprint.endDate' config.json)
DAYS_LEFT=$(( ($(date -d "$END_DATE" +%s) - $(date +%s)) / 86400 ))
echo "$DAYS_LEFT days remaining"
```

### Sprint Progress

```bash
# Count items by status
acli jira workitem search --jql "sprint = $SPRINT_ID" --json | \
  jq '{
    total: length,
    done: [.[] | select(.status == "Done")] | length,
    in_progress: [.[] | select(.status == "In Progress")] | length,
    to_do: [.[] | select(.status == "To Do")] | length
  } | . + {progress_pct: (100 * .done / .total | floor)}'
```

## Configuration

### Required Config

```json
{
  "defaultBoardId": 123,
  "customFields": {
    "sprint": "customfield_10020"
  },
  "sprintCache": {
    "boardId": 123,
    "currentSprint": { "id": null, "name": null, "startDate": null, "endDate": null },
    "cachedAt": null,
    "ttlMinutes": 60
  }
}
```

### Finding Your Board ID

```bash
acli jira board search
acli jira board search --name "Your Board Name"
```

## Fallback Behavior

If sprint cache is missing or stale:
- Sprint info is fetched fresh from the API
- Cache is automatically populated for next request
- No user-visible difference in functionality
