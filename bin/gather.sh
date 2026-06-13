#!/bin/bash
# claude-context-injector: gather.sh
# Collects context from enabled sources and outputs JSON for Claude Code's
# UserPromptSubmit hook to inject as additionalContext.

CONFIG="$HOME/.claude-context-injector/config.json"

get_config() {
  jq -r ".$1 // false" "$CONFIG" 2>/dev/null || echo "false"
}

LINES=()

# ── Time ──────────────────────────────────────────────────────────────────────
if [ "$(get_config time)" = "true" ]; then
  LINES+=("Current time: $(date '+%Y-%m-%d %H:%M:%S %Z')")
fi

# ── Weather (wttr.in, free, no API key) ───────────────────────────────────────
if [ "$(get_config weather)" = "true" ]; then
  LOCATION=$(get_config weather_location)
  [ "$LOCATION" = "false" ] && LOCATION=""
  W=$(curl -s --max-time 3 "wttr.in/${LOCATION}?format=3" 2>/dev/null)
  [ -n "$W" ] && LINES+=("Weather: $W")
fi

# ── Git ───────────────────────────────────────────────────────────────────────
if [ "$(get_config git)" = "true" ]; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    STATUS=""
    [ "$DIRTY" -gt 0 ] && STATUS=" (${DIRTY} uncommitted changes)"
    LINES+=("Git: branch=${BRANCH}${STATUS}")
  fi
fi

# ── Battery (macOS) ───────────────────────────────────────────────────────────
if [ "$(get_config battery)" = "true" ]; then
  BAT=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%' | head -1)
  CHARGING=$(pmset -g batt 2>/dev/null | grep -o 'charging\|discharging\|charged' | head -1)
  [ -n "$BAT" ] && LINES+=("Battery: ${BAT} ${CHARGING}")
fi

# ── Working directory ─────────────────────────────────────────────────────────
if [ "$(get_config cwd)" = "true" ]; then
  LINES+=("Working directory: $(pwd)")
fi

# ── Build context and output JSON ─────────────────────────────────────────────
if [ ${#LINES[@]} -eq 0 ]; then
  exit 0
fi

CTX=$(printf '%s\n' "${LINES[@]}")

python3 -c "
import sys, json
ctx = sys.stdin.read().strip()
if ctx:
    print(json.dumps({
        'hookSpecificOutput': {
            'hookEventName': 'UserPromptSubmit',
            'additionalContext': ctx
        }
    }))
" <<< "$CTX"
