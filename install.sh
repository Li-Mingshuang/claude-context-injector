#!/bin/bash
# Fallback install script — copies skill to ~/.claude/skills/context-injector
# and registers the hook. Prefer the Skill method (see README).
set -e

SKILL_DIR="$HOME/.claude/skills/context-injector"
CONFIG_DIR="$HOME/.claude-context-injector"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing claude-context-injector..."

# 1. Copy skill to ~/.claude/skills/context-injector
mkdir -p "$SKILL_DIR/bin"
cp "$SCRIPT_DIR/skill/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$SCRIPT_DIR/skill/bin/gather.sh" "$SKILL_DIR/bin/gather.sh"
chmod +x "$SKILL_DIR/bin/gather.sh"
echo "  Skill installed to $SKILL_DIR"

# 2. Create default config
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/config.json" ]; then
  cat > "$CONFIG_DIR/config.json" << 'EOF'
{
  "time": true,
  "weather": false,
  "weather_location": "",
  "git": true,
  "battery": false,
  "cwd": false,
  "custom": []
}
EOF
  echo "  Created $CONFIG_DIR/config.json"
fi

# 3. Register hook
mkdir -p "$(dirname "$SETTINGS")"
[ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"

python3 - <<EOF
import json, os
settings_path = os.path.expanduser("~/.claude/settings.json")
gather_path = os.path.expanduser("~/.claude/skills/context-injector/bin/gather.sh")
hook_cmd = f"bash {gather_path}"

with open(settings_path) as f:
    settings = json.load(f)

settings.setdefault("hooks", {}).setdefault("UserPromptSubmit", [])

already = any(
    any(h.get("command") == hook_cmd for h in g.get("hooks", []))
    for g in settings["hooks"]["UserPromptSubmit"]
)

if not already:
    settings["hooks"]["UserPromptSubmit"].append({
        "hooks": [{"type": "command", "command": hook_cmd}]
    })
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
    print("  Hook registered")
else:
    print("  Hook already set")
EOF

echo ""
echo "✓ Done. Restart Claude Code to activate."
echo "  Edit $CONFIG_DIR/config.json to configure sources."
