---
name: creating-mermaid-diagrams
description: >
  Generates GitHub-compatible Mermaid diagrams that render correctly in
  markdown files, pull requests, issues, and comments. Supports all Mermaid
  diagram types with tested color palettes for light and dark mode. Provides
  local SVG/PNG preview via mermaid CLI and GitHub rendering preview via
  private gists. Use when the user asks to create a diagram, flowchart,
  sequence diagram, ER diagram, architecture diagram, state machine, Gantt
  chart, or any Mermaid visualization for GitHub.
allowed-tools: Bash, Read, Write, Glob, Grep
license: MIT
metadata:
  version: 1.0.0
  author: mdsakalu
  spec-version: agentskills.io/2026
compatibility: >
  Optional: npx @mermaid-js/mermaid-cli for local SVG/PNG preview.
  Optional: gh CLI for gist-based GitHub rendering preview.
  macOS and Linux. Claude Code only.
---

# Creating Mermaid Diagrams

## Quick Start

Wrap mermaid in a fenced code block for GitHub:

~~~markdown
```mermaid
flowchart TD
    A["Start"] --> B{"Decision"}
    B -->|Yes| C["Action"]
    B -->|No| D["Other Action"]
    C --> E["End"]
    D --> E

    classDef primary fill:#4493f8,stroke:#1f6feb,color:#fff
    classDef success fill:#3fb950,stroke:#238636,color:#fff
    classDef warning fill:#d29922,stroke:#9e6a03,color:#fff
    classDef danger fill:#f85149,stroke:#da3633,color:#fff

    class A primary
    class C success
    class D warning
    class E danger
```
~~~

Always include `accTitle` and `accDescr` for accessibility.

## Workflow

1. **Choose diagram type** -- Match the user's intent to a diagram type (see table below or `references/diagram-types.md` for full syntax)
2. **Write the diagram** -- Use snake_case node IDs, quote reserved words
3. **Apply styling** -- Use classDef from the Default Styling section or pick a theme from `references/themes.md`
4. **Preview** -- Local SVG via `preview.sh local` or GitHub rendering via `preview.sh gist`
5. **Embed** -- Place the fenced code block in the target markdown file

## Choosing a Diagram Type

| Use Case | Diagram Type | Keyword |
|---|---|---|
| Process flow, decision tree | `flowchart` | flowchart TD/LR |
| API call sequence, auth flow | `sequenceDiagram` | sequenceDiagram |
| Object model, inheritance | `classDiagram` | classDiagram |
| Lifecycle, transitions | `stateDiagram-v2` | stateDiagram-v2 |
| Database schema, relationships | `erDiagram` | erDiagram |
| Project timeline | `gantt` | gantt |
| Task board | `kanban` | kanban |
| Historical/event timeline | `timeline` | timeline |
| Distribution, proportions | `pie` | pie |
| 2x2 matrix, positioning | `quadrantChart` | quadrantChart |
| Line/bar chart | `xychart-beta` | xychart-beta |
| Flow volume, allocation | `sankey-beta` | sankey-beta |
| Brainstorming, hierarchy | `mindmap` | mindmap |
| System context, containers | `C4Context` | C4Context |
| Infrastructure layout | `architecture-beta` | architecture-beta |
| Block layout | `block-beta` | block-beta |
| Git history visualization | `gitGraph` | gitGraph |
| Network packets | `packet-beta` | packet-beta |
| Requirements traceability | `requirementDiagram` | requirementDiagram |

For full syntax and examples of each type, see `references/diagram-types.md`.

## GitHub Compatibility Essentials

These rules are critical. Violating them causes diagrams to silently fail on GitHub.

### Fenced Code Block Syntax

Always use triple backticks with `mermaid` language identifier:

~~~markdown
```mermaid
flowchart TD
    A --> B
```
~~~

### Node ID Rules

- Use `snake_case` for all node IDs: `api_gateway`, `user_request`
- Quote labels that contain spaces or special characters: `A["My Label"]`
- Quote reserved words used as IDs: `end_node["end"]`, `class_def["class"]`
- Reserved words: `end`, `class`, `click`, `style`, `subgraph`, `default`

### Dark Mode Compatibility

