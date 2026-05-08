import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const SHUTDOWN_DIALOG = '/opt/edyou/shutdown-dialog/shutdown_dialog.py';

export default class ShutdownDialogueExtension extends Extension {
    enable() {
        this._settings = this._getSettings();
        this._dialogRunning = false;

        log('[EDYOU Shutdown] enable() called');

        this._wmSettings = new Gio.Settings({ schema: 'org.gnome.desktop.wm.keybindings' });
        this._savedClose = this._wmSettings.get_strv('close');
        this._wmSettings.set_strv('close', []);
        log('[EDYOU Shutdown] close-window binding disabled');

        Main.wm.addKeybinding(
            'shutdown-shortcut',
            this._settings,
            Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW,
            this._onAltF4.bind(this)
        );
        log('[EDYOU Shutdown] addKeybinding registered');
    }

    disable() {
        log('[EDYOU Shutdown] disable() called');
        Main.wm.removeKeybinding('shutdown-shortcut');

        if (this._wmSettings && this._savedClose) {
            this._wmSettings.set_strv('close', this._savedClose);
        }

        this._settings = null;
        this._wmSettings = null;
        this._savedClose = null;
    }

    _getSettings() {
        const schemaDir = this.dir.get_child('schemas');
        const source = Gio.SettingsSchemaSource.new_from_directory(
            schemaDir.get_path(),
            Gio.SettingsSchemaSource.get_default(),
            false
        );
        const schema = source.lookup('org.gnome.shell.extensions.shutdown-dialogue', false);
        if (!schema) {
            log('[EDYOU Shutdown] ERROR: Schema not found at ' + schemaDir.get_path());
            throw new Error('Schema not found');
        }
        return new Gio.Settings({ settings_schema: schema });
    }

    _onAltF4(display, action, deviceId, timestamp) {
        log('[EDYOU Shutdown] _onAltF4 triggered');
        const focusWindow = global.display.get_focus_window();

        if (!focusWindow || this._isDesktop(focusWindow)) {
            this._launchDialog();
        } else {
            log('[EDYOU Shutdown] closing focused window');
            focusWindow.delete(global.get_current_time());
        }
    }

    _isDesktop(window) {
        const type = window.get_window_type();
        const wmClass = (window.get_wm_class() || '').toLowerCase();

        log(`[EDYOU Shutdown] _isDesktop check: type=${type} wmClass=${wmClass}`);

        if (type === Meta.WindowType.DESKTOP || type === Meta.WindowType.DOCK)
            return true;

        if (wmClass.includes('gnome-shell') || wmClass === 'gjs')
            return true;

        if (wmClass === 'nautilus' || wmClass === 'org.gnome.nautilus') {
            try {
                const skip = window.skip_taskbar !== undefined
                    ? window.skip_taskbar
                    : window.is_skip_taskbar();
                if (skip)
                    return true;
            } catch (_e) {
            }
        }

        return false;
    }

    _launchDialog() {
        if (this._dialogRunning) {
            log('[EDYOU Shutdown] dialog already running');
            return;
        }
        log('[EDYOU Shutdown] launching dialog');
        try {
            let envp = GLib.get_environ();
            envp.push('GDK_BACKEND=x11');
            const [, pid] = GLib.spawn_async_with_pipes(
                null,
                ['python3', SHUTDOWN_DIALOG],
                envp,
                GLib.SpawnFlags.SEARCH_PATH,
                null
            );
            this._dialogRunning = true;
            this._dialogPid = pid;
            GLib.child_watch_add(GLib.PRIORITY_DEFAULT, pid, (cpid, status) => {
                log('[EDYOU Shutdown] dialog process exited');
                this._dialogRunning = false;
                this._dialogPid = null;
                GLib.spawn_close_pid(cpid);
            });
            log('[EDYOU Shutdown] dialog launched (pid=' + pid + ')');
        } catch (e) {
            this._dialogRunning = false;
            log('[EDYOU Shutdown] Failed to launch dialog: ' + e.message);
        }
    }
}
