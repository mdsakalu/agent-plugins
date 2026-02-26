# Map Jira Discovery

This document describes the "Map Jira" discovery command that explores your Jira instance to find related projects, people, and generate AI-powered descriptions.

## Overview

The Map Jira command:
- **Spiders from primary projects** to discover connections
- **Finds related projects** through epic links, mentions, and assignees
- **Identifies key people** you interact with
- **Generates AI descriptions** of what each project does
- **Stores discoveries** in config for future reference

## Running Map Jira

**User request:** "Map Jira" / "Discover related projects" / "Who else works with PROJ?"

**Claude performs:**
1. Start from primary projects
2. Explore connections (links, epics, assignees)
3. Discover new projects and people
4. Generate descriptions
5. Update config with findings

## Discovery Algorithm

### Phase 1: Link Exploration

Find projects linked to primary project tickets:

```bash
# Get all links from recent tickets
acli jira workitem search \
  --jql "project = PROJ AND created >= -90d" \
  --fields "key,issuelinks" \
  --json | jq '[.[].issuelinks[].outwardIssue.key, .[].issuelinks[].inwardIssue.key] | map(split("-")[0]) | unique'
```

### Phase 2: Assignee Analysis

Find people who work on your tickets:

```bash
# Get unique assignees from recent tickets
acli jira workitem search \
  --jql "project = PROJ AND updated >= -30d" \
  --fields "assignee,reporter" \
  --json | jq '[.[].assignee, .[].reporter] | map(select(. != null)) | unique'
```

### Phase 3: Epic Connections

Find epics that span multiple projects:

```bash
# Find cross-project epics
acli jira workitem search \
  --jql "type = Epic AND project = PROJ" \
  --fields "key,summary" \
  --json
```

Then check what other projects have children under these epics.

### Phase 4: AI Description Generation

For each discovered project, Claude analyzes:
- Project name and key
- Recent ticket summaries
- Epic themes
- Common labels

Then generates a concise description.

## What Gets Discovered

### Discovered Projects

```json
"discoveredProjects": [
  {
    "key": "INFRA",
    "name": "Infrastructure",
    "discoveredVia": "epic link from PROJ-100",
    "discoveredAt": "2026-01-20T14:00:00Z"
  },
  {
    "key": "AUTH",
    "name": "Authentication Services",
    "discoveredVia": "issue link from PROJ-234",
    "discoveredAt": "2026-01-20T14:00:00Z"
  }
]
```

### Known People

```json
"knownPeople": [
  {
    "email": "user@example.com",
    "displayName": "Jane Doe",
    "projects": ["PROJ", "TEAM"],
    "lastSeen": "2026-01-23T10:30:00Z"
  },
  {
    "email": "user2@example.com",
    "displayName": "John Smith",
    "projects": ["PROJ", "INFRA"],
    "lastSeen": "2026-01-22T15:00:00Z"
  }
]
```

### Project Purposes

AI-generated descriptions:

```json
"projectPurposes": {
  "PROJ": "Core product platform - user management, workflows, and integrations",
  "TEAM": "Team collaboration - shared resources, cross-team features, task coordination",
  "DATA": "Data analytics - reporting dashboards, BI integrations, data pipelines",
  "INFRA": "Infrastructure - cloud resources, deployments, monitoring, security"
}
```

## Discovery Output

After running Map Jira:

```
🗺️ Jira Discovery Results

Discovered Projects (3 new):
- INFRA (Infrastructure) - via epic link from PROJ-100
- AUTH (Authentication Services) - via issue link from PROJ-234
- NOTIFY (Notifications) - via assignee overlap

Key People Found (5):
- Jane Doe (user@example.com) - works on PROJ, TEAM
- John Smith (user2@example.com) - works on PROJ, INFRA
- Sarah Williams (user3@example.com) - works on TEAM, DATA
- Mike Johnson (user4@example.com) - works on PROJ
- Lisa Brown (user5@example.com) - works on AUTH, PROJ

Project Purposes Generated:
- PROJ: Core product platform - user management, workflows...
- INFRA: Infrastructure - cloud resources, deployments...
- AUTH: Authentication services - SSO, OAuth, permissions...

Would you like to add any discovered projects to your config?
[Add INFRA as secondary] [Add AUTH as secondary] [Skip]
```

## Incremental Updates

Running Map Jira again:
- Updates existing project information
- Adds newly discovered projects
- Refreshes people's project associations
- Doesn't duplicate existing entries

## Using Discovery Data

### Find Expert for a Topic

```
User: Who knows about authentication?

Claude: [checks knownPeople and projectPurposes]
Based on my records, John Smith works on both PROJ and AUTH projects.
AUTH handles authentication services. Would you like to check tickets
they've worked on?
```

### Cross-Project Context

```
User: Create a ticket for SSO integration

Claude: [checks projectPurposes]
This sounds like it involves AUTH (Authentication services) and PROJ.
Should I create this in:
- PROJ (your primary project)
- AUTH (handles SSO)
- Link to both?
```

### Finding Related Work

```
User: What projects are related to PROJ?

Claude: Based on discovery:
- TEAM (Team collaboration) - shares assignees, linked tickets
- INFRA (Infrastructure) - epic dependencies
- AUTH (Authentication) - linked for SSO features
- DATA (Data analytics) - reporting integrations
```

## Configuration Updates

### After Discovery

```bash
# Add discovered project
jq '.discoveredProjects += [{
  "key": "INFRA",
  "name": "Infrastructure",
  "discoveredVia": "epic link from PROJ-100",
  "discoveredAt": "2026-01-20T14:00:00Z"
}]' config.json > tmp && mv tmp config.json

# Add known person
jq '.knownPeople += [{
  "email": "user@example.com",
  "displayName": "Jane Doe",
  "projects": ["PROJ", "TEAM"],
  "lastSeen": "2026-01-23T10:30:00Z"
}]' config.json > tmp && mv tmp config.json

# Add project purpose
jq '.projectPurposes.INFRA = "Infrastructure - cloud resources, deployments, monitoring"' config.json > tmp && mv tmp config.json
```

### Promoting Discovered Projects

```bash
# Move from discovered to secondary
jq '.projects.secondary += ["INFRA"] | .projects.all += ["INFRA"]' config.json > tmp && mv tmp config.json
```

## Discovery Limits

To avoid overwhelming the system:
- Maximum 50 tickets analyzed per project
- Maximum 10 projects discovered per run
- Maximum 20 people tracked
- 90-day lookback for link analysis

## Privacy Considerations

Discovery only accesses:
- Projects you have permission to view
- Public ticket information (key, summary, assignee)
- No sensitive fields (descriptions, comments) are stored

All data stays in your local config file.

## Fallback Behavior

If discovery config is empty:
- No cross-project intelligence
- No people suggestions
- Skill functions normally using primary project
- Can run Map Jira anytime to populate
