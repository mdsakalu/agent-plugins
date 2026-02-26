---
name: writing-skills
description: Creates well-structured Agent Skills for Claude Code. Guides through SKILL.md structure, naming conventions, and best practices. Use when creating new skills, improving existing ones, or when the user asks about skill authoring.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
license: MIT
metadata:
  version: 3.0.0
  updated: 2026-01-23
  spec-version: agentskills.io/2026
compatibility: |
  Primary platform: Claude Code (filesystem-based skill discovery).
  Concepts apply to all Agent Skills platforms (Claude apps, API).
---

# Writing Skills

## Quick Start

Initialize a new skill:

```bash
python ~/.claude/skills/writing-skills/scripts/init_skill.py my-skill-name
```

Or copy this template manually:

```markdown
---
name: your-skill-name
description: What this skill does and when to use it. Write in third person.
---

# Your Skill Name

## Quick Start
[Minimal working example]

## Instructions
[Clear, step-by-step guidance]
```

Save as `SKILL.md` in `~/.claude/skills/your-skill/` or `.claude/skills/your-skill/`.

**Note:** Custom slash commands (`.claude/commands/`) have been merged into skills. Both work identically, but skills support additional features like bundled files and frontmatter options.

## Agent Skills Open Standard

Skills follow the [agentskills.io](https://agentskills.io) open specification, adopted by 25+ AI tools including Claude Code, Cursor, GitHub Copilot, VS Code, and others.

**Key concepts:**
- **Portability**: Skills are portable across Claude apps, Claude Code, and API
- **Composability**: Skills stack together automatically via description matching
- **Progressive disclosure**: Only load context when needed (token efficiency)

**Platform deployment:**

| Platform | Discovery | Installation |
|----------|-----------|--------------|
| Claude Code | Filesystem (`~/.claude/skills/`) | Manual or plugin marketplace |
| Claude Apps | Skills UI | Upload or marketplace |
| API | Skills API | Programmatic registration |

**Plugin installation** (Claude Code):
```bash
/plugin marketplace add anthropics/skills
```

**Example skills**: [github.com/anthropics/skills](https://github.com/anthropics/skills)

## Creation Process

### 1. Understand with Concrete Examples

Before building, gather examples of how the skill will be used:
- "What would a user say to trigger this skill?"
- "What specific tasks should it handle?"

### 2. Plan Reusable Contents

For each example, identify what would help Claude execute repeatedly:
- **Scripts** for operations that need deterministic reliability
- **References** for documentation Claude should consult
- **Assets** for templates/files used in output

### 3. Initialize the Skill

```bash
python ~/.claude/skills/writing-skills/scripts/init_skill.py skill-name --path ~/.claude/skills
```

### 4. Develop the Skill

Write SKILL.md and create necessary resources. Delete unused example files.

### 5. Validate

```bash
python ~/.claude/skills/writing-skills/scripts/quick_validate.py ~/.claude/skills/skill-name
```

### 6. Iterate

Use the skill, notice inefficiencies, improve, repeat.

## Types of Skill Content

Skills can contain different types of instructions:

### Reference Content (guidelines)

Adds knowledge Claude applies to your current work. Runs inline with conversation context.

```yaml
---
name: api-conventions
description: API design patterns for this codebase
---

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

### Task Content (actions)

Step-by-step instructions for specific actions. Often triggered manually.

```yaml
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
---

Deploy the application:
1. Run the test suite
2. Build the application
3. Push to the deployment target
```

**Tip:** If you use `context: fork` on a guideline-only skill, the subagent gets guidelines but no task, and returns without meaningful output.

## Core Principles

### Conciseness is Critical

The context window is shared. Only add information Claude doesn't already know.

**Good** (~50 tokens):
```markdown
## Extract PDF text
Use pdfplumber:
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

**Bad** (~150 tokens):
```markdown
## Extract PDF text
PDF (Portable Document Format) files are a common file format...
[Claude already knows what PDFs are]
```

### Trigger Words in Descriptions

Claude matches skills by analyzing the `description` field. Include specific
trigger words that users would naturally say:

**Good** (specific triggers):
```yaml
description: Extracts text from PDF files, fills PDF forms, merges PDFs.
  Use when working with PDF documents or when user mentions "PDF", "form filling",
  or "document extraction".
```

**Bad** (vague, no triggers):
```yaml
description: Helps with documents.
```

Think: "What would a user say that should activate this skill?"

### Set Appropriate Degrees of Freedom

Match specificity to task fragility:

| Freedom Level | Use When | Example |
|---------------|----------|---------|
| **High** (text instructions) | Multiple valid approaches, context-dependent | "Use your judgment for formatting" |
| **Medium** (templates with params) | Preferred pattern exists, some variation OK | "Follow this template, adapt sections as needed" |
| **Low** (exact scripts) | Fragile operations, consistency critical | "Run this exact script with these parameters" |

### Progressive Disclosure

Keep SKILL.md under 500 lines. Split detailed content into separate files:

```
my-skill/
├── SKILL.md        # Overview, quick start (<500 lines)
├── scripts/        # Executable code
├── references/     # Detailed docs (loaded on-demand)
└── assets/         # Templates, images (not loaded into context)
```

Reference with: `See [REFERENCE.md](references/reference.md) for details`

## What NOT to Include

Skills should only contain essential files. Do NOT create:
- README.md, INSTALLATION_GUIDE.md, CHANGELOG.md
- User-facing documentation
- Setup/testing procedures
- Auxiliary context about the creation process

## Structure Requirements

See [STRUCTURE.md](STRUCTURE.md) for complete requirements:
- YAML frontmatter validation rules
- Naming conventions (use gerund form: `writing-skills`, `processing-pdfs`)
- Description guidelines (third person, specific triggers)
- File organization patterns

## Common Patterns

See [PATTERNS.md](PATTERNS.md) for detailed examples:
- **Template pattern**: Output format templates (strict vs flexible)
- **Examples pattern**: Input/output pairs for quality
- **Workflow pattern**: Multi-step tasks with checklists
- **Feedback loop**: Validate → fix → repeat cycles
- **Progressive disclosure**: High-level guide with references
- **Subagent pattern**: Run skills in isolated contexts with `context: fork`
- **Dynamic context**: Inject live data using `!`command`` syntax
- **Visual output**: Generate interactive HTML from scripts
- **Invocation control**: Manage who can trigger skills

## Before Publishing

Validate your skill:

```bash
python ~/.claude/skills/writing-skills/scripts/quick_validate.py path/to/skill
```

See [CHECKLIST.md](CHECKLIST.md) for the complete validation checklist.

Quick checks:
- [ ] Description is specific and includes trigger words
- [ ] Description is in third person
- [ ] SKILL.md under 500 lines
- [ ] No time-sensitive information
- [ ] Consistent terminology throughout

## Anti-patterns to Avoid

### Don't offer too many options
```markdown
# Bad: Confusing
"You can use pypdf, or pdfplumber, or PyMuPDF, or..."

# Good: Default with escape hatch
"Use pdfplumber for text extraction. For scanned PDFs requiring OCR, use pdf2image with pytesseract instead."
```

### Don't use nested references
```markdown
# Bad: Too deep
SKILL.md → advanced.md → details.md → actual info

# Good: One level deep
SKILL.md → reference.md (contains actual info)
```

### Don't include time-sensitive information
```markdown
# Bad: Will become wrong
"If you're doing this before August 2025, use the old API."

# Good: Use "old patterns" section
## Current method
Use the v2 API endpoint.

## Old patterns
<details>
<summary>Legacy v1 API (deprecated)</summary>
[Historical context]
</details>
```

### Don't punt errors to Claude
```python
# Bad: Just fails
def process_file(path):
    return open(path).read()

# Good: Handles errors explicitly
def process_file(path):
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        print(f"File {path} not found")
        return None
```

### Don't include proprietary information (for public skills)

If publishing a skill publicly, sanitize examples and references:

```markdown
# Bad: Leaks internal details
curl "https://api.internal-company.com/v2/users"
SPACE_KEY="CompanySecrets"
> "As John from Engineering explained in the Q3 review..."

# Good: Generic examples
curl "https://api.example.com/v2/users"
SPACE_KEY="MYSPACE"
> "As the presenter explained..."
```

**Check for:**
- Internal hostnames, URLs, or IP addresses
- Real employee names or email addresses
- Project codenames or internal tool names
- Space/repo/channel names that reveal company structure
- Quotes or context from internal meetings

## Platform-Specific Notes

### Claude Code

Skills in Claude Code are filesystem-based:
- **Locations**:
  - `~/.claude/skills/` (personal - all projects)
  - `.claude/skills/` (project-specific)
  - Plugin-provided skills
  - Enterprise managed settings
- **Priority**: Enterprise > personal > project (by location)
- **Nested discovery**: Working in `packages/frontend/` also finds `packages/frontend/.claude/skills/`
- **Network**: Full access available
- **Autonomy**: Use `allowed-tools` to reduce approval prompts
- **Subagents**: Use `context: fork` with `agent` field for isolated execution
- **Commands merged**: `.claude/commands/` files work as skills (skills take precedence on name conflict)

### Claude Apps (claude.ai)

- Skills configured via Skills UI
- Example skills available to paid plans
- Upload custom skills directly
- No filesystem access; use provided data sources

### API Integration

- Register skills via Skills API
- See [Skills API Quickstart](https://docs.claude.com/en/api/skills-guide)
- Programmatic management and versioning

For cross-platform design, keep SKILL.md self-contained and avoid
platform-specific tool references in core instructions.
