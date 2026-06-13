# claude-context-injector

Automatically injects useful context into every Claude Code conversation via the `UserPromptSubmit` hook — no manual prompting needed.

## What it injects

| Source | Example output | Default |
|--------|---------------|---------|
| `time` | `Current time: 2026-06-13 22:30:00 CST` | ✅ on |
| `weather` | `Weather: Beijing: ⛅️ +28°C` | off |
| `git` | `Git: branch=main (3 uncommitted changes)` | ✅ on |
| `battery` | `Battery: 82% discharging` | off |
| `cwd` | `Working directory: /Users/you/project` | off |

Claude reads this as background context at the start of every message — like giving it a dashboard of your current state.

## Requirements

- Claude Code
- `jq` (`brew install jq` or `apt install jq`)
- `python3`
- `curl` (for weather)

## Install

```bash
git clone https://github.com/li-mingshuang/claude-context-injector
cd claude-context-injector
bash install.sh
```

Restart Claude Code. Done.

## Configure

Edit `~/.claude-context-injector/config.json`:

```json
{
  "time": true,
  "weather": true,
  "weather_location": "Beijing",
  "git": true,
  "battery": false,
  "cwd": false
}
```

`weather_location` can be a city name, airport code, or coordinates. Leave empty for auto-detect by IP.

## How it works

`install.sh` adds a `UserPromptSubmit` hook to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": "bash ~/.claude-context-injector/gather.sh"
      }]
    }]
  }
}
```

Every time you send a message, `gather.sh` runs, collects enabled data sources, and outputs a JSON blob that Claude Code injects as `additionalContext` — so Claude sees it as part of the conversation context before generating a response.

## Uninstall

```bash
bash uninstall.sh
```

## Extending

Add a new source to `gather.sh`:

```bash
# ── Your custom source ────────────────────────────────────────────────────────
if [ "$(get_config my_source)" = "true" ]; then
  DATA=$(your-command-here)
  [ -n "$DATA" ] && LINES+=("My source: $DATA")
fi
```

Add the toggle to `config.json`:
```json
{ "my_source": true }
```

## License

MIT
