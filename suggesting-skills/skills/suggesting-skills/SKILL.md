---
name: suggesting-skills
description: Analyzes current Claude Code session to suggest new skills based on work patterns. Saves suggestions to ~/.claude/skill-suggestions/ for later review. Invoke with /suggest-skills to analyze session or /review-suggestions to review and implement saved suggestions.
allowed-tools: Read, Write, Glob, Grep, Task, AskUserQuestion
license: MIT
metadata:
  version: 1.0.0
  updated: 2026-01-15
  spec-version: agentskills.io/2026
compatibility: |
  Claude Code only. Uses Task tool for subagent analysis to preserve context.
  Designed to run pre-compaction to capture insights before context is lost.
---

# Suggesting Skills

Analyzes Claude Code sessions to identify opportunities for new skills based on:
- Repeated patterns that could be codified
- Complex multi-step workflows done manually
- External tool integrations that could be standardized
- Tasks requiring significant back-and-forth that could be streamlined

## Storage Location

All suggestions are saved to: `~/.claude/skill-suggestions/`

Each suggestion is a separate markdown file with timestamp to avoid conflicts:
```
~/.claude/skill-suggestions/
├── 2026-01-15-143052-api-testing.md
├── 2026-01-15-160823-log-analysis.md
└── ...
```

## Commands

### /suggest-skills - Analyze Current Session

When invoked, analyze the current session for skill opportunities.

**Analysis Criteria:**

1. **Repeated Patterns** - Look for tasks done multiple times with similar structure
   - Same sequence of tool calls repeated
   - Similar prompts asking for the same type of work
   - Copy-paste patterns that could be templated

2. **Complex Workflows** - Multi-step processes that could be codified
   - Tasks requiring 5+ sequential steps
   - Workflows with conditional logic or decision points
   - Processes that required user clarification mid-stream

3. **Tool Integrations** - External tools or APIs used that could be standardized
   - CLI tools with complex flag combinations
   - API calls with specific patterns
   - Data transformations or parsing

4. **Pain Points** - Areas where the session struggled
   - Multiple attempts to get something right
   - Errors that required recovery steps
   - Tasks where instructions were unclear

**Suggestion Format:**

For each potential skill identified, save a file to `~/.claude/skill-suggestions/` with:

```markdown
# Skill Suggestion: [Name]

**Generated:** [timestamp]
**Session Context:** [brief description of what was being worked on]

## Observed Pattern

[Description of what was observed in the session]

## Proposed Skill

**Name:** [suggested-skill-name]
**Description:** [one-line description]

### What It Would Do

[2-3 sentences explaining the skill's purpose]

### Example Usage

[Example of how a user would invoke/use this skill]

### Key Components

- [Component 1]
- [Component 2]
- ...

## Evidence From Session

[Specific examples from the session that support this suggestion]

## Implementation Notes

[Any technical considerations for implementing this skill]

---
Status: pending
```

**File Naming:**
```
YYYY-MM-DD-HHMMSS-skill-name-slug.md
```

**After Analysis:**

1. Summarize findings to user
2. List any suggestions saved
3. Remind user they can run `/review-suggestions` later

### /review-suggestions - Review and Implement

When invoked, help the user review existing suggestions.

**Workflow:**

1. **List Suggestions** - Show all pending suggestions in `~/.claude/skill-suggestions/`
   ```
   Found 3 pending skill suggestions:
   1. api-testing (2026-01-15) - Standardized API endpoint testing workflow
   2. log-analysis (2026-01-15) - Parse and summarize application logs
   3. db-migrations (2026-01-14) - Database migration management
   ```

2. **User Selection** - Use AskUserQuestion to let user choose:
   - Review a specific suggestion
   - Review all suggestions
   - Delete outdated suggestions

3. **For Each Review:**
   - Read and present the suggestion
   - Ask user:
     - **Accept** - Proceed to create the skill
     - **Modify** - Edit the suggestion before implementing
     - **Defer** - Keep for later
     - **Reject** - Delete the suggestion

4. **If Accepted:**
   - Use the `writing-skills` skill to create the new skill
   - Mark suggestion as `implemented` (update Status line)
   - Move file to `~/.claude/skill-suggestions/implemented/`

5. **If Rejected:**
   - Delete the suggestion file
   - Or move to `~/.claude/skill-suggestions/rejected/` if user wants history

## Running as Subagent (Pre-Compaction)

This skill is designed to run as a subagent to preserve the full session context. When run as a subagent, it gets its own context window and can analyze the entire conversation before any compaction occurs.

**Best Practice:** Run `/suggest-skills` at the end of complex sessions before context is compacted, or when you notice you're doing repetitive work.

**How to invoke as subagent:**

The `/suggest-skills` command should launch analysis in a background subagent:

```
Task tool with:
  subagent_type: "general-purpose"
  run_in_background: true
  prompt: [analysis prompt - see below]
```

**Subagent Analysis Prompt:**
```
You are analyzing a Claude Code session to identify skill opportunities.

Review the conversation history and look for:
1. Repeated patterns (same type of task done multiple times)
2. Complex workflows (multi-step processes with 5+ steps)
3. Tool integrations (external tools used with specific patterns)
4. Pain points (errors, retries, unclear instructions)

For each opportunity found:
1. Create a suggestion file in ~/.claude/skill-suggestions/
2. Use filename format: YYYY-MM-DD-HHMMSS-skill-name.md
3. Follow the suggestion template in the skill documentation
4. Be specific - include concrete examples from the session

Focus on patterns that would genuinely benefit from codification.
Do NOT suggest skills for one-off tasks or trivial operations.

After saving suggestions, output a brief summary of what was found.
```

**Future Enhancement:** If Claude Code adds a PreCompact hook type, this skill could be triggered automatically before context compaction

## What Makes a Good Suggestion

**Good candidates:**
- Task was done 2+ times with same pattern
- Workflow required 5+ steps that could be scripted
- External tool had non-obvious configuration
- Process required domain knowledge that could be documented

**Poor candidates:**
- One-time tasks unlikely to recur
- Simple operations Claude already handles well
- Tasks too specific to one codebase
- Operations that would require constant updates

## Example Suggestions

### Good Example
```markdown
# Skill Suggestion: reviewing-prs

**Observed Pattern:** User asked for PR review 3 times, each time
specifying the same criteria (security, performance, test coverage).

**What It Would Do:** Standardize PR review with configurable checklists
for different review types (security-focused, performance-focused, etc.)
```

### Poor Example
```markdown
# Skill Suggestion: fixing-typo-in-readme

**Observed Pattern:** User fixed a typo in README.md

[Too specific, one-time task, not worth a skill]
```

## Troubleshooting

- **No suggestions generated**: Session may not have had automatable patterns
- **Too many suggestions**: Be more selective, focus on recurring patterns
- **Suggestion directory not found**: Run `mkdir -p ~/.claude/skill-suggestions`
