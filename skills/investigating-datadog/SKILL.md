---
name: investigating-datadog
description: Queries Datadog for debugging and investigation. Search logs, query metrics, check monitors, list hosts, view events, and search APM traces. Use when the user asks about Datadog data, wants to debug issues, check alerts, or investigate infrastructure.
allowed-tools: Bash, Read, Task, WebFetch
license: MIT
metadata:
  version: 2.0.0
  updated: 2026-01-08
  spec-version: agentskills.io/2026
compatibility: |
  Requires: uv (for dependency management), DD_API_KEY and DD_APP_KEY env vars.
  Dependencies managed via pyproject.toml (datadog-api-client).
  Claude Code only - requires Bash execution and Task tool for subagents.
---

# Investigating Datadog

## Before You Start

**Check authentication:**
```bash
echo "API: ${DD_API_KEY:+set} APP: ${DD_APP_KEY:+set}"
```

If not set, see [SETUP.md](SETUP.md).

## When to Use a Subagent

**Use a subagent for investigations** - when the user wants to understand an error pattern, debug an issue, or answer "when did this start / is it still happening / how often":

```
Use the Task tool with subagent_type="general-purpose" and this prompt:

"Investigate this Datadog issue and return a concise summary:

Query: <the log query or error message>
Service: <service name if known>
Time range: <e.g., 7d, 24h>

Run this command from ~/.claude/skills/investigating-datadog/scripts:
uv run dd.py investigate "<query>" --from <time>

Analyze the output and return a summary with:
1. Status: Is it still happening? When did it start?
2. Volume: How many occurrences? What's the rate?
3. Pattern: Is it constant, increasing, or sporadic?
4. Sources: Which pods/hosts are affected?
5. Recommendation: What should be investigated next?

Keep the summary concise - under 20 lines."
```

**Use direct commands for quick lookups** - simple queries where you just need the data:
- List alerting monitors
- Check recent events
- Quick log search

## Decision Guide

| Goal | Command |
|------|---------|
| "Is this still happening?" | `investigate` |
| "Show me the trend" | `timeline` |
| "Show me recent logs" | `logs` |
| "What's alerting?" | `monitors --status alert` |
| "Check specific metric" | `metrics` |
| "Find affected hosts" | `hosts --filter` |

## Example Output

A good investigation summary returned by the subagent:
```
Status: RESOLVED - Last occurrence 6h ago
Volume: 847 occurrences over 3 days
Pattern: Spike on Dec 20 15:00-18:00, then resolved
Sources: pod-api-7f8d9 (92%), pod-api-3c2a1 (8%)
Recommendation: Check deployment logs around Dec 20 15:00
```

## Troubleshooting

- **Empty results**: Broaden time range (`--from 7d`) or simplify query
- **Auth errors**: Re-run setup in [SETUP.md](SETUP.md)
- **Timeout**: Add `--limit 100` to reduce data volume
- **"Invalid query"**: Check query syntax in [Query Syntax](#query-syntax) section

## Quick Commands

Run from `~/.claude/skills/investigating-datadog/scripts`:

```bash
# List alerting monitors
uv run dd.py monitors --status alert

# Search logs
uv run dd.py logs "service:web status:error" --from 2h

# Query metrics
uv run dd.py metrics "avg:system.cpu.user{*}"

# Full investigation (use subagent instead for cleaner output)
uv run dd.py investigate "error message" --from 7d

# Visual timeline chart
uv run dd.py timeline "error message" --from 48h
```

## Command Reference

### investigate
Comprehensive analysis of a log pattern. Returns first/last occurrence, count, distribution histogram, sources, and samples. Auto-expands time range to find true start.

```bash
uv run dd.py investigate "Failed to connect" --from 7d
uv run dd.py investigate "service:api status:error" --from 24h
```

### timeline
Visual hourly chart of error frequency. Shows severity indicators (🔴🟠🟡🟢), auto-expands to find true start, and indicates if issue is resolved.

```bash
uv run dd.py timeline "error message" --from 48h
uv run dd.py timeline "service:api status:error" --title "API Errors"
```

### logs
Search logs with formatted table output.

```bash
uv run dd.py logs "service:web status:error"
uv run dd.py logs "host:prod-*" --from 2h --limit 500
uv run dd.py logs "error" --json  # Raw JSON
```

### metrics
Query metrics with sparkline visualization.

```bash
uv run dd.py metrics "avg:system.cpu.user{*}"
```

### monitors
List monitors with status icons (🔴🟡🟢).

```bash
uv run dd.py monitors
uv run dd.py monitors --status alert
uv run dd.py monitor 12345  # Single monitor
```

### hosts / events / traces

```bash
uv run dd.py hosts --filter "aws"
uv run dd.py events --from 24h
uv run dd.py traces "service:api @http.status_code:500"
```

## Time Formats

- Relative: `1h`, `30m`, `2d`, `7d`
- ISO: `YYYY-MM-DDTHH:MM:SSZ` (e.g., `2024-01-15T10:00:00Z`)

## Query Syntax

**Logs**: `service:web`, `status:error`, `host:prod-*`, `"exact phrase"`

**Metrics**: `avg:system.cpu.user{*}`, `sum:metric{env:prod} by {host}`

**Spans**: `service:api`, `@http.status_code:500`, `@duration:>1s`
