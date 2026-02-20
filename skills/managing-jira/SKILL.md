---
name: managing-jira
description: Uses Atlassian CLI (ACLI) to interact with Jira - create, search, view, edit tickets/issues, manage projects, boards, sprints, and more. Invoke this skill when the user asks about Jira tickets, issues, sprints, or wants to interact with their Jira instance.
allowed-tools: Bash, Read
license: MIT
metadata:
  version: 3.0.0
  updated: 2026-01-23
  spec-version: agentskills.io/2026
compatibility: |
  Requires: Atlassian CLI (acli) installed and authenticated.
  Install: brew tap atlassian/homebrew-acli && brew install acli
  Claude Code only - requires Bash execution.
---

# Managing Jira

## Before You Start

### 1. Check Installation

**First, verify ACLI is installed:**

```bash
acli --version
```

If command not found, help the user install it. See [INSTALL.md](INSTALL.md) for instructions.

**Quick install (macOS with Homebrew):**
```bash
brew tap atlassian/homebrew-acli && brew install acli
```

### 2. Check Authentication

**Verify authentication:**

```bash
acli jira auth status
```

If not authenticated, help the user log in:

```bash
acli jira auth login
```

This opens a browser for Jira authentication. Do not proceed with other commands until authentication succeeds.

### 3. Read User Config

**Before using project or board commands**, read the user's config:

```bash
cat ~/.config/claude-skills/managing-jira/config.json
```

This provides:
- `defaultProject` and `defaultBoardId` - Use instead of placeholder "PROJ"
- `api.email`, `api.token`, `api.baseUrl` - For REST API operations (see [REST-API.md](REST-API.md))
- `customFields` - Organization-specific Jira field IDs
- `epicPatterns` - Team's epic naming conventions

If config doesn't exist, ask the user for their project key and board ID, or see [CONFIG.md](CONFIG.md) for setup instructions.

## Quick Start

```bash
# Find my open tickets
acli jira workitem search --jql "assignee = currentUser() AND status != Done"

# Create a task
acli jira workitem create --project "PROJ" --type "Task" --summary "Task title" --assignee "@me"

# View a ticket
acli jira workitem view KEY-123

# Transition to In Progress
acli jira workitem transition --key "KEY-123" --status "In Progress"
```

## Example Output

Successful search:
```
KEY        SUMMARY                          STATUS
PROJ-123   Fix login timeout                In Progress
PROJ-124   Add dark mode toggle             To Do
```

Successful create:
```
Created: PROJ-125 "New feature request"
URL: https://yourcompany.atlassian.net/browse/PROJ-125
```

Successful view:
```
Key:         PROJ-123
Summary:     Fix login timeout
Status:      In Progress
Assignee:    john@example.com
Created:     2026-01-15
Description: Users experiencing timeout on login page...
```

## Work Item Operations

**CRITICAL: Jira uses ADF (Atlassian Document Format), NOT Wiki markup or Markdown.**

Do NOT use wiki syntax like:
- `h2. Heading` - renders as literal text
- `{code:java}...{code}` - renders as literal text
- `||Header||` tables - renders as literal text
- `*bold*` or `_italic_` - renders as literal text

For ANY ticket with formatted descriptions (headings, code blocks, tables, lists), you MUST:
1. Read [ADF.md](ADF.md) first
2. Use `--from-json` with proper ADF JSON structure
3. Never use `--description` with markup syntax

### Create
```bash
# Basic
acli jira workitem create --summary "Title" --project "PROJ" --type "Task"

# Full details
acli jira workitem create --project "PROJ" --type "Bug" \
  --summary "Bug title" --description "Description" --assignee "@me" --label "urgent"

# With parent (subtask)
acli jira workitem create --project "PROJ" --type "Sub-task" --summary "Subtask" --parent "PROJ-123"

# From JSON (for rich formatting)
acli jira workitem create --from-json workitem.json
```

**IMPORTANT**: The `--description` flag only supports PLAIN TEXT with NO line breaks.
Newlines in your description become literal `\n` characters, not line breaks - the entire
description renders as a single paragraph. For any structure (line breaks, headings,
code blocks, lists, tables), you MUST use `--from-json` with ADF format.
See [ADF.md](ADF.md) for the JSON structure.

