# Mermaid Diagram Types Reference

Quick reference for all Mermaid diagram types. Each entry includes: when to use, a minimal working example, and GitHub-specific tips where applicable.

---

## Core Diagrams

### Flowchart

**Syntax:** `flowchart TD` (top-down) or `flowchart LR` (left-right)
**Use when:** Modeling process flows, decision trees, or any directed graph.

```mermaid
---
accTitle: Example Flowchart
accDescr: Demonstrates a basic flowchart with decision branching.
---
flowchart TD
    start_process[Start] --> check_input{Valid Input?}
    check_input -->|Yes| process_data[Process Data]
    check_input -->|No| show_error[Show Error]
    process_data --> end_process[Done]
    show_error --> end_process
```

**GitHub tips:**
- Use `accTitle` and `accDescr` in frontmatter for accessibility (recommended on all diagrams, shown here as a reminder).
- `TD`/`TB` for top-down, `LR` for left-right, `RL` for right-left, `BT` for bottom-top.
- Keep node IDs in snake_case for readability in source.

---

### Sequence Diagram

**Syntax:** `sequenceDiagram`
**Use when:** Illustrating API calls, authentication flows, or message passing between actors.

```mermaid
sequenceDiagram
    participant client
    participant api_server
    participant database

    client->>api_server: POST /login
    api_server->>database: SELECT user
    database-->>api_server: user record
    api_server-->>client: 200 JWT token
```

**GitHub tips:**
- Use `->>` for solid arrows (requests) and `-->>` for dashed arrows (responses).
- `participant` declares order; `actor` renders a person icon instead of a box.
- Long diagrams render better with `autonumber` to label each step.

---

### Class Diagram

**Syntax:** `classDiagram`
**Use when:** Documenting object models, inheritance hierarchies, or interface contracts.

```mermaid
classDiagram
    class base_service {
        +String name
        +start() void
        +stop() void
    }
    class auth_service {
        +validate(token) bool
    }
    base_service <|-- auth_service
    auth_service --> token_store : uses
```

**GitHub tips:**
- Use `<|--` for inheritance, `-->` for association, `*--` for composition, `o--` for aggregation.
- Visibility: `+` public, `-` private, `#` protected, `~` package.

---

### State Diagram

**Syntax:** `stateDiagram-v2`
**Use when:** Modeling lifecycles, state machines, or transition logic.

```mermaid
stateDiagram-v2
    [*] --> idle
    idle --> processing : submit_job
    processing --> completed : success
    processing --> failed : error
    failed --> idle : retry
    completed --> [*]
```

**GitHub tips:**
- Use `v2` syntax; the original `stateDiagram` is deprecated.
- `[*]` represents start and end pseudo-states.
- Nest states with `state parent_state { ... }` for composite states.

---

### ER Diagram

**Syntax:** `erDiagram`
**Use when:** Documenting database schemas or entity relationships.

```mermaid
erDiagram
    user ||--o{ order : places
    order ||--|{ line_item : contains
    line_item }o--|| product : references

    user {
        int id PK
        string email
        string name
    }
    order {
        int id PK
        int user_id FK
        date created_at
    }
```

**GitHub tips:**
- Relationship syntax: `||` exactly one, `o|` zero or one, `}|` one or more, `}o` zero or more.
- Mark keys with `PK`, `FK`, `UK` after the column name.

---

## Project Diagrams

### Gantt

**Syntax:** `gantt`
**Use when:** Showing project timelines, phase schedules, or task dependencies.

```mermaid
gantt
    title Release Plan
    dateFormat YYYY-MM-DD
    section Backend
        api_design       :a1, 2026-03-01, 7d
        implementation   :a2, after a1, 14d
    section Frontend
        wireframes       :b1, 2026-03-01, 5d
        build_ui         :b2, after b1, 10d
```

**GitHub tips:**
- Tasks can use `done`, `active`, `crit` markers for status and priority.
- `after a1` creates dependency links between tasks.

---

### Kanban

**Syntax:** `kanban`
**Use when:** Representing task boards or workflow stages.

```mermaid
kanban
    Backlog
        task_a[Design API schema]
        task_b[Write migration scripts]
    In Progress
        task_c[Build auth module]
    Done
        task_d[Setup CI pipeline]
```

**GitHub tips:**
- Kanban is a newer diagram type; verify rendering support in your target GitHub environment.
- Column names are plain text; tasks use bracket syntax for IDs and labels.

---

### Timeline

**Syntax:** `timeline`
**Use when:** Showing historical events, milestones, or chronological progressions.

