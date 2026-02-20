# Common Skill Patterns

## Template Pattern

Provide templates for output format. Match strictness to requirements.

### Strict Template (API responses, data formats)

```markdown
## Report structure

ALWAYS use this exact template:

# [Analysis Title]

## Executive summary
[One-paragraph overview]

## Key findings
- Finding 1 with data
- Finding 2 with data

## Recommendations
1. Actionable recommendation
2. Actionable recommendation
```

### Flexible Template (adaptable guidance)

```markdown
## Report structure

Sensible default format (adapt as needed):

# [Analysis Title]

## Executive summary
[Overview]

## Key findings
[Adapt sections based on analysis]

## Recommendations
[Tailor to context]
```

## Examples Pattern

For quality-dependent output, provide input/output pairs:

```markdown
## Commit message format

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware

**Example 2:**
Input: Fixed bug where dates displayed incorrectly
Output:
fix(reports): correct date formatting in timezone conversion

Use UTC timestamps consistently across report generation

**Example 3:**
Input: Updated dependencies and refactored error handling
Output:
chore: update dependencies and refactor error handling

- Upgrade lodash to 4.17.21
- Standardize error response format
```

## Workflow Pattern

Break complex operations into clear steps with a trackable checklist.

```markdown
## Form processing workflow

Copy this checklist and track progress:

Task Progress:
- [ ] Step 1: Analyze the form
- [ ] Step 2: Create field mapping
- [ ] Step 3: Validate mapping
- [ ] Step 4: Fill the form
- [ ] Step 5: Verify output

**Step 1: Analyze the form**
Run: `python scripts/analyze_form.py input.pdf`
Output: `fields.json` with extracted fields

**Step 2: Create field mapping**
Edit `fields.json` to add values for each field.

**Step 3: Validate mapping**
Run: `python scripts/validate_fields.py fields.json`
Fix any errors before continuing.

**Step 4: Fill the form**
Run: `python scripts/fill_form.py input.pdf fields.json output.pdf`

**Step 5: Verify output**
Run: `python scripts/verify_output.py output.pdf`
If verification fails, return to Step 2.
```

## Feedback Loop Pattern

Validate → fix → repeat improves quality.

```markdown
## Document editing process

1. Make edits to the document
2. **Validate immediately**: `python scripts/validate.py document/`
3. If validation fails:
   - Review the error message
   - Fix the issues
   - Run validation again
4. **Only proceed when validation passes**
5. Finalize the output
6. Test the result
```

## Conditional Workflow Pattern

Guide through decision points:

```markdown
## Document modification workflow

1. Determine the modification type:

   **Creating new content?** → Follow "Creation workflow"
   **Editing existing content?** → Follow "Editing workflow"

2. Creation workflow:
   - Use appropriate library
   - Build document from scratch
   - Export to final format

3. Editing workflow:
   - Load existing document
   - Modify content directly
   - Validate after each change
   - Save when complete
```

## Progressive Disclosure Pattern

High-level guide with references to detailed content.

### Main SKILL.md

```markdown
# Data Analysis

## Quick start

Load and analyze data:
import pandas as pd
df = pd.read_csv("data.csv")
df.describe()

## Advanced features

**Statistical analysis**: See [STATISTICS.md](STATISTICS.md)
**Visualization**: See [CHARTS.md](CHARTS.md)
**ML integration**: See [ML.md](ML.md)
```

### Domain-specific organization

For skills with multiple domains:

```
analytics-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md (revenue, billing)
    ├── sales.md (pipeline, accounts)
    └── product.md (usage, features)
```

```markdown
# SKILL.md

## Available datasets

**Finance**: Revenue, ARR, billing → See [reference/finance.md](reference/finance.md)
**Sales**: Opportunities, pipeline → See [reference/sales.md](reference/sales.md)
**Product**: API usage, features → See [reference/product.md](reference/product.md)

## Quick search

Find specific metrics:
grep -i "revenue" reference/finance.md
grep -i "pipeline" reference/sales.md
```

## Utility Scripts Pattern

Pre-made scripts are more reliable than generated code.

### Dependency Strategy

For Python scripts, prefer this order:

1. **Standard library only** - Most portable, no install needed
2. **uv inline dependencies** - Portable with automatic dependency resolution
3. **Requirements file** - When dependencies are complex

```python
#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# dependencies = ["pdfplumber>=0.10"]
# ///
```

**Don't go overboard:** Use established libraries for complex tasks (boto3, requests, etc.). Reimplementing AWS auth or HTTP in pure stdlib wastes tokens and adds bugs.

