# Setup

## 1. Install Dependencies

```bash
cd ~/.claude/skills/investigating-datadog/scripts
uv sync
```

## 2. Get Datadog Credentials

### API Key
1. Go to Datadog → Organization Settings → API Keys
2. Click "New Key" or copy an existing one
3. This key authenticates your requests

### Application Key
1. Go to Datadog → Organization Settings → Application Keys
2. Click "New Key"
3. Name it something like "claude-code"
4. This key authorizes read access

## 3. Store Credentials Securely (Mac Keychain)

**Recommended approach** - stores keys encrypted in macOS Keychain:

```bash
# Store the keys (you'll be prompted or can paste inline)
security add-generic-password -a "$USER" -s "datadog-api-key" -w "YOUR_API_KEY"
security add-generic-password -a "$USER" -s "datadog-app-key" -w "YOUR_APP_KEY"
```

Then add to `~/.zshrc`:

```bash
# Datadog credentials from Keychain
export DD_API_KEY=$(security find-generic-password -a "$USER" -s "datadog-api-key" -w 2>/dev/null)
export DD_APP_KEY=$(security find-generic-password -a "$USER" -s "datadog-app-key" -w 2>/dev/null)
export DD_SITE="datadoghq.com"
```

Reload your shell: `source ~/.zshrc`

### Alternative: Plain text (less secure)

Add directly to `~/.zshrc`:

```bash
export DD_API_KEY="your-api-key-here"
export DD_APP_KEY="your-application-key-here"
export DD_SITE="datadoghq.com"
```

### Site Values by Region

| Region | DD_SITE value |
|--------|---------------|
| US1 (default) | `datadoghq.com` |
| US3 | `us3.datadoghq.com` |
| US5 | `us5.datadoghq.com` |
| EU | `datadoghq.eu` |
| AP1 | `ap1.datadoghq.com` |
| US1-FED | `ddog-gov.com` |

## 4. Configure Claude Code Permissions

To avoid permission prompts, add to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "permissions": {
    "allow": [
      "Bash(uv run:*)",
      "Bash(uv sync:*)"
    ]
  }
}
```

## 5. Verify Setup

```bash
cd ~/.claude/skills/investigating-datadog/scripts
uv run dd.py monitors
```

If successful, you'll see a table of your monitors.

## Troubleshooting

**"DD_API_KEY environment variable not set"**
- Ensure you've exported the variable and reloaded your shell
- Run `echo $DD_API_KEY` to verify it's set
- If using Keychain, verify: `security find-generic-password -a "$USER" -s "datadog-api-key" -w`

**"403 Forbidden"**
- Your Application Key may lack permissions
- Create a new Application Key with broader scope

**"Could not connect"**
- Check DD_SITE matches your Datadog region
- Verify network connectivity to Datadog
