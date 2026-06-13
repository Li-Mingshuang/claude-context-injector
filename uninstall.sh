#!/bin/bash
set -e

SKILL_DIR="$HOME/.claude/skills/context-injector"
CONFIG_DIR="$HOME/.claude-context-injector"
SETTINGS="$HOME/.claude/settings.json"
GATHER="$SKILL_DIR/bin/gather.sh"

echo "Uninstalling claude-context-injector..."

# Remove hook
if [ -f "$SETTINGS" ]; then
  python3 - <<EOF
import json, os
settings_path = os.path.expanduser("~/.claude/settings.json")
hook_cmd = "bash $GATHER"

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.get("hooks", {}).get("UserPromptSubmit", [])
settings["hooks"]["UserPromptSubmit"] = [
    g for g in hooks
    if not any(h.get("command") == hook_cmd for h in g.get("hooks", []))
]
with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
print("  Hook removed")
EOF
fi

# Remove skill
[ -d "$SKILL_DIR" ] && rm -rf "$SKILL_DIR" && echo "  Removed $SKILL_DIR"

# Config is kept intentionally — remove manually if needed
echo ""
echo "✓ Done. Restart Claude Code to apply."
echo "  Config kept at $CONFIG_DIR (remove manually if needed)"
