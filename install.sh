#!/bin/bash
set -e

INSTALL_DIR="$HOME/.claude-context-injector"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing claude-context-injector..."

# ── 1. Create install directory ───────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"

# ── 2. Copy gather script ─────────────────────────────────────────────────────
cp "$SCRIPT_DIR/bin/gather.sh" "$INSTALL_DIR/gather.sh"
chmod +x "$INSTALL_DIR/gather.sh"

# ── 3. Copy default config (only if not exists) ───────────────────────────────
if [ ! -f "$INSTALL_DIR/config.json" ]; then
  cp "$SCRIPT_DIR/config.example.json" "$INSTALL_DIR/config.json"
  echo "  Created $INSTALL_DIR/config.json"
else
  echo "  Kept existing $INSTALL_DIR/config.json"
fi

# ── 4. Add hook to ~/.claude/settings.json ────────────────────────────────────
mkdir -p "$(dirname "$SETTINGS")"
[ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"

python3 - <<EOF
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
gather_path = os.path.expanduser("~/.claude-context-injector/gather.sh")
hook_command = f"bash {gather_path}"

with open(settings_path) as f:
    settings = json.load(f)

settings.setdefault("hooks", {}).setdefault("UserPromptSubmit", [])

# Check if already installed
already = any(
    any(h.get("command") == hook_command for h in group.get("hooks", []))
    for group in settings["hooks"]["UserPromptSubmit"]
)

if not already:
    settings["hooks"]["UserPromptSubmit"].append({
        "hooks": [{"type": "command", "command": hook_command}]
    })
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
    print("  Hook added to ~/.claude/settings.json")
else:
    print("  Hook already present in ~/.claude/settings.json")
EOF

echo ""
echo "✓ Done! Restart Claude Code for the hook to take effect."
echo ""
echo "Configure which sources to enable:"
echo "  $INSTALL_DIR/config.json"
echo ""
echo "Available sources: time, weather, git, battery, cwd"
