import St      from 'gi://St';
import GLib    from 'gi://GLib';
import Gio     from 'gi://Gio';
import Clutter from 'gi://Clutter';
import { Extension }  from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main      from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';

const CACHE_PATH  = `${GLib.get_user_runtime_dir()}/claude-usage.json`;
const POLL_SECS   = 1;
const STALE_SECS  = 30;

export default class ClaudeUsageExtension extends Extension {
  enable() {
    this._indicator = new PanelMenu.Button(0.0, this.metadata.name, false);

    this._label = new St.Label({
      text: 'Claude Code  loading…',
      style_class: 'claude-usage-label',
      y_align: Clutter.ActorAlign.CENTER,
    });
    this._indicator.add_child(this._label);
    Main.panel.addToStatusArea(this.uuid, this._indicator, 1, 'left');

    this._pollId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, POLL_SECS, () => {
      this._refresh();
      return GLib.SOURCE_CONTINUE;
    });
    this._refresh();
  }

  disable() {
    if (this._pollId) {
      GLib.source_remove(this._pollId);
      this._pollId = null;
    }
    this._indicator?.destroy();
    this._indicator = null;
    this._label = null;
  }

  _refresh() {
    try {
      const file = Gio.File.new_for_path(CACHE_PATH);
      const [ok, bytes] = file.load_contents(null);
      if (!ok) { this._setOffline(); return; }

      const data = JSON.parse(new TextDecoder().decode(bytes));
      const now  = Math.floor(Date.now() / 1000);

      if (!data.updated_at || (now - data.updated_at) > STALE_SECS) {
        this._setOffline();
        return;
      }

      const five  = data.five_hour ?? '--';
      const seven = data.seven_day ?? '--';
      const reset = data.reset_str ?? '';

      this._label.set_text(`Claude Code  5h: ${five}  7d: ${seven}${reset}`);
    } catch (_) {
      this._setOffline();
    }
  }

  _setOffline() {
    this._label?.set_text('Claude Code  offline');
  }
}
