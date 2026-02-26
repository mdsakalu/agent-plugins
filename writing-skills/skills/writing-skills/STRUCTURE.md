# Skill Structure Reference

## Required File

Every skill requires a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: your-skill-name
description: What this skill does and when to use it.
allowed-tools: Read, Edit, Bash
---

# Your Skill Name

[Instructions here]
```

## YAML Frontmatter Requirements

### name (required)

| Constraint | Rule |
|------------|------|
| Max length | 64 characters |
| Characters | Lowercase letters, numbers, hyphens only |
| No XML tags | Cannot contain `<` or `>` |
| Reserved words | Cannot contain "anthropic" or "claude" |

**Valid examples:**
- `processing-pdfs`
- `writing-skills`
- `data-analysis-v2`

**Invalid examples:**
- `ProcessingPDFs` (uppercase)
- `my_skill` (underscore)
- `claude-helper` (reserved word)
- `my skill` (space)

### description (required)

| Constraint | Rule |
|------------|------|
| Max length | 1024 characters |
| Min length | 1 character (non-empty) |
| No XML tags | Cannot contain `<` or `>` |
| Point of view | **Must be third person** |

### allowed-tools (optional)

Tools the skill can use without approval prompts.

```yaml
allowed-tools: Read, Edit, Bash, Glob, Grep
```

Common tools: `Read`, `Edit`, `Write`, `Bash`, `Glob`, `Grep`, `WebFetch`, `Task`, `AskUserQuestion`

Supports permission patterns: `Bash(git:*)`, `Bash(npm:*)`, etc.

### argument-hint (optional)

Hint shown during autocomplete to indicate expected arguments.

```yaml
argument-hint: [issue-number]
# or
argument-hint: [filename] [format]
```

### disable-model-invocation (optional)

Prevents Claude from automatically loading this skill. Use for workflows you want to control manually.

```yaml
disable-model-invocation: true
```

**When to use:** Deployment scripts, destructive operations, anything with side effects you want to trigger explicitly with `/skill-name`.

### user-invocable (optional)

Set to `false` to hide from the `/` menu. Use for background knowledge that shouldn't be invoked directly.

```yaml
user-invocable: false
```

**When to use:** Context-only skills like "legacy-system-context" that Claude should know about but users wouldn't invoke as a command.

### model (optional)

Specify which model to use when this skill is active.

```yaml
model: claude-sonnet-4-20250514
```

### context (optional)

Set to `fork` to run in an isolated subagent context.

```yaml
context: fork
```

**When to use:** Research tasks, parallel exploration, tasks that shouldn't affect main conversation.

### agent (optional)

Which subagent type to use when `context: fork` is set.

```yaml
context: fork
agent: Explore
```

Options: `Explore`, `Plan`, `general-purpose`, or custom agents from `.claude/agents/`.

### hooks (optional)

Hooks scoped to this skill's lifecycle. See Claude Code hooks documentation.

```yaml
hooks:
  PreToolUse:
    - command: echo "Tool about to run"
```

### license (optional)

Specify the license for your skill.

| Constraint | Rule |
|------------|------|
| Max length | 256 characters |
| Format | License name (e.g., "MIT", "Apache-2.0") or path to LICENSE file |

```yaml
# Simple license name
license: MIT

# Reference to bundled file
license: See LICENSE.md
```

### metadata (optional)

Key-value map for author, version, and custom fields.

| Constraint | Rule |
|------------|------|
| Format | YAML map |
| Common keys | `author`, `version`, `updated`, `spec-version` |
| Custom keys | Allowed (use lowercase, hyphenated names) |

```yaml
metadata:
  author: Your Name
  version: 1.0.0
  updated: 2026-01-08
  spec-version: agentskills.io/2026
  custom-field: any value
```

### compatibility (optional)

Environment requirements and platform constraints.

| Constraint | Rule |
|------------|------|
| Max length | 500 characters |
| Purpose | Document platform requirements, dependencies, limitations |

```yaml
# Short form
compatibility: Requires Python 3.10+, pdfplumber library

# Multi-line form
compatibility: |
  Platform: Claude Code only (uses filesystem)
  Dependencies: Python 3.10+, pdfplumber, PyYAML
  Not compatible with Claude apps (requires local file access)
```

**When to use compatibility:**
- Skill requires specific tools not available everywhere
- Skill uses platform-specific features (hooks, Task tool)
- Skill has external dependencies
- Skill has known limitations on certain platforms

**Good descriptions:**

```yaml
# Specific, includes triggers
description: Extracts text and tables from PDF files, fills forms, merges documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.

# Clear scope and triggers
description: Analyzes Excel spreadsheets, creates pivot tables, generates charts. Use when analyzing Excel files, spreadsheets, tabular data, or .xlsx files.

# Action-oriented with context
description: Generates descriptive commit messages by analyzing git diffs. Use when the user asks for help writing commit messages or reviewing staged changes.
```

**Bad descriptions:**

```yaml
# Too vague
description: Helps with documents

# Wrong point of view
description: I can help you process Excel files

# Missing triggers
description: Processes data
```

## Complete Frontmatter Example

```yaml
---
name: processing-pdfs
description: Extracts text and tables from PDF files, fills forms, merges
  documents. Use when working with PDF files or when user mentions PDFs,
  forms, or document extraction.