**Types:** Epic, Story, Task, Bug, Sub-task (varies by project)

### Search
```bash
# JQL search
acli jira workitem search --jql "project = PROJ AND status = 'To Do'"

# Output formats
acli jira workitem search --jql "..." --fields "key,summary,status"
acli jira workitem search --jql "..." --json
acli jira workitem search --jql "..." --csv

# Using saved filter
acli jira workitem search --filter 10001

# Pagination
acli jira workitem search --jql "..." --limit 50
acli jira workitem search --jql "..." --paginate
```

### View
```bash
acli jira workitem view KEY-123
acli jira workitem view KEY-123 --json
acli jira workitem view KEY-123 --fields "summary,description,comment"
acli jira workitem view KEY-123 --web  # Open in browser
```

### Edit
```bash
# Single field
acli jira workitem edit --key "KEY-123" --summary "New summary"
acli jira workitem edit --key "KEY-123" --assignee "@me"
acli jira workitem edit --key "KEY-123" --labels "bug,urgent"

# Bulk edit by JQL
acli jira workitem edit --jql "project = PROJ AND status = 'To Do'" --assignee "@me" --yes

# Remove assignee
acli jira workitem edit --key "KEY-123" --remove-assignee

# Edit with rich formatting (ADF) - see ADF.md for details
acli jira workitem edit --from-json edit.json --yes
```

**Note:** `--key` and `--from-json` are mutually exclusive. For ADF edits, specify the issue key inside the JSON file using `"issues": ["KEY-123"]`. See [ADF.md](ADF.md) for the full format.

### Transition
```bash
acli jira workitem transition --key "KEY-123" --status "In Progress"
acli jira workitem transition --key "KEY-123" --status "Done"

# Bulk transition
acli jira workitem transition --jql "assignee = currentUser()" --status "In Progress" --yes
```

### Other Operations
```bash
acli jira workitem assign --key "KEY-123" --assignee "@me"
acli jira workitem delete --key "KEY-123"
acli jira workitem clone --key "KEY-123"
acli jira workitem archive --key "KEY-123"
```

## Links

```bash
# Create a link between issues
acli jira workitem link create --out "KEY-123" --in "KEY-456" --type "LINK_TYPE"

# List available link types (ALWAYS check this first - names are often verbose)
acli jira workitem link type

# Note: Link types require the FULL name from the list above
# Example: --type "01 Relates To (Named 01 to be at top of list for generic linking)"
```

## Comments
```bash
acli jira workitem comment create --key "KEY-123" --body "Comment text"
acli jira workitem comment list --key "KEY-123"
acli jira workitem comment update --key "KEY-123" --id "12345" --body "Updated"
acli jira workitem comment delete --key "KEY-123" --id "12345"
```

## Projects
```bash
acli jira project list
acli jira project view PROJ
acli jira project create --name "Project Name" --key "PROJ" --type "software"
```

## Boards and Sprints
```bash
# Boards
acli jira board search
acli jira board get --board-id 123
acli jira board list-sprints --board-id 123

# Sprints
acli jira sprint list-workitems --sprint-id 456
```

## Filters
```bash
acli jira filter list
acli jira filter list --favourite
acli jira filter get --filter-id 10001
```

## Common Workflows

### Create Bug with Full Details
```bash
acli jira workitem create --project "PROJ" --type "Bug" \
  --summary "Login button not responding on mobile" \
  --description "Steps: 1. Open app 2. Click login..." \
  --assignee "@me" --label "mobile,urgent"
```

### Find My Open Tickets
```bash
acli jira workitem search \
  --jql "assignee = currentUser() AND status != Done" \
  --fields "key,summary,status,priority"
```

### Sprint Planning Queries
```bash
# Current sprint items
acli jira workitem search --jql "project = PROJ AND sprint in openSprints()"

# Backlog (unassigned, no sprint)
acli jira workitem search --jql "project = PROJ AND sprint is EMPTY AND assignee is EMPTY"
```

### Bulk Reassign Tickets
```bash
acli jira workitem edit \
  --jql "project = PROJ AND assignee = 'old@email.com' AND status != Done" \
  --assignee "new@email.com" --yes
```