```mermaid
timeline
    title Product Milestones
    2025-Q1 : MVP launched
             : First 100 users
    2025-Q2 : Series A funding
    2025-Q3 : International expansion
    2025-Q4 : 10k users milestone
```

**GitHub tips:**
- Each time period can have multiple events separated by newlines with `:`.
- Titles are optional but recommended for context.

---

### Requirement Diagram

**Syntax:** `requirementDiagram`
**Use when:** Tracking requirements traceability or linking requirements to design elements.

```mermaid
requirementDiagram
    requirement auth_requirement {
        id: REQ-001
        text: System shall authenticate users via OAuth2
        risk: medium
        verifymethod: test
    }
    element auth_module {
        type: module
    }
    auth_module - satisfies -> auth_requirement
```

**GitHub tips:**
- Relationship types: `satisfies`, `traces`, `contains`, `derives`, `refines`, `copies`.
- `risk` accepts `low`, `medium`, `high`; `verifymethod` accepts `test`, `inspection`, `analysis`, `demonstration`.

---

## Data Diagrams

### Pie Chart

**Syntax:** `pie`
**Use when:** Showing distribution or proportions of a whole.

```mermaid
pie title Incident Root Causes
    "Config Error" : 42
    "Code Bug" : 30
    "Infra Failure" : 18
    "Unknown" : 10
```

**GitHub tips:**
- Values are relative; Mermaid calculates percentages automatically.
- Keep to 6 or fewer slices for readability.

---

### Quadrant Chart

**Syntax:** `quadrantChart`
**Use when:** Creating 2x2 matrices for priority/effort mapping or strategic positioning.

```mermaid
quadrantChart
    title Task Prioritization
    x-axis Low Effort --> High Effort
    y-axis Low Impact --> High Impact
    quadrant-1 Do First
    quadrant-2 Schedule
    quadrant-3 Delegate
    quadrant-4 Eliminate
    task_a: [0.2, 0.8]
    task_b: [0.7, 0.9]
    task_c: [0.3, 0.3]
    task_d: [0.8, 0.2]
```

**GitHub tips:**
- Coordinates are normalized 0.0 to 1.0 for both axes.
- Quadrants are numbered: 1=top-right, 2=top-left, 3=bottom-left, 4=bottom-right.

---

### XY Chart

**Syntax:** `xychart-beta`
**Use when:** Creating line charts or bar charts from data series.

```mermaid
xychart-beta
    title "Monthly Deployments"
    x-axis [Jan, Feb, Mar, Apr, May, Jun]
    y-axis "Count" 0 --> 50
    bar [12, 18, 25, 30, 22, 40]
    line [12, 18, 25, 30, 22, 40]
```

**GitHub tips:**
- Beta syntax; may change in future Mermaid versions.
- Supports `bar` and `line` series; both can coexist in one chart.

---

### Sankey Diagram

**Syntax:** `sankey-beta`
**Use when:** Visualizing flow volume, resource allocation, or conversion funnels.

```mermaid
sankey-beta

Traffic,Organic,5000
Traffic,Paid,3000
Organic,Signup,2000
Organic,Bounce,3000
Paid,Signup,1500
Paid,Bounce,1500
```

**GitHub tips:**
- Uses CSV-like syntax: `source,target,value` with each flow on its own line.
- A blank line after the directive is required before the data rows.
- Keep node names short; long labels can clip.

---

## Architecture Diagrams

### C4 Context

**Syntax:** `C4Context`
**Use when:** Creating system context diagrams following the C4 model.

```mermaid
C4Context
    title System Context - Order Platform
    Person(customer, "Customer", "Places orders")
    System(order_system, "Order Platform", "Handles orders")
    System_Ext(payment_provider, "Payment Gateway", "Processes payments")

    Rel(customer, order_system, "Uses", "HTTPS")
    Rel(order_system, payment_provider, "Sends payments", "API")
```

**GitHub tips:**
- Also supports `C4Container`, `C4Component`, and `C4Deployment` for deeper levels.
- Use `System_Ext` for external systems, `System_Boundary` for grouping.
- `Rel` defines relationships with optional description and technology.

---

### Architecture

**Syntax:** `architecture-beta`
**Use when:** Illustrating infrastructure layout or cloud architecture.

```mermaid
architecture-beta
    group cloud_vpc(cloud)[VPC]

    service web_app(server)[Web App] in cloud_vpc
    service app_db(database)[Database] in cloud_vpc
    service cdn(internet)[CDN]

    cdn:R --> L:web_app
    web_app:R --> L:app_db
```

