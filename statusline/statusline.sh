#!/usr/bin/env bash
# ~/.claude/statusline.sh
# Fires after every Claude Code response.
# Writes $XDG_RUNTIME_DIR/claude-usage.json for the GNOME extension to read.

INPUT=$(cat)
CACHE="${XDG_RUNTIME_DIR:-/tmp}/claude-usage.json"
NOW=$(date +%s)

if command -v jq &>/dev/null; then
  FIVE=$(echo "$INPUT" | jq -r '.rate_limits.five_hour.used_percentage // empty')
  SEVEN=$(echo "$INPUT" | jq -r '.rate_limits.seven_day.used_percentage // empty')
  RESET=$(echo "$INPUT" | jq -r '.rate_limits.five_hour.resets_at // empty')
  MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude Code"')
else
  FIVE=$(echo "$INPUT" | grep -oP '"five_hour".*?"used_percentage":\s*\K[\d.]+' | head -1)
  SEVEN=$(echo "$INPUT" | grep -oP '"seven_day".*?"used_percentage":\s*\K[\d.]+' | head -1)
  RESET=$(echo "$INPUT" | grep -oP '"five_hour".*?"resets_at":\s*\K\d+' | head -1)
  MODEL="Claude Code"
fi

fmt_pct() {
  local v="$1"
  if [[ -z "$v" || "$v" == "null" ]]; then echo "--"; return; fi
  printf "%.0f%%" "$v"
}

FIVE_FMT=$(fmt_pct "$FIVE")
SEVEN_FMT=$(fmt_pct "$SEVEN")

RESET_STR=""
if [[ "$RESET" =~ ^[0-9]+$ ]] && (( RESET > NOW )); then
  DIFF=$(( RESET - NOW ))
  HH=$(( DIFF / 3600 ))
  MM=$(( (DIFF % 3600) / 60 ))
  RESET_STR=" reset ${HH}h${MM}m"
fi

cat > "$CACHE" <<JSON
{
  "five_hour": "$FIVE_FMT",
  "seven_day": "$SEVEN_FMT",
  "model": "$MODEL",
  "reset_str": "$RESET_STR",
  "updated_at": $NOW
}
JSON

echo "${MODEL}  5h: ${FIVE_FMT}  7d: ${SEVEN_FMT}${RESET_STR}"