### View Ticket with Comments
```bash
acli jira workitem view KEY-123 --fields "summary,status,assignee,description,comment"
```

## Choosing the Right Epic

When creating tickets, assign them to an appropriate epic. Follow this process:

### 1. Identify the work type

| Work Type | Epic Pattern | Example |
|-----------|--------------|---------|
| On-call / reactive / prod support | Quarterly reactive epic | "Q1 '26 Reactive Work" |
| Incident remediation | Incident epic | "Q4 2025 Incident Response" |
| Tech debt / stability | Catch-all tech epic | "Tech Modernization & Stability Improvements" |
| Feature work | Feature-specific epic | "Search Performance Optimization" |

### 2. Search for candidate epics

```bash
# Search for reactive/on-call epics (use current quarter)
acli jira workitem search --jql "project = PROJ AND issuetype = Epic AND summary ~ 'Reactive' AND status NOT IN (Done, Closed)" --fields "key,summary,status"

# Search for epics by keyword
acli jira workitem search --jql "project = PROJ AND issuetype = Epic AND (summary ~ 'keyword1' OR summary ~ 'keyword2') AND status NOT IN (Done, Closed)" --fields "key,summary,status"
```

### 3. Look at similar past tickets

Find tickets similar to yours and check what epic they used:

```bash
# Search for similar tickets
acli jira workitem search --jql "project = PROJ AND summary ~ 'OOM' AND parent IS NOT EMPTY" --fields "key,summary,parent"
```

### 4. Verify the epic is appropriate

```bash
# View epic details
acli jira workitem view EPIC-KEY --fields "summary,description,status"

# Check what other tickets are under this epic
acli jira workitem search --jql "parent = EPIC-KEY" --fields "key,summary,status"
```

### 5. Confirm or document your choice

Before assigning, either:

**Option A: Confirm with the user first**
- Present the epic you found and why it seems appropriate
- Ask: "Should I assign this to [EPIC-KEY] '[Epic Name]'?"

**Option B: Assign and document your reasoning**
- Assign the ticket to the epic
- Add a comment explaining why you chose that epic
- Mention it can be changed if incorrect

Example comment:
```
Assigned to epic PROJ-1330 "Q1 '26 Reactive Work" - this is the current quarter's epic for on-call/production support work. Feel free to reassign if a different epic is more appropriate.
```

### 6. Assign the ticket to the epic