**GitHub tips:**
- Beta syntax; icon names in parentheses are from a built-in icon set (`server`, `database`, `internet`, `cloud`, `disk`).
- Positioning hints use `L`, `R`, `T`, `B` for left, right, top, bottom.
- `group` creates visual boundaries; `in` places services inside groups.

---

### Block Diagram

**Syntax:** `block-beta`
**Use when:** Creating block-based layouts or component diagrams with spatial positioning.

```mermaid
block-beta
    columns 3
    api_gateway["API Gateway"]:3
    auth_svc["Auth"] cache_svc["Cache"] db_svc["Database"]
    space:2 monitoring["Monitoring"]
```

**GitHub tips:**
- `columns N` sets the grid width; blocks span columns with `:N` suffix.
- `space` inserts empty cells for layout control.
- Beta syntax; good for structured layouts that flowcharts handle awkwardly.

---

## Other Diagrams

### Mindmap

**Syntax:** `mindmap`
**Use when:** Brainstorming, showing hierarchical concepts, or organizing ideas.

```mermaid
mindmap
    root((System Design))
        Backend
            API Layer
            Business Logic
            Data Access
        Frontend
            Components
            State Management
        Infrastructure
            CI/CD
            Monitoring
```

**GitHub tips:**
- Indentation defines hierarchy (use consistent spacing).
- Root shape: `((circle))`, `[square]`, `(rounded)`, or plain text.
- No explicit connections; hierarchy is implied by nesting.

---

### ZenUML

**Syntax:** `zenuml`
**Use when:** Preferring code-like syntax for sequence diagrams.

```mermaid
zenuml
    @Actor client
    @Entity api_server

    client->api_server.get_users() {
        api_server->database.query("SELECT *") {
            return results
        }
        return response
    }
```

**GitHub tips:**
- Alternative to `sequenceDiagram` with a more programming-language feel.
- Uses method call syntax and curly braces for nested interactions.
- Verify GitHub rendering support; ZenUML may require a newer Mermaid version.

---

### Packet Diagram

**Syntax:** `packet-beta`
**Use when:** Documenting network packet structures or binary data formats.

```mermaid
packet-beta
    0-15: "Source Port"
    16-31: "Destination Port"
    32-63: "Sequence Number"
    64-95: "Acknowledgment Number"
    96-99: "Data Offset"
    100-105: "Reserved"
    106-111: "Flags"
    112-127: "Window Size"
```

**GitHub tips:**
- Bit ranges use `start-end: "label"` syntax.
- Beta feature; useful for protocol documentation and RFC-style diagrams.
- Renders as a structured bit-field table.

---

### Git Graph

**Syntax:** `gitGraph`
**Use when:** Visualizing branching strategies, merge flows, or release processes.

```mermaid
gitGraph
    commit id: "init"
    branch feature_auth
    checkout feature_auth
    commit id: "add_login"
    commit id: "add_tests"
    checkout main
    merge feature_auth id: "merge_auth"
    commit id: "release_v1"
```

**GitHub tips:**
- Branch names cannot contain spaces; use snake_case or kebab-case.
- `cherry-pick` is supported for showing cherry-pick operations.
- Default branch is `main`; customize with `commit`, `branch`, `checkout`, `merge` commands.

---

## Quick Selection Guide

| Need to show...            | Use              | Syntax keyword       |
|----------------------------|------------------|----------------------|
| Process or logic flow      | Flowchart        | `flowchart`          |
| API or message exchange    | Sequence Diagram | `sequenceDiagram`    |
| Object model               | Class Diagram    | `classDiagram`       |
| State transitions          | State Diagram    | `stateDiagram-v2`    |
| Database schema            | ER Diagram       | `erDiagram`          |
| Project schedule           | Gantt            | `gantt`              |
| Task board                 | Kanban           | `kanban`             |
| Chronological events       | Timeline         | `timeline`           |
| Requirements tracing       | Requirement      | `requirementDiagram` |
| Proportions                | Pie Chart        | `pie`                |
| 2x2 matrix                 | Quadrant Chart   | `quadrantChart`      |
| Line/bar chart             | XY Chart         | `xychart-beta`       |
| Flow volumes               | Sankey           | `sankey-beta`        |
| System context (C4)        | C4 Context       | `C4Context`          |
| Infrastructure layout      | Architecture     | `architecture-beta`  |
| Block layout               | Block Diagram    | `block-beta`         |
| Idea hierarchy             | Mindmap          | `mindmap`            |
| Sequence (code-style)      | ZenUML           | `zenuml`             |
| Packet/binary structure    | Packet           | `packet-beta`        |
| Git branching              | Git Graph        | `gitGraph`           |
