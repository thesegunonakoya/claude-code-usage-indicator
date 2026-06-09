#!/usr/bin/env bash
set -euo pipefail

EXT_UUID="claude-code-usage@thesegunonakoya.github.io"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$EXT_UUID"
STATUSLINE_DST="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"

GREEN='\033[0;32m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }

gnome-extensions disable "$EXT_UUID" 2>/dev/null || true
ENABLED=$(gsettings get org.gnome.shell enabled-extensions)
if [[ "$ENABLED" == *"'$EXT_UUID'"* ]]; then
  NEW=$(echo "$ENABLED" | sed -e "s/, '$EXT_UUID'//" -e "s/'$EXT_UUID', //" -e "s/\['$EXT_UUID'\]/[]/")
  gsettings set org.gnome.shell enabled-extensions "$NEW"
fi
rm -rf "$EXT_DIR"
info "Removed GNOME extension"

rm -f "$STATUSLINE_DST"
info "Removed statusline script"

rm -f "${XDG_RUNTIME_DIR:-/tmp}/claude-usage.json"
info "Removed cache file"

if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
  TMP=$(mktemp)
  jq 'del(.statusLine)' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
  info "Removed statusLine key from $SETTINGS"
fi

echo ""
info "Uninstall complete. Restart GNOME Shell to clear the indicator."
