---
name: reflecting-on-skills
description: Analyzes skill usage and suggests improvements. Automatically invoked after other skills via PostToolUse hook. Enables continuous improvement through self-reflection on errors, inefficiencies, and gaps.
allowed-tools: Bash, Read, Edit, Task, AskUserQuestion
license: MIT
metadata:
  version: 2.0.0
  updated: 2026-01-08
  spec-version: agentskills.io/2026
compatibility: |
  Claude Code only. Uses PostToolUse hooks and Task tool for background
  subagent analysis. Not portable to Claude apps or API without hook infrastructure.
---

# Reflecting on Skills

This skill is automatically triggered after any other skill completes (via a PostToolUse hook).

## Platform Compatibility

> **Claude Code Only**: This skill uses PostToolUse hooks and the Task tool for
> background subagent execution. These features are specific to Claude Code and
> not available in Claude apps or via the API.

For the cross-platform Agent Skills specification, see [agentskills.io](https://agentskills.io).

## Instructions

When invoked after another skill completes:

1. **Identify the skill** - Determine which skill was just used from conversation context

2. **Launch background analysis** - Use the Task tool:
   ```
   Task tool with:
     subagent_type: "general-purpose"
     run_in_background: true
     prompt: [see below]
   ```

3. **Subagent prompt template**:
   ```
   Analyze the skill that was just used in this conversation.

   1. Read the skill's SKILL.md file at: ~/.claude/skills/[skill-name]/SKILL.md
   2. Review the conversation to identify:
      - Errors or exceptions encountered
      - Unclear or missing instructions that caused confusion
      - Edge cases the skill didn't handle
      - Inefficiencies or unnecessary steps
      - Deviations from the skill's guidance (may indicate gaps)

   3. If issues found, draft SPECIFIC improvements:
      - Exact text to add/change in SKILL.md
      - Keep changes minimal and focused
      - Only address observed issues, not hypotheticals

   4. If improvements warranted, use AskUserQuestion:
      - Present the issue observed
      - Show the proposed change
      - Ask: "Apply this improvement to [skill-name]?"

   5. If approved, use Edit tool to update the skill's SKILL.md

   If no issues observed, complete silently without prompting.
   ```

4. **Continue conversation** - Don't wait for reflection to complete

## Hook Configuration

This skill is triggered by a PostToolUse hook in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/post-skill-reflect.py"
          }
        ]
      }
    ]
  }
}
```

The hook script at `~/.claude/hooks/post-skill-reflect.py` excludes this skill to prevent infinite loops.

## What Makes a Good Suggestion

**Good** (observed issue):
- "User got FileNotFoundError - add note about checking file exists"
- "Instructions said X but user needed Y - clarify the step"

**Bad** (hypothetical):
- "Might be nice to add error handling for edge cases"
- "Could improve by adding more examples"

## Complete Example

After `managing-jira` skill completes with an error:

1. **Observed**: User tried `acli jira workitem create --type Epic` and got "Capitalize field required"
2. **Read**: SKILL.md already has Epic limitation in Known Limitations ✓
3. **Analysis**: Limitation exists but user still hit it - maybe needs better visibility
4. **Proposal**: Move Epic limitation to a "Common Pitfalls" callout box
5. **Ask user**: "The Epic creation limitation is documented but easy to miss. Add a Common Pitfalls callout at the top of the Create section?"
6. **If approved**: Edit SKILL.md to add the callout

## When NOT to Suggest Changes

- Skill worked correctly (user error, not skill gap)
- Issue is one-off edge case unlikely to recur
- Fix would add complexity without clear benefit
- The issue is already documented (unless visibility is the problem)
- User explicitly deviated from skill guidance

## Refusal and Escalation

**Refuse** (do not suggest changes):
- Changes would alter security-sensitive code without explicit user review
- The skill involves credentials, API keys, or authentication logic
- Proposed changes affect multiple skills simultaneously
- User has explicitly disabled skill reflection for the session

**Escalate** (always ask before proceeding):
- The proposed change is substantial (more than 10 lines)
- The change affects the skill's core behavior
- Multiple alternative improvements are possible

## Evaluation Checklist

Before proposing a change, verify:

- [ ] Issue was actually observed (not hypothetical)
- [ ] Root cause identified (not just symptoms)
- [ ] Proposed change is minimal and focused
- [ ] Change follows existing skill patterns
- [ ] Change maintains backward compatibility
- [ ] Similar issue not already documented elsewhere

## Troubleshooting

- **Hook not triggering**: Check `~/.claude/settings.json` has the PostToolUse hook configured per Hook Configuration section
- **Infinite loop**: Ensure `post-skill-reflect.py` excludes "reflecting-on-skills"
- **Subagent not finding skill**: Verify skill path uses `~/.claude/skills/[skill-name]/SKILL.md` format
- **No improvements suggested**: This is expected when skills work correctly - silence is success
