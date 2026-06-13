#!/bin/bash
# claude-context-injector — gather.sh
# Called by UserPromptSubmit hook. Reads config.json and collects
# enabled context sources, then outputs JSON for Claude Code to inject.

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
  W=$(curl -s --max-time 2 "wttr.in/${LOCATION}?format=3" 2>/dev/null)
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

# ── Custom sources (from config.custom array) ─────────────────────────────────
CUSTOM_COUNT=$(jq -r '.custom | length // 0' "$CONFIG" 2>/dev/null || echo "0")
if [ "$CUSTOM_COUNT" -gt 0 ]; then
  for i in $(seq 0 $((CUSTOM_COUNT - 1))); do
    LABEL=$(jq -r ".custom[$i].label" "$CONFIG" 2>/dev/null)
    CMD=$(jq -r ".custom[$i].command" "$CONFIG" 2>/dev/null)
    ENABLED=$(jq -r ".custom[$i].enabled // true" "$CONFIG" 2>/dev/null)
    if [ "$ENABLED" = "true" ] && [ -n "$CMD" ] && [ "$CMD" != "null" ]; then
      OUT=$(eval "$CMD" 2>/dev/null | head -1)
      [ -n "$OUT" ] && LINES+=("${LABEL}: ${OUT}")
    fi
  done
fi

# ── Output JSON ───────────────────────────────────────────────────────────────
[ ${#LINES[@]} -eq 0 ] && exit 0

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
