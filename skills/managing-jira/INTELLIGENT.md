# Intelligent Features

The skill includes learning capabilities that improve over time. All learned data is stored in your config file and persists across sessions.

## Saved Queries with Semantic Matching

Instead of remembering exact JQL syntax, use natural language:

| You say | Matched query | JQL executed |
|---------|---------------|--------------|
| "What am I working on?" | myInProgress | `assignee = currentUser() AND status = 'In Progress'` |
| "Show my backlog" | myBacklog | `assignee = currentUser() AND status = 'To Do'` |
| "Current sprint items" | teamSprint | `project in ({primary}) AND sprint in openSprints()` |

**How it works:**
1. Claude matches your request against saved queries' semantic triggers
2. High confidence (≥90%): Execute directly
3. Medium confidence: Confirm before executing
4. Low confidence: Ask for clarification

**Learning:** After running the same ad-hoc query 3+ times, Claude suggests saving it with semantic triggers.

See [QUERIES.md](QUERIES.md) for full details.

## Sprint Helpers

Quick access to sprint information with caching:

**Commands:**
- "What sprint are we in?" - Current sprint with cache (60-min TTL)
- "Sprint summary" - Items by status, days remaining, progress
- "My sprint items" - Your tickets in current sprint
- "Add PROJ-123 to sprint" - Add ticket to current sprint

**Cache:** Sprint info is cached to avoid repeated API calls. Cache refreshes automatically after TTL.

See [SPRINTS.md](SPRINTS.md) for details.

## Personal Metrics & Workload

Track your work patterns:

**WIP Limits (optional):**
- Set a limit on concurrent in-progress items
- Get warnings when approaching or exceeding limit
- Disabled by default (set `wipLimit: null`)

**Completion Tracking:**
- Tracks tickets completed this week/month
- "How many tickets did I complete this week?"

**Cycle Time Estimates:**
- Learns average completion time by issue type
- Helps estimate future work

See [METRICS.md](METRICS.md) for configuration.

## Smart Epic Assignment

Claude learns which epics to use based on your confirmations:

**Flow:**
1. When creating a ticket, Claude analyzes keywords
2. Matches against learned epic associations
3. High confidence (≥90%): Assigns directly
4. Lower confidence: Asks "Should I assign to [Epic Name]?"
5. Your confirmation trains future suggestions

**Example learned association:**
```json
"on-call": {
  "epicKey": "PROJ-1330",
  "keywords": ["on-call", "production", "incident", "alert", "OOM"],
  "confidence": 95
}
```

See [EPICS.md](EPICS.md) for learning details.

## Multi-Project Support

Work across multiple Jira projects with tiered access:

**Project Tiers:**
- **Primary** - Searched by default, used for ticket creation
- **Secondary** - Available but not default

**Interaction Tracking:**
- Counts how often you interact with each project
- After 20 interactions with a secondary project, suggests promotion

**Query Placeholders:**
- `{primary}` - Replaced with primary projects
- `{all}` - Replaced with all known projects

See [PROJECTS.md](PROJECTS.md) for configuration.

## Map Jira Discovery

Explore your Jira instance to find related projects and people:

**Command:** "Map Jira" / "Discover related projects"

**What it finds:**
- Projects linked to your primary projects
- People who work on similar tickets
- Cross-project epic relationships

**What it generates:**
- AI descriptions of each project's purpose
- List of known collaborators with their projects

**Example output:**
```
Discovered: INFRA (Infrastructure) - via epic link from PROJ-100
Known: Jane Doe works on PROJ, TEAM
Purpose: INFRA handles cloud resources, deployments, monitoring
```

See [DISCOVERY.md](DISCOVERY.md) for the discovery algorithm.

## Recent Tickets Memory

Track tickets you've recently interacted with for quick reference:

**Tracked interactions:** Created, commented, viewed, edited, transitioned

**Use cases:**
- "What was that ticket from yesterday?" - Fuzzy lookup
- "The OOM ticket" - Search by keyword in summary
- "My recent tickets" - List recent activity

**Storage:** Last 50 interactions, sorted by recency. Not a cache - persists permanently.

See [RECENT.md](RECENT.md) for details.

## Feature Summary

| Feature | Purpose | Details |
|---------|---------|---------|
| Saved Queries | Natural language → JQL | [QUERIES.md](QUERIES.md) |
| Sprint Helpers | Cached sprint info | [SPRINTS.md](SPRINTS.md) |
| Personal Metrics | WIP limits, tracking | [METRICS.md](METRICS.md) |
| Smart Epics | Learn epic assignments | [EPICS.md](EPICS.md) |
| Multi-Project | Tiered project access | [PROJECTS.md](PROJECTS.md) |
| Map Jira | Discover projects/people | [DISCOVERY.md](DISCOVERY.md) |
| Recent Tickets | Interaction memory | [RECENT.md](RECENT.md) |
