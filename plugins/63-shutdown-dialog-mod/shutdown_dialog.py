#!/usr/bin/env python3

import subprocess
import sys
import os

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GdkPixbuf

def is_dark_mode():
    try:
        settings = Gtk.Settings.get_default()
        style = settings.get_property("gtk-theme-name").lower()
        if "dark" in style:
            return True
    except:
        pass
    try:
        result = subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"],
            capture_output=True, text=True, timeout=2
        )
        if "dark" in result.stdout.lower():
            return True
    except:
        pass
    return False

def get_logo_path():
    dark = is_dark_mode()
    base = "/usr/local/bin"
    local = os.path.dirname(os.path.abspath(__file__))
    if dark:
        for p in [f"{base}/shutdown-logo-dark.png", f"{local}/shutdown-logo-dark.png"]:
            if os.path.exists(p): return p
    else:
        for p in [f"{base}/shutdown-logo-light.png", f"{local}/shutdown-logo-light.png"]:
            if os.path.exists(p): return p
    return None

class ShutdownDialog(Gtk.Window):
    def __init__(self):
        super().__init__(title="Shut Down EDYOU OS")
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_keep_above(True)
        self.set_default_size(480, 250)
        self.set_size_request(480, 250)

        screen = Gdk.Screen.get_default()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        dark = is_dark_mode()
        bg = "#1e1e1e" if dark else "#f2f2f2"
        fg = "#ffffff" if dark else "#000000"
        btn = "#2d2d2d" if dark else "#e8e8e8"
        btn_h = "#3d3d3d" if dark else "#dcdcdc"
        sep = "#3d3d3d" if dark else "#cccccc"

        css = f"""
            window {{
                background-color: transparent;
                border-radius: 16px;
            }}
            #rounded-bg {{
                background-color: {bg};
                border-radius: 16px;
            }}
            button {{
                background: {btn};
                color: {fg};
                border: none;
                border-radius: 6px;
                padding: 8px 16px;
            }}
            button:hover {{
                background: {btn_h};
            }}
            button:focus {{
                outline: none;
            }}
            combobox {{
                background: {btn};
                color: {fg};
                border: 1px solid {sep};
                border-radius: 4px;
                padding: 4px;
            }}
            label {{
                color: {fg};
            }}
            separator {{
                background: {sep};
                min-height: 1px;
            }}
        """.encode()

        p = Gtk.CssProvider()
        p.load_from_data(css)
        self.get_style_context().add_provider(p, 600)

        self.connect("key-press-event", self.on_key_press)

        outer = Gtk.Box()
        outer.set_name("rounded-bg")
        outer.get_style_context().add_provider(p, 600)
        self.add(outer)

        inner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        inner.set_margin_top(16)
        inner.set_margin_bottom(16)
        inner.set_margin_start(16)
        inner.set_margin_end(16)
        outer.pack_start(inner, True, True, 0)

        path = get_logo_path()
        try:
            if path and os.path.exists(path):
                img = Gtk.Image.new_from_pixbuf(GdkPixbuf.Pixbuf.new_from_file(path).scale_simple(280, 70, 2))
            else:
                img = Gtk.Label(label="EDYOU OS")
                img.get_style_context().add_provider(p, 600)
        except:
            img = Gtk.Label(label="EDYOU OS")
            img.get_style_context().add_provider(p, 600)
        img.set_halign(Gtk.Align.CENTER)
        img.set_valign(Gtk.Align.CENTER)
        inner.pack_start(img, False, False, 0)

        sep = Gtk.HSeparator()
        inner.pack_start(sep, False, False, 0)

        lbl = Gtk.Label(label="What do you want the computer to do?")
        lbl.set_halign(Gtk.Align.CENTER)
        lbl.set_valign(Gtk.Align.CENTER)
        inner.pack_start(lbl, False, False, 0)

        self.combo = Gtk.ComboBoxText()
        for opt in ["Shut Down", "Restart", "Suspend", "Log Out"]:
            self.combo.append_text(opt)
        self.combo.set_active(0)
        self.combo.set_size_request(200, 32)
        self.combo.set_halign(Gtk.Align.CENTER)
        inner.pack_start(self.combo, False, False, 4)

        spacer = Gtk.Box()
        spacer.set_size_request(-1, 16)
        inner.pack_start(spacer, False, False, 0)

        btns = Gtk.Box(spacing=12)
        btns.set_halign(Gtk.Align.CENTER)
        inner.pack_start(btns, False, False, 0)

        for lbl_text, handler in [("OK", self.on_ok), ("Cancel", self.on_cancel), ("Help", self.on_help)]:
            b = Gtk.Button(label=lbl_text)
            b.connect("clicked", handler)
            btns.pack_start(b, False, False, 0)

        self.ok_btn = btns.get_children()[0]
        self.connect("show", lambda w: self.ok_btn.grab_focus())

    def focus_is_within_combo(self, widget):
        while widget is not None:
            if widget is self.combo:
                return True
            widget = widget.get_parent()
        return False

    def on_key_press(self, w, e):
        if e.keyval == 65307:
            self.on_cancel(None)
            return True

        if e.keyval in (65293, 65421):
            focus = self.get_focus()
            if focus is None or focus is self.ok_btn or self.focus_is_within_combo(focus):
                self.on_ok(None)
                return True
            return False

        return False

    def on_ok(self, w):
        act = self.combo.get_active_text()
        self.destroy()
        Gtk.main_quit()
        cmds = {
            "Shut Down": "sudo systemctl poweroff",
            "Restart": "sudo systemctl reboot",
            "Suspend": "sudo systemctl suspend",
            "Log Out": "gnome-session-quit --logout --no-prompt"
        }
        if act in cmds:
            subprocess.Popen(cmds[act], shell=True)

    def on_cancel(self, w):
        self.destroy()
        Gtk.main_quit()

    def on_help(self, w):
        try:
            subprocess.Popen(["xdg-open", "https://edyou-os.vercel.app/docs.html#faq"])
        except:
            pass

def main():
    if not os.environ.get("DISPLAY"):
        sys.exit(1)
    Gtk.init()
    d = ShutdownDialog()
    d.show_all()
    d.connect("destroy", Gtk.main_quit)
    Gtk.main()

if __name__ == "__main__":
    main()