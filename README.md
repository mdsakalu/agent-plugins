# agent-plugins

A marketplace of agent plugins, skills, and extensions for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Install the marketplace

```bash
/plugin marketplace add mdsakalu/agent-plugins
```

Then install individual plugins:

```bash
/plugin install creating-mermaid-diagrams@agent-plugins
/plugin install investigating-datadog@agent-plugins
/plugin install managing-confluence@agent-plugins
/plugin install managing-jira@agent-plugins
/plugin install reflecting-on-skills@agent-plugins
/plugin install suggesting-skills@agent-plugins
/plugin install summarize-meeting@agent-plugins
/plugin install writing-skills@agent-plugins
```

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [creating-mermaid-diagrams](creating-mermaid-diagrams/) | Generate GitHub-compatible Mermaid diagrams with tested color palettes, local preview, and gist-based GitHub rendering |
| [investigating-datadog](investigating-datadog/) | Query Datadog logs, metrics, monitors, hosts, events, and APM traces for debugging and investigation |
| [managing-confluence](managing-confluence/) | Manage Confluence Cloud pages via REST API — create, read, update, delete pages, manage attachments, and search content |
| [managing-jira](managing-jira/) | Interact with Jira via Atlassian CLI — create, search, and manage tickets, projects, boards, and sprints |
| [reflecting-on-skills](reflecting-on-skills/) | Analyze skill usage after each invocation and suggest improvements via PostToolUse hook-driven self-reflection |
| [suggesting-skills](suggesting-skills/) | Analyze Claude Code sessions to identify repeated patterns and suggest new skills based on usage |
| [summarize-meeting](summarize-meeting/) | Generate comprehensive meeting summaries from Zoom recordings — frame extraction, transcript processing, and chat analysis |
| [writing-skills](writing-skills/) | Guide for authoring well-structured Agent Skills — SKILL.md structure, naming conventions, and best practices |

## Plugin Details

### creating-mermaid-diagrams

Generates GitHub-compatible Mermaid diagrams that render correctly in markdown files, pull requests, issues, and comments. Includes 24 named color themes tested on both GitHub light and dark modes, local SVG/PNG preview via mermaid CLI, and gist-based GitHub rendering preview.

**Requires:** Optional: `npx @mermaid-js/mermaid-cli` for local preview, `gh` CLI for gist preview.

### investigating-datadog

Queries Datadog for debugging and investigation using a Python CLI tool (`dd.py`). Supports log search, metric queries, monitor status, host listing, event viewing, APM trace search, and comprehensive investigation with timeline visualization.

**Requires:** `uv`, `DD_API_KEY` and `DD_APP_KEY` environment variables.

### managing-confluence

Manages Confluence Cloud pages via REST API with bash helper functions. Supports CRUD operations on pages, attachment management, CQL search, space management, and intelligent features like saved queries and learned templates.

**Requires:** `curl`, `python3`, `CONFLUENCE_EMAIL`, `CONFLUENCE_API_TOKEN`, and `CONFLUENCE_DOMAIN` environment variables.

### managing-jira

Interacts with Jira via Atlassian CLI (ACLI). Supports ticket CRUD, JQL search, sprint management, board operations, bulk edits, ADF-formatted descriptions, and intelligent features like saved queries and smart epic assignment.

**Requires:** Atlassian CLI (`acli`) installed and authenticated.

### reflecting-on-skills

Automatically triggered after any other skill completes via a PostToolUse hook. Analyzes skill usage for errors, inefficiencies, and gaps, then proposes targeted improvements to SKILL.md files. Includes the `post-skill-reflect.py` hook script.

**Requires:** Claude Code with PostToolUse hook support.

### suggesting-skills

Analyzes Claude Code sessions to identify opportunities for new skills. Detects repeated patterns, complex multi-step workflows, external tool integrations, and pain points. Saves suggestions to `~/.claude/skill-suggestions/` for later review and implementation.

**Requires:** Claude Code with Task tool support.

### summarize-meeting

Generates comprehensive meeting summaries from Zoom recordings. Extracts frames via ffmpeg, processes VTT transcripts, analyzes chat logs, and produces detailed documentation with visual timelines, executive summaries, and complete frame catalogues.

**Requires:** `ffmpeg`, Python 3.10+. Optional: `whisper.cpp`, `steipete/summarize`.

### writing-skills

Guides through creating well-structured Agent Skills following the [agentskills.io](https://agentskills.io) open specification. Includes skill initialization scripts, validation tools, naming conventions, structural patterns, and best practices for cross-platform portability.

## Manual Install

Copy individual plugin skills into `~/.claude/skills/`:

```bash
cp -R investigating-datadog/skills/investigating-datadog ~/.claude/skills/
```

For the reflection hook (part of `reflecting-on-skills`):

```bash
cp reflecting-on-skills/hooks/post-skill-reflect.py ~/.claude/hooks/
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
