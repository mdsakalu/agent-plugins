# Personal Metrics & Workload

This document describes workload tracking, WIP limits, and personal metrics features.

## Overview

Personal metrics help you:
- **Track WIP** - Stay aware of concurrent in-progress work
- **Monitor completion** - See tickets completed this week/month
- **Estimate cycle time** - Understand how long different issue types take

## WIP (Work In Progress) Limits

### Purpose

WIP limits help prevent overcommitment by warning when you have too many items in progress simultaneously.

### Configuration

WIP limits are **disabled by default** (set to `null`):

```json
"metrics": {
  "wipLimit": null
}
```

To enable, set a numeric limit:

```bash
jq '.metrics.wipLimit = 3' ~/.config/claude-skills/managing-jira/config.json > tmp && mv tmp ~/.config/claude-skills/managing-jira/config.json
```

### How It Works

When WIP limit is set, Claude:

1. Checks your current in-progress count before certain operations
2. Warns if you're at or above the limit
3. Still allows the action (it's a warning, not a block)

**Triggers:**
- Creating a new ticket and assigning to yourself
- Transitioning a ticket to "In Progress"
- Assigning yourself to a ticket

**Example warning:**
```
⚠️ WIP Warning: You currently have 3 items in progress (limit: 3)

Current in-progress items:
- PROJ-123: Fix OOM error
- PROJ-124: Investigate memory spike
- PROJ-125: Update logging

Consider completing or handing off an item before starting new work.
Proceed anyway? [y/N]
```

### Check WIP Status

**User request:** "What's my workload?" / "Am I over WIP?"

**Claude runs:**
```bash
# Count in-progress items
acli jira workitem search \
  --jql "assignee = currentUser() AND status = 'In Progress'" \
  --fields "key,summary"
```

Then compares against configured `wipLimit`.

## Completion Tracking

### Purpose

Track completed tickets over time to understand productivity patterns.

### Configuration

```json
"metrics": {
  "completionTracking": {
    "thisWeek": ["PROJ-123", "PROJ-124"],
    "thisMonth": ["PROJ-120", "PROJ-121", "PROJ-123", "PROJ-124"]
  }
}
```

### How It Works

When a ticket is transitioned to "Done":

1. Add ticket key to `thisWeek` and `thisMonth` arrays
2. Claude mentions it in the response

**Weekly reset:** At the start of each week (Monday), `thisWeek` is cleared.

**Monthly reset:** At the start of each month, `thisMonth` is cleared.

### Update Completion Tracking

When transitioning to Done:

```bash
# Add to tracking
jq --arg ticket "PROJ-125" '
  .metrics.completionTracking.thisWeek += [$ticket] |
  .metrics.completionTracking.thisMonth += [$ticket]
' config.json > tmp && mv tmp config.json
```

### View Completion Stats

**User request:** "How many tickets did I complete this week?"

**Claude response:**
```
This week: 5 tickets completed
- PROJ-123: Fix OOM error
- PROJ-124: Investigate memory spike
- PROJ-125: Update logging
- PROJ-126: Add retry logic
- PROJ-127: Document API changes

This month: 12 tickets completed
```

## Cycle Time Estimates

### Purpose

Track average time to complete different issue types, helping estimate future work.

### Configuration

```json
"metrics": {
  "cycleTimeEstimates": {
    "Bug": 2.5,
    "Task": 1.5,
    "Story": 5.0,
    "Sub-task": 0.5
  }
}
```

Values are in **days** (average time from In Progress to Done).

### How It Works

Claude uses these estimates to:
- Provide context when viewing tickets ("Stories typically take ~5 days")
- Help with sprint planning ("3 bugs would typically take ~7.5 days")

### Building Estimates

To calculate from historical data:

```bash
# Get recently completed bugs with resolution dates
acli jira workitem search \
  --jql "project = PROJ AND type = Bug AND status = Done AND resolved >= -30d" \
  --fields "key,created,resolutiondate" \
  --json
```

Then calculate average time between created/started and resolved.

### Update Estimates

```bash
jq '.metrics.cycleTimeEstimates.Bug = 2.0' config.json > tmp && mv tmp config.json
```

## Workload View

**User request:** "Show my workload" / "My metrics"

**Claude provides comprehensive view:**

```
📊 Your Workload

WIP Status: 2/3 items in progress ✅
- PROJ-123: Fix OOM error (In Progress, 2 days)
- PROJ-124: Investigate memory spike (In Progress, 1 day)

This Week: 5 tickets completed
This Month: 12 tickets completed

Backlog: 4 items assigned to you
- PROJ-130: Add caching (To Do)
- PROJ-131: Update docs (To Do)
- PROJ-132: Review PR feedback (To Do)
- PROJ-133: Write tests (To Do)

Sprint Progress: 6 days remaining
- Your items: 3 done, 2 in progress, 2 to do
```

## Configuration Reference

Full metrics configuration:

```json
"metrics": {
  "wipLimit": 3,
  "completionTracking": {
    "thisWeek": [],
    "thisMonth": []
  },
  "cycleTimeEstimates": {
    "Bug": 2.5,
    "Task": 1.5,
    "Story": 5.0,
    "Sub-task": 0.5,
    "Epic": 20.0
  }
}
```

## Commands Reference

| Request | Action |
|---------|--------|
| "My workload" | Show WIP status, completion stats, backlog |
| "Am I over WIP?" | Check against WIP limit |
| "How many tickets this week?" | Show weekly completion count |
| "My metrics" | Full workload view |
| "Set WIP limit to 4" | Update config |
| "Disable WIP limit" | Set to null |

## Fallback Behavior

If metrics config is missing:
- No WIP warnings shown
- No completion tracking
- No cycle time estimates
- Skill functions normally otherwise
