# agent-plugins

Agent plugins, skills, and extensions for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Install as a plugin marketplace

```bash
claude plugin add --marketplace mdsakalu/agent-plugins
```

Then enable individual skills in your Claude Code settings.

## Skills

| Skill | Description |
|---|---|
| [investigating-datadog](skills/investigating-datadog/) | Query Datadog logs, metrics, monitors, hosts, events, and APM traces for debugging and investigation |
| [managing-confluence](skills/managing-confluence/) | Manage Confluence Cloud pages via REST API — create, read, update, delete pages, manage attachments, search content |
| [managing-jira](skills/managing-jira/) | Interact with Jira via Atlassian CLI (ACLI) — tickets, projects, boards, sprints, and more |
| [reflecting-on-skills](skills/reflecting-on-skills/) | Analyzes skill usage after each invocation and suggests improvements. Pairs with the `post-skill-reflect.py` hook |
| [suggesting-skills](skills/suggesting-skills/) | Analyzes Claude Code sessions to identify opportunities for new skills based on work patterns |
| [summarize-meeting](skills/summarize-meeting/) | Generate meeting summaries from Zoom recordings — frame extraction, transcript processing, chat analysis |
| [writing-skills](skills/writing-skills/) | Guide for authoring well-structured Agent Skills — SKILL.md structure, naming conventions, best practices |

## Hooks

| Hook | Description |
|---|---|
| [post-skill-reflect.py](hooks/post-skill-reflect.py) | PostToolUse hook that triggers `reflecting-on-skills` after any skill completes |

## Manual install

Copy individual skills into `~/.claude/skills/`:

```bash
cp -R skills/writing-skills ~/.claude/skills/
```

For the reflection hook:

```bash
cp hooks/post-skill-reflect.py ~/.claude/hooks/
```

Then add to your `~/.claude/settings.json`:

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

## License

MIT