GitHub renders diagrams on both light (#ffffff) and dark (#0d1117) backgrounds. Rules:

- Use **medium-to-dark fill colors** (not pastel/light) so text is readable on both
- Always set explicit `color:#fff` or `color:#000` in classDef
- Test with both backgrounds (use `preview.sh` dark mode flag)
- The default GitHub mermaid theme changes between light/dark -- custom classDef overrides this

### Accessibility

Always include accessibility metadata:

```mermaid
flowchart TD
    accTitle: CI/CD Pipeline Overview
    accDescr: Shows the flow from code commit through build, test, and deploy stages
    A --> B
```

### What GitHub Does NOT Support

- `%%{init: {'theme': 'dark'}}%%` -- theme directives are **ignored**
- HTML tags in labels (`<b>`, `<br/>`) -- use `\n` for line breaks if needed
- Nested subgraphs beyond 2 levels deep (rendering breaks)
- Diagrams with more than ~100 nodes (performance degrades)
- `click` callbacks (security restriction)
- Some beta diagram types may not be available yet

For the complete compatibility reference, see `references/github-compatibility.md`.

## Default Styling

Ready-to-use classDef set tested on GitHub light and dark modes:

```
%% Semantic color classes -- GitHub light+dark safe
classDef primary fill:#4493f8,stroke:#1f6feb,color:#fff
classDef secondary fill:#8b949e,stroke:#6e7681,color:#fff
classDef success fill:#3fb950,stroke:#238636,color:#fff
classDef warning fill:#d29922,stroke:#9e6a03,color:#fff
classDef danger fill:#f85149,stroke:#da3633,color:#fff
classDef muted fill:#30363d,stroke:#484f58,color:#8b949e
classDef info fill:#58a6ff,stroke:#388bfd,color:#fff
```

### Applying Classes

```mermaid
flowchart TD
    user["User"] --> api["API Gateway"]
    api --> auth{"Authenticate"}
    auth -->|Pass| service["Service"]
    auth -->|Fail| error["Error"]
    service --> db[("Database")]

    class user primary
    class api info
    class auth warning
    class service success
    class error danger
    class db secondary
```

### Edge Styling

```
%% Default edge style
linkStyle default stroke:#8b949e,stroke-width:2px

%% Style a specific edge by index (0-based)
linkStyle 0 stroke:#4493f8,stroke-width:3px
linkStyle 2 stroke:#f85149,stroke-width:2px,stroke-dasharray:5
```

For themed palettes (Dracula, Nord, Catppuccin, etc.), see `references/themes.md`.
For advanced styling patterns, see `references/style-guide.md`.

## Preview Workflow

### Local Preview (SVG/PNG)

Requires: `npx @mermaid-js/mermaid-cli` (installed on first use)

```bash
# Preview a .mmd file as SVG (opens in browser)
bash ~/.claude/skills/creating-mermaid-diagrams/scripts/preview.sh local diagram.mmd

# Preview with dark background
bash ~/.claude/skills/creating-mermaid-diagrams/scripts/preview.sh local diagram.mmd --dark

# Extract mermaid from a markdown file and preview
bash ~/.claude/skills/creating-mermaid-diagrams/scripts/preview.sh local README.md
```

The script:
1. Extracts mermaid code from markdown if needed
2. Runs `npx -y @mermaid-js/mermaid-cli mmdc` to generate SVG
3. Optionally generates a dark-background version
4. Opens the SVG in the default browser

### GitHub Preview (Private Gist)

Requires: `gh` CLI authenticated

```bash
# Create a private gist with the diagram and open in browser
bash ~/.claude/skills/creating-mermaid-diagrams/scripts/preview.sh gist diagram.md

# If input is .mmd, it will be wrapped in a markdown code block automatically
bash ~/.claude/skills/creating-mermaid-diagrams/scripts/preview.sh gist diagram.mmd
```

The script:
1. Wraps raw mermaid in a markdown fenced code block if needed
2. Creates a private gist via `gh gist create`
3. Tracks the gist ID in `~/.cache/mermaid-preview-gists.txt`
4. Prints the gist URL
5. Opens the URL in the default browser

This is the most accurate preview since it uses GitHub's actual renderer.

## Gist Management

Preview gists accumulate over time. Use these commands to manage them:

```bash
# List all tracked preview gists
bash ~/.claude/skills/creating-mermaid-diagrams/scripts/preview.sh list

# Show gists that can be cleaned up (does NOT delete)
bash ~/.claude/skills/creating-mermaid-diagrams/scripts/preview.sh cleanup
```

The `cleanup` command lists tracked gists but does **not** delete them automatically. After running cleanup, Claude should present the list to the user and ask for confirmation before deleting each gist:

```bash
# Delete a specific gist (only after user confirmation)
gh gist delete GIST_ID
```

After deletion, the gist ID is removed from the tracking file.

**Important**: Never delete gists without explicit user confirmation. Always show the gist URL and creation date before asking.

## Output Format

When creating a diagram for the user, always output it in this format:

~~~markdown
```mermaid
[diagram type]
    accTitle: [Brief title]
    accDescr: [One-sentence description of what the diagram shows]

    [diagram content]

    [classDef declarations]
    [class assignments]
```
~~~

## References

- **Diagram types and syntax**: `references/diagram-types.md`
- **GitHub rendering details**: `references/github-compatibility.md`
- **Styling patterns**: `references/style-guide.md`
- **Color themes**: `references/themes.md`
- **Preview scripts**: `scripts/preview.sh`, `scripts/theme-preview.sh`
