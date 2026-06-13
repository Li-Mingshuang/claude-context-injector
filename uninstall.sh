#!/bin/bash
set -e

INSTALL_DIR="$HOME/.claude-context-injector"
SETTINGS="$HOME/.claude/settings.json"

echo "Uninstalling claude-context-injector..."

# ── Remove hook from settings.json ────────────────────────────────────────────
if [ -f "$SETTINGS" ]; then
  python3 - <<EOF
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
gather_path = os.path.expanduser("~/.claude-context-injector/gather.sh")
hook_command = f"bash {gather_path}"

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.get("hooks", {}).get("UserPromptSubmit", [])
filtered = [
    g for g in hooks
    if not any(h.get("command") == hook_command for h in g.get("hooks", []))
]

if len(filtered) < len(hooks):
    settings["hooks"]["UserPromptSubmit"] = filtered
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
    print("  Hook removed from ~/.claude/settings.json")
else:
    print("  Hook not found in ~/.claude/settings.json")
EOF
fi

# ── Remove install directory ──────────────────────────────────────────────────
if [ -d "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR"
  echo "  Removed $INSTALL_DIR"
fi

echo ""
echo "✓ Uninstalled. Restart Claude Code to apply."