allowed-tools: Read, Write, Bash, Glob
license: MIT
metadata:
  author: Your Name
  version: 1.2.0
  updated: 2026-01-08
  spec-version: agentskills.io/2026
compatibility: |
  Requires Python 3.10+ with pdfplumber library.
  Works on Claude Code and API. Limited functionality in Claude apps
  (no local file access).
---
```

**Field summary:**

| Field | Required | Max Length | Notes |
|-------|----------|------------|-------|
| name | Yes | 64 chars | lowercase, hyphens, digits only |
| description | Yes | 1024 chars | third person, include triggers |
| allowed-tools | No | - | tool names, supports patterns like `Bash(git:*)` |
| argument-hint | No | - | autocomplete hint like `[issue-number]` |
| disable-model-invocation | No | - | `true` to prevent auto-loading |
| user-invocable | No | - | `false` to hide from `/` menu |
| model | No | - | model ID to use |
| context | No | - | `fork` for subagent execution |
| agent | No | - | subagent type when `context: fork` |
| hooks | No | - | skill-scoped hooks |
| license | No | 256 chars | license name or file reference |
| metadata | No | - | YAML map for author/version |
| compatibility | No | 500 chars | environment requirements |

For the full specification, see [agentskills.io/specification](https://agentskills.io/specification).

## String Substitutions

Skills support dynamic value substitution in content:

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking the skill |
| `${CLAUDE_SESSION_ID}` | Current session ID for logging/correlation |

If `$ARGUMENTS` is not present in the skill content, arguments are appended as `ARGUMENTS: <value>`.

## Dynamic Context Injection

The `!`command`` syntax runs shell commands before the skill content is sent to Claude:

```markdown
## PR Context
- Diff: !`gh pr diff`
- Comments: !`gh pr view --comments`
```

Commands execute immediately and their output replaces the placeholder. Claude only sees the final rendered content.

## Naming Conventions

Use **gerund form** (verb + -ing) for skill names:

| Good (gerund) | Acceptable | Avoid |
|---------------|------------|-------|
| `processing-pdfs` | `pdf-processing` | `pdf-helper` |
| `analyzing-data` | `data-analysis` | `data-utils` |
| `writing-tests` | `test-writer` | `tests` |
| `managing-databases` | `db-manager` | `db` |

Why gerund form?
- Clearly describes the activity
- Consistent pattern across skills
- Easy to understand at a glance

## File Organization

### Simple skill (single file)

```
my-skill/
└── SKILL.md
```

### Standard skill (with references)

```
my-skill/
├── SKILL.md        # Main instructions (<500 lines)
├── REFERENCE.md    # Detailed documentation
└── EXAMPLES.md     # Extended examples
```

### Skill with scripts

```
my-skill/
├── SKILL.md
├── REFERENCE.md
└── scripts/
    ├── analyze.py
    ├── validate.py
    └── process.py
```

### Full skill (all resource types)

```
my-skill/
├── SKILL.md           # Main instructions (<500 lines)
├── scripts/           # Executable code (deterministic operations)
│   └── process.py
├── references/        # Docs loaded into context on-demand
│   └── api-guide.md
└── assets/            # Files used in output (NOT loaded into context)
    ├── template.pptx
    └── logo.png
```

**When to use each:**
- **scripts/**: Code that needs to run reliably (PDF processing, API calls)
- **references/**: Documentation Claude should read when working (schemas, specs)
- **assets/**: Templates, images, fonts - copied to output, not read into context

### Domain-organized skill

```
analytics-skill/
├── SKILL.md
└── reference/
    ├── finance.md
    ├── sales.md
    └── product.md
```

## Token Budget Guidelines

| Content | Guideline |
|---------|-----------|
| SKILL.md body | Under 500 lines |
| Reference files | Any length (loaded on-demand) |
| Scripts | Any length (executed, not loaded) |

### Progressive Loading

1. **Startup**: Only `name` and `description` loaded (~100 tokens per skill)
2. **Triggered**: SKILL.md body loaded (under 5k tokens recommended)
3. **As needed**: Reference files loaded when referenced

## Reference Depth

Keep references **one level deep** from SKILL.md:

```markdown
# Good: One level
SKILL.md → reference.md (contains info)

# Bad: Too deep
SKILL.md → advanced.md → details.md → info
```

## Directory Locations

### Personal skills (all projects)

```
~/.claude/skills/your-skill/SKILL.md
```

### Project skills (specific project)

```
/path/to/project/.claude/skills/your-skill/SKILL.md
```

## File Naming

- Use lowercase
- Use hyphens for word separation
- Use descriptive names
- Always use forward slashes in paths

```markdown
# Good
reference/api-guide.md
scripts/validate-input.py

# Bad
Reference/APIGuide.md
scripts\validate_input.py
```

## Portable Path References

Use `{baseDir}` for portable paths within skills:

```markdown
## Scripts

Run the analyzer:
python {baseDir}/scripts/analyze.py input.pdf
```

`{baseDir}` resolves to the skill's root directory at runtime, ensuring
portability across installations and platforms.
