#!/usr/bin/env bash
set -euo pipefail

EXT_UUID="claude-code-usage@thesegunonakoya.github.io"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$EXT_UUID"
STATUSLINE_DST="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"
MIN_MAJOR=2; MIN_MINOR=1; MIN_PATCH=80

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
abort() { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

# ── 1. check claude is installed ───────────────────────────────────
command -v claude &>/dev/null || abort "claude not found. Install Claude Code first."

# ── 2. check claude version >= 2.1.80 ──────────────────────────────
RAW_VERSION=$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
if [[ -z "$RAW_VERSION" ]]; then
  warn "Could not determine Claude Code version. Proceeding anyway."
  warn "The statusLine rate_limits field requires Claude Code >= ${MIN_MAJOR}.${MIN_MINOR}.${MIN_PATCH}."
  warn "If the top bar shows '--' for usage, run: claude update"
else
  IFS='.' read -r V_MAJ V_MIN V_PAT <<< "$RAW_VERSION"
  OLDER=false
  if   (( V_MAJ < MIN_MAJOR )); then OLDER=true
  elif (( V_MAJ == MIN_MAJOR && V_MIN < MIN_MINOR )); then OLDER=true
  elif (( V_MAJ == MIN_MAJOR && V_MIN == MIN_MINOR && V_PAT < MIN_PATCH )); then OLDER=true
  fi
  if [[ "$OLDER" == true ]]; then
    abort "Claude Code $RAW_VERSION is too old.\n       rate_limits data requires >= ${MIN_MAJOR}.${MIN_MINOR}.${MIN_PATCH}.\n       Run: claude update"
  fi
  info "Claude Code $RAW_VERSION — version OK"
fi

# ── 3. check jq (optional but recommended) ─────────────────────────
if ! command -v jq &>/dev/null; then
  warn "jq not found. The statusline script will fall back to grep/sed parsing."
  warn "Install jq for reliability: sudo dnf install jq"
fi

# ── 4. check gnome-shell ───────────────────────────────────────────
command -v gnome-shell &>/dev/null || abort "gnome-shell not found. This tool requires GNOME."

# ── 5. install statusline script ───────────────────────────────────
mkdir -p "$HOME/.claude"
cp statusline/statusline.sh "$STATUSLINE_DST"
chmod +x "$STATUSLINE_DST"
info "Installed statusline script → $STATUSLINE_DST"

# ── 6. merge statusLine key into ~/.claude/settings.json ───────────
if [[ -f "$SETTINGS" ]]; then
  if command -v jq &>/dev/null; then
    TMP=$(mktemp)
    jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline.sh", "padding": 0, "refreshInterval": 10}}' \
      "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
    info "Merged statusLine key into $SETTINGS"
  else
    warn "jq not available — could not auto-merge settings.json."
    warn "Manually add the statusLine block from .claude/settings.json.example"
  fi
else
  cp .claude/settings.json.example "$SETTINGS"
  info "Created $SETTINGS"
fi

# ── 7. install GNOME extension ─────────────────────────────────────
mkdir -p "$EXT_DIR"
cp gnome-extension/metadata.json "$EXT_DIR/"
cp gnome-extension/extension.js  "$EXT_DIR/"
cp gnome-extension/stylesheet.css "$EXT_DIR/"
info "Installed GNOME extension → $EXT_DIR"

# ── 8. enable the extension ────────────────────────────────────────
# gnome-extensions enable fails if the running shell hasn't scanned the
# new extension dir yet (always the case on first install under Wayland),
# so fall back to writing the gsettings list directly.
if ! gnome-extensions enable "$EXT_UUID" 2>/dev/null; then
  ENABLED=$(gsettings get org.gnome.shell enabled-extensions)
  if [[ "$ENABLED" != *"'$EXT_UUID'"* ]]; then
    if [[ "$ENABLED" == "@as []" || "$ENABLED" == "[]" ]]; then
      gsettings set org.gnome.shell enabled-extensions "['$EXT_UUID']"
    else
      gsettings set org.gnome.shell enabled-extensions "${ENABLED%]}, '$EXT_UUID']"
    fi
  fi
fi
info "Extension enabled: $EXT_UUID"

# ── 9. prompt for GNOME Shell restart ──────────────────────────────
echo ""
info "Installation complete."
echo ""
echo "  To activate the top-bar indicator, restart GNOME Shell:"
echo ""
echo "  On X11  →  press Alt+F2, type r, press Enter"
echo "  On Wayland  →  log out and log back in"
echo ""
echo "  Then start Claude Code. The label appears after the first response."
