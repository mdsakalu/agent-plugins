# Smart Epic Assignment

This document describes how the skill learns epic assignments from your confirmations and improves suggestions over time.

## Overview

Smart epic assignment:
- **Matches keywords** to learned epics based on work type
- **Asks for confirmation** when confidence is below 90%
- **Learns from confirmations** to improve future suggestions
- **Combines with epicPatterns** for comprehensive matching

## How It Works

### 1. Keyword Matching

When creating a ticket, Claude analyzes:
- Summary text
- Description content
- Labels
- Work type indicators

These are matched against `learnedEpics` keywords:

```json
"learnedEpics": {
  "on-call": {
    "epicKey": "PROJ-1330",
    "epicName": "Q1 '26 Reactive Work",
    "keywords": ["on-call", "production", "incident", "alert", "page", "outage"],
    "confidence": 95,
    "lastConfirmed": "2026-01-23T10:30:00Z"
  },
  "tech-debt": {
    "epicKey": "PROJ-800",
    "epicName": "Tech Modernization",
    "keywords": ["refactor", "cleanup", "technical debt", "maintenance", "upgrade"],
    "confidence": 85,
    "lastConfirmed": "2026-01-20T14:00:00Z"
  }
}
```

### 2. Confidence Calculation

Confidence is calculated based on:

| Factor | Weight |
|--------|--------|
| Keyword matches | +20 per match (max 60) |
| Recent confirmation | +20 if confirmed in last 7 days |
| High usage | +10 if epic used 5+ times |
| epicPatterns match | +15 if also matches pattern |

**Maximum confidence:** 100%

### 3. Action Based on Confidence

| Confidence | Action |
|------------|--------|
| ≥90% | Assign epic directly, mention in response |
| 70-89% | Suggest epic, use AskUserQuestion to confirm |
| 50-69% | Present multiple options, ask user to choose |
| <50% | Fall back to epic search workflow |

### 4. Learning from Confirmations

When user confirms an epic assignment:

1. Add/update entry in `learnedEpics`
2. Add any new keywords from the ticket
3. Set confidence to 95%
4. Update `lastConfirmed` timestamp

## Learning Triggers

### Creating a Ticket

```
User: Create a ticket for the production OOM error I'm investigating

Claude: I'll create this ticket. Based on the keywords "production" and "OOM",
        this appears to be reactive/on-call work.

        Should I assign to epic PROJ-1330 "Q1 '26 Reactive Work"?
        [Yes] [No, different epic] [No epic]

User: Yes

Claude: [Creates ticket, assigns epic, updates learnedEpics]
```

### Confirming a Suggested Epic

When user confirms, Claude updates config:

```bash
jq --arg key "on-call" --arg epicKey "PROJ-1330" --arg epicName "Q1 '\''26 Reactive Work" '
  .learnedEpics[$key] = {
    epicKey: $epicKey,
    epicName: $epicName,
    keywords: (.learnedEpics[$key].keywords // []) + ["production", "OOM"],
    confidence: 95,
    lastConfirmed: (now | todate)
  } | .learnedEpics[$key].keywords |= unique
' config.json > tmp && mv tmp config.json
```

### Correcting a Suggestion

When user chooses a different epic:

1. Reduce confidence of suggested epic by 10%
2. Learn the correct epic association
3. Add keywords from this ticket to correct epic

```bash
# Reduce confidence of wrong suggestion
jq '.learnedEpics["on-call"].confidence = ([.learnedEpics["on-call"].confidence - 10, 50] | max)' config.json > tmp && mv tmp config.json

# Learn correct association
jq --arg epicKey "PROJ-900" '
  .learnedEpics["feature-x"] = {
    epicKey: $epicKey,
    keywords: ["production", "OOM"],
    confidence: 95
  }
' config.json > tmp && mv tmp config.json
```

## Integration with epicPatterns

`learnedEpics` works alongside static `epicPatterns`:

1. **epicPatterns** - Template-based matching (quarterly patterns, naming conventions)
2. **learnedEpics** - Keyword-based matching (learned from confirmations)

Both are consulted. If both match with high confidence, `learnedEpics` takes precedence (it's more specific).

### Example Combined Flow

```
User: Create a ticket for Q1 on-call dashboard improvements

Claude analysis:
1. learnedEpics["on-call"] matches "on-call" → PROJ-1330 (confidence: 95)
2. epicPatterns["On-call / reactive"] matches "on-call" → suggests Q1 '26 Reactive
3. Both point to same epic → very high confidence

Claude: Creating ticket under epic PROJ-1330 "Q1 '26 Reactive Work"
```

## Managing Learned Epics

### View Learned Epics

```bash
jq '.learnedEpics | to_entries | .[] | "\(.key): \(.value.epicName) (\(.value.confidence)% confidence)"' config.json
```

### Add Keywords to Existing Epic

```bash
jq '.learnedEpics["on-call"].keywords += ["pagerduty", "alert"]' config.json > tmp && mv tmp config.json
```

### Remove a Learned Epic

```bash
jq 'del(.learnedEpics["outdated-epic"])' config.json > tmp && mv tmp config.json
```

### Reset Confidence

```bash
jq '.learnedEpics["on-call"].confidence = 50' config.json > tmp && mv tmp config.json
```

## Confidence Decay

To prevent stale associations:
- Confidence decreases by 5% if not confirmed for 30 days
- Epics with confidence <30% are ignored in matching
- Quarterly epics should be updated when new quarter begins

### Updating for New Quarter

When a new quarter starts:

```bash
# Update the reactive epic for new quarter
jq '.learnedEpics["on-call"].epicKey = "PROJ-1500" |
    .learnedEpics["on-call"].epicName = "Q2 '\''26 Reactive Work" |
    .learnedEpics["on-call"].confidence = 90' config.json > tmp && mv tmp config.json
```

## Example Learned Epics Config

```json
"learnedEpics": {
  "on-call": {
    "epicKey": "PROJ-1330",
    "epicName": "Q1 '26 Reactive Work",
    "keywords": ["on-call", "production", "incident", "alert", "page", "outage", "OOM", "crash"],
    "confidence": 95,
    "lastConfirmed": "2026-01-23T10:30:00Z"
  },
  "tech-debt": {
    "epicKey": "PROJ-800",
    "epicName": "Tech Modernization",
    "keywords": ["refactor", "cleanup", "technical debt", "maintenance", "upgrade", "deprecation"],
    "confidence": 85,
    "lastConfirmed": "2026-01-20T14:00:00Z"
  },
  "observability": {
    "epicKey": "PROJ-950",
    "epicName": "Observability Improvements",
    "keywords": ["logging", "metrics", "tracing", "monitoring", "dashboard", "alert"],
    "confidence": 80,
    "lastConfirmed": "2026-01-18T09:00:00Z"
  }
}
```

## Fallback Behavior

If `learnedEpics` is empty or missing:
- Fall back to `epicPatterns` matching
- Fall back to epic search workflow (see SKILL.md "Choosing the Right Epic")
- Always ask for confirmation on first use