**WARNING: "Linking" is NOT the same as setting parent!**
- `acli jira workitem link create` creates an issue LINK (a reference between tickets)
- Setting `parent` field makes the ticket a CHILD of the epic (shows in epic's backlog)
- For epic assignment, you MUST set the parent field via REST API

Use REST API to set the parent (see [REST-API.md](REST-API.md#setting-parent-epic-on-a-ticket)):

```bash
curl -s --request PUT \
  --url "https://yourcompany.atlassian.net/rest/api/3/issue/PROJ-123" \
  --header "Authorization: Basic ${AUTH}" \
  --header "Content-Type: application/json" \
  --data '{"fields": {"parent": {"key": "EPIC-KEY"}}}'
```

To add a comment explaining your choice:
```bash
acli jira workitem comment create --key "PROJ-123" --body "Assigned to epic EPIC-KEY - [reason]. Feel free to reassign if a different epic is more appropriate."
```

### Epic Patterns (From Config)

Check your config file for organization-specific epic patterns:

```bash
jq -r '.epicPatterns[] | "- \(.workType): \(.example)"' ~/.config/claude-skills/managing-jira/config.json
```

If no patterns are configured, common patterns include:
- **Quarterly reactive**: `Q1 '26 Reactive Work` - for on-call/production support
- **Incident response**: `Q4 2025 Incident Response` - for incident remediation
- **Tech debt**: Descriptive names like `Tech Modernization & Stability`
- **Feature work**: Feature-specific names like `Search Performance Optimization`

**Tip:** For reactive/on-call work, use the current quarter's reactive epic. Search with the current quarter (Q1-Q4) and year.

See [CONFIG.md](CONFIG.md#epic-patterns) for how to configure your organization's patterns.

## Intelligent Features

The skill includes learning capabilities that improve over time. See [INTELLIGENT.md](INTELLIGENT.md) for full details.

| Feature | Purpose | Details |
|---------|---------|---------|
| Saved Queries | Natural language → JQL matching | [QUERIES.md](QUERIES.md) |
| Sprint Helpers | Cached sprint info, summaries | [SPRINTS.md](SPRINTS.md) |
| Personal Metrics | WIP limits, completion tracking | [METRICS.md](METRICS.md) |
| Smart Epics | Learn epic assignments from confirmations | [EPICS.md](EPICS.md) |
| Multi-Project | Tiered project access with promotion | [PROJECTS.md](PROJECTS.md) |
| Map Jira | Discover related projects and people | [DISCOVERY.md](DISCOVERY.md) |
| Recent Tickets | Last 50 interaction memory | [RECENT.md](RECENT.md) |

## Reference

- **Installation**: See [INSTALL.md](INSTALL.md) for installation instructions
- **Configuration**: See [CONFIG.md](CONFIG.md) for setup instructions
- **JQL syntax**: See [JQL.md](JQL.md) for query examples
- **Rich formatting**: See [ADF.md](ADF.md) for Atlassian Document Format
- **REST API workarounds**: See [REST-API.md](REST-API.md) for ACLI limitations
- **Intelligent Features**: See [INTELLIGENT.md](INTELLIGENT.md) for learning capabilities

## Output Formats

Most commands support:
- `--json` - JSON output for parsing
- `--csv` - CSV output for spreadsheets
- `--web` - Open in browser

## Tips

1. Use `@me` for self-assignment instead of typing your email
2. Use `--yes` to skip confirmation prompts in scripts
3. Use `--paginate` to get all results for large datasets
4. Use `--filter ID` for complex, reusable queries
5. Use `--fields` to limit output and improve readability

## Known Limitations

- `--description-file` does not support headings - use `--from-json` instead
- Attachments cannot be added via CLI
- **Sprint assignment** must be done via REST API (see [REST-API.md](REST-API.md#setting-sprint-on-a-ticket))
- **Epic creation** may fail with required custom field errors (e.g., "Capitalize is required") - workaround: use REST API directly (see [REST-API.md](REST-API.md))
- **Story points and custom fields** cannot be set via ACLI edit command - use REST API (see [REST-API.md](REST-API.md))
- **ACLI view doesn't display custom fields**: `acli jira workitem view` only shows standard fields (summary, status, assignee, etc.). To verify custom field values (story points, sprint, etc.), use REST API with field IDs from your config (`~/.config/claude-skills/managing-jira/config.json`):
  ```bash
  # Get field ID from config (e.g., storyPoints -> customfield_10026)
  FIELD_ID=$(jq -r '.customFields.storyPoints' ~/.config/claude-skills/managing-jira/config.json)
  curl -s --request GET \
    --url "${BASE_URL}/rest/api/3/issue/KEY-123?fields=${FIELD_ID}" \
    --header "Authorization: Basic ${AUTH}" | jq '.fields'
  ```
  When you discover new custom field IDs, add them to `customFields` in the config for future reference.
- **Link types** require the FULL name including parenthetical description:
  - Correct: `--type "01 Relates To (Named 01 to be at top of list for generic linking)"`
  - Wrong: `--type "Relates To"`
  - Always run `acli jira workitem link type` first to get exact names
- **Unassigned tickets**: Simply omit the `--assignee` flag (don't use empty string or "unassigned")
- **Subtasks with ADF descriptions**: `--from-json` does not support parent field (`parent`, `parentKey` both fail). Workaround: create subtask with CLI flags first (`--parent`), then edit description with `--from-json` in a second command
- **Workflow transitions may be blocked**: Some Jira workflows require custom fields (e.g., "Actual Points") when transitioning to Done - use REST API (see [REST-API.md](REST-API.md))
- **Comment ADF formatting**: ACLI's `--body` parameter does not render ADF formatting in comments - links, code blocks, and bullet lists appear as plain text. Workaround: Use Jira REST API directly with `curl` for rich-formatted comments