```markdown
## Utility scripts

**analyze.py**: Extract structure from input
python scripts/analyze.py input.pdf > structure.json

Output format:
{
  "field_name": {"type": "text", "location": [100, 200]},
  "signature": {"type": "sig", "location": [150, 500]}
}

**validate.py**: Check for errors
python scripts/validate.py structure.json
# Returns: "OK" or lists errors

**process.py**: Apply transformations
python scripts/process.py input.pdf structure.json output.pdf
```

## Table of Contents for Long Files

For reference files over 100 lines:

```markdown
# API Reference

## Contents
- Authentication and setup
- Core methods (create, read, update, delete)
- Advanced features (batch, webhooks)
- Error handling
- Code examples

## Authentication and setup
...

## Core methods
...
```

## Refusal and Escalation Pattern

Define boundaries for when the skill should refuse or escalate.

```markdown
## Refusal and Escalation

**Refuse** (do not proceed):
- Request involves credentials, API keys, or secrets
- Action would be irreversible without explicit confirmation
- Request is outside the skill's defined scope

**Escalate** (ask user before proceeding):
- Multiple valid approaches exist
- Action affects production systems
- Confidence in interpretation is low
- Change is substantial (define threshold)

**Example escalation:**
"I found two ways to approach this:
1. [Option A] - faster but less flexible
2. [Option B] - more setup but extensible

Which approach would you prefer?"
```

Use this pattern for skills that handle sensitive operations, make decisions, or modify important resources.

## Evaluation Checklist Pattern

Define quality criteria for skill outputs.

```markdown
## Evaluation Checklist

Before finalizing output, verify:

- [ ] Output matches requested format
- [ ] All required fields populated
- [ ] No placeholder text remaining
- [ ] Validation script passes (if applicable)
- [ ] Output is self-contained and complete

**Quality indicators:**

| Criterion | Good | Bad |
|-----------|------|-----|
| Completeness | All sections filled | "[TODO]" markers |
| Accuracy | Matches source data | Hallucinated content |
| Format | Consistent structure | Mixed styles |
```

Use this pattern for skills that generate documents, code, or structured output.

## Subagent Pattern

Run skills in isolated contexts for focused tasks. Use `context: fork` for research, exploration, or parallel work.

### Research Skill

```yaml
---
name: deep-research
description: Research a topic thoroughly using codebase exploration
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:

1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

### Task Execution Skill

```yaml
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
allowed-tools: Bash(git:*) Bash(npm:*)
---

Deploy $ARGUMENTS to production:

1. Run the test suite
2. Build the application
3. Push to the deployment target
4. Verify the deployment succeeded
```

**When to use `context: fork`:**
- Research tasks that shouldn't pollute main conversation
- Parallel exploration of multiple areas
- Tasks with explicit instructions (not just guidelines)

**When NOT to use:**
- Reference/guideline skills ("use these API conventions")
- Skills that need access to conversation context

## Dynamic Context Pattern

Inject live data into skills using shell command preprocessing.

```yaml
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh:*)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task
Summarize this pull request focusing on:
1. What changed and why
2. Potential risks or concerns
3. Suggested reviewers based on code ownership
```

Commands run before Claude sees the content. Claude receives the fully-rendered prompt.

## Visual Output Pattern

Skills can generate interactive HTML for exploring data, debugging, or reports.

```yaml
---
name: codebase-visualizer
description: Generate interactive tree visualization of your codebase
allowed-tools: Bash(python:*)
---

# Codebase Visualizer

Generate an interactive HTML tree view of your project structure.

## Usage

Run the visualization script:
python {baseDir}/scripts/visualize.py .

Creates `codebase-map.html` and opens it in your browser.

## Output features
- Collapsible directories
- File sizes displayed
- Color-coded by file type
- Aggregate directory sizes
```

Pair with a Python script in `scripts/` that generates self-contained HTML.

**Use cases:**
- Dependency graphs
- Test coverage reports
- API documentation
- Database schema visualizations

## Invocation Control Pattern

Control who can invoke skills using frontmatter flags.

### User-only Skills (manual trigger)

```yaml
---
name: deploy
description: Deploy to production
disable-model-invocation: true
---
```

User invokes with `/deploy`. Claude cannot trigger automatically.

### Claude-only Skills (background knowledge)

```yaml
---
name: legacy-system-context
description: Context about the legacy payment system
user-invocable: false
---
```

Claude loads when relevant. Not shown in `/` menu.

### Both (default)

```yaml
---
name: code-review
description: Review code for issues
---
```

User can invoke with `/code-review`. Claude can also load when relevant.

**Decision matrix:**

| Want | Set |
|------|-----|
| Only user triggers | `disable-model-invocation: true` |
| Only Claude loads | `user-invocable: false` |
| Both can invoke | (default, no flags needed) |
