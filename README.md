# Claude Code Usage Indicator

A GNOME Shell top-bar indicator that shows your [Claude Code](https://claude.com/claude-code) 5-hour and 7-day usage percentages in real time — refreshed every second.

![Claude Code usage indicator in the GNOME top bar](docs/screenshot.png)

## How it works

```
claude code (statusLine hook)
    │  fires after every response, pipes JSON to stdin
    ↓
~/.claude/statusline.sh
    │  parses rate_limits fields, writes to shared file
    ↓
$XDG_RUNTIME_DIR/claude-usage.json     ← shared state (per-user tmpfs, no disk churn)
    ↑
GNOME Shell extension                  ← polls every 1 s
    │
    ↓
Top bar label: "Claude Code  5h: 19%  7d: 5%"
```

Claude Code runs the statusline script after every response (and every second while a session is open, via `refreshInterval`). The script extracts the `rate_limits` data from the JSON payload and writes a small cache file. The GNOME extension polls that file every second and renders the label, so the indicator tracks your usage in real time. If the file goes stale for more than 30 s, the label switches to `Claude Code  offline`.

## Requirements

- GNOME Shell 45–49
- Claude Code **≥ 2.1.80** — the `rate_limits` field was added to the statusLine payload in this version
- `jq` (recommended; the script falls back to grep parsing without it)

## Install

```bash
git clone https://github.com/thesegunonakoya/claude-code-usage-indicator.git
cd claude-code-usage-indicator
./install.sh
```

The installer:

1. Verifies Claude Code is installed and new enough
2. Copies the statusline script to `~/.claude/statusline.sh`
3. Merges the `statusLine` key into `~/.claude/settings.json` (existing settings are preserved)
4. Installs and enables the GNOME extension

Then restart GNOME Shell:

- **X11** — press <kbd>Alt</kbd>+<kbd>F2</kbd>, type `r`, press <kbd>Enter</kbd>
- **Wayland** — log out and log back in

Start Claude Code; the label appears after the first response.

## Uninstall

```bash
./uninstall.sh
```

Removes the extension, the statusline script, the cache file, and the `statusLine` key from your settings. Restart GNOME Shell to clear the indicator.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `5h: --  7d: --` | Claude Code is older than 2.1.80 and does not emit `rate_limits`. Run `claude update`. |
| `Claude Code  offline` | No Claude Code session has updated the cache in the last 30 s. Start a session. |
| No label in the top bar | GNOME Shell not restarted after install, or the extension is disabled — check `gnome-extensions info claude-code-usage@thesegunonakoya.github.io`. |
| Custom statusline overwritten | The installer replaces any existing `~/.claude/statusline.sh`. Merge your customizations into the new script — whatever it prints to stdout is still your status line. |

## License

[MIT](LICENSE)
