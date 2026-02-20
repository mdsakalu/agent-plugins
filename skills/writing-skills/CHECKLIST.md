# Skill Quality Checklist

Copy and use this checklist before publishing a skill.

## Automated Validation

Run the validation script first:

```bash
python ~/.claude/skills/writing-skills/scripts/quick_validate.py path/to/skill
```

This checks: frontmatter format, name conventions, description requirements.

## Core Quality

```
- [ ] name: max 64 chars, lowercase/numbers/hyphens only
- [ ] name: no reserved words (anthropic, claude)
- [ ] name: matches directory name
- [ ] description: non-empty, max 1024 chars
- [ ] description: written in third person
- [ ] description: includes what skill does AND when to use it
- [ ] description: includes specific trigger words/contexts
- [ ] allowed-tools: listed if skill needs tool autonomy
- [ ] license: if provided, max 256 chars (optional)
- [ ] metadata: valid YAML map if provided (optional)
- [ ] compatibility: if provided, max 500 chars (optional)
- [ ] SKILL.md body: under 500 lines
- [ ] Additional details: in separate reference files
- [ ] No time-sensitive information (or in "old patterns" section)
- [ ] Consistent terminology throughout
- [ ] Examples are concrete, not abstract
- [ ] File references: one level deep only
- [ ] Progressive disclosure: used appropriately
- [ ] Workflows: have clear, numbered steps
```

## Invocation Control (if applicable)

```
- [ ] disable-model-invocation: set to true for user-only workflows
- [ ] user-invocable: set to false for Claude-only background knowledge
- [ ] argument-hint: provided if skill accepts arguments
- [ ] context: fork set if skill should run in isolated subagent
- [ ] agent: specified if using context: fork (Explore, Plan, etc.)
```

## Structure

```
- [ ] SKILL.md exists with valid YAML frontmatter
- [ ] Quick start section with minimal working example
- [ ] Instructions are clear and actionable
- [ ] File paths use forward slashes (not backslashes)
- [ ] Directory structure is logical and documented
```

## Cross-Platform Compatibility

```
- [ ] compatibility field documents platform requirements
- [ ] Platform-specific features clearly noted
- [ ] Core instructions work across platforms where possible
- [ ] {baseDir} used for portable path references
- [ ] External dependencies documented in compatibility
- [ ] No hardcoded absolute paths (except in examples)
```

## Code and Scripts (if applicable)

```
- [ ] Scripts handle errors explicitly (don't punt to Claude)
- [ ] No "magic numbers" - all constants are justified/documented
- [ ] Required packages are listed
- [ ] Scripts have clear documentation
- [ ] Validation/verification steps for critical operations
- [ ] Feedback loops included for quality-critical tasks
```

## Testing

```
- [ ] Tested with representative tasks
- [ ] Skill activates when expected
- [ ] Instructions are clear during use
- [ ] Edge cases handled appropriately
```

## Evaluation Checklist (for skills that produce output)

```
- [ ] Quality criteria defined for skill outputs
- [ ] Examples show both good and bad output
- [ ] Validation steps included where applicable
- [ ] Refusal conditions documented (when NOT to proceed)
- [ ] Escalation criteria defined (when to ask user)
```

## Quick Self-Review Questions

Before publishing, ask yourself:

1. **Would a new team member understand this?**
   - Is the quick start actually quick?
   - Are instructions self-contained?

2. **Is every token justified?**
   - Does Claude already know this?
   - Can this explanation be shorter?

3. **Does the description work for discovery?**
   - Would Claude select this skill for the intended tasks?
   - Are trigger words specific enough?

4. **Is the structure discoverable?**
   - Can Claude find what it needs?
   - Are references clearly signposted?

## Common Issues to Check

| Issue | Check |
|-------|-------|
| Wrong point of view | Description says "I can" or "You can" instead of third person |
| Too vague | Description is "Helps with files" instead of specific |
| Missing triggers | Description doesn't say when to use the skill |
| Over-explained | Includes info Claude already knows (what PDFs are, etc.) |
| Too many options | Offers 5 ways to do something instead of recommending one |
| Nested references | SKILL.md → file1.md → file2.md → actual info |
| Magic numbers | Constants like `TIMEOUT = 47` without explanation |
| Error punting | Scripts that just `raise` without handling |
| Name mismatch | Skill name doesn't match directory name |
| Wrong fork use | `context: fork` on guideline-only skills (no task) |
| Missing $ARGUMENTS | Skill accepts args but doesn't use `$ARGUMENTS` |
| Dangerous auto-invoke | Side-effect skills without `disable-model-invocation: true` |

## Final Validation

```
- [ ] Run quick_validate.py - does it pass?
- [ ] Read SKILL.md aloud - does it flow?
- [ ] Try the quick start - does it work?
- [ ] Check total line count of SKILL.md (wc -l)
- [ ] Verify all referenced files exist
- [ ] Test with a fresh Claude conversation
- [ ] Delete unused example files from init
```
