# JQL Quick Reference

## Project Filtering
```
project = "PROJECT_KEY"
project in ("PROJ1", "PROJ2")
```

## Status Filtering
```
status = "In Progress"
status != "Done"
status in ("To Do", "In Progress")
status not in ("Done", "Closed")
```

## Assignee Queries
```
assignee = currentUser()
assignee = "user@email.com"
assignee is EMPTY
assignee is not EMPTY
```

## Type Filtering
```
type = Bug
type in (Bug, Task)
issuetype = Story
```

## Date Queries
```
created >= -7d                    # Created in last 7 days
updated >= startOfWeek()          # Updated this week
created >= "2024-01-01"           # Created after date
duedate < now()                   # Overdue items
```

## Sprint Queries
```
sprint in openSprints()           # Current active sprints
sprint in futureSprints()         # Future sprints
sprint is EMPTY                   # Backlog items
sprint = "Sprint 1"               # Specific sprint
```

## Text Search
```
summary ~ "login"                 # Summary contains "login"
description ~ "error"             # Description contains "error"
text ~ "search term"              # Full text search
```

## Labels and Components
```
labels = "urgent"
labels in ("bug", "frontend")
component = "API"
```

## Priority
```
priority = High
priority in (High, Highest)
```

## Combined Examples
```
project = PROJECT_KEY AND status = "In Progress" AND assignee = currentUser()
project = PROJECT_KEY AND type = Bug AND priority in (High, Highest) AND status != Done
project = PROJECT_KEY AND created >= -7d ORDER BY created DESC
```
