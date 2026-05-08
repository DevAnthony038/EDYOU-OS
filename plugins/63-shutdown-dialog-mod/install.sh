set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Installing EDYOU OS Shutdown Dialog..."

# Install dependencies
print_ok "Installing dependencies..."
# Add dconf-cli so we can run `dconf update` and manipulate system defaults
apt install ${INTERACTIVE:-} xdotool xbindkeys python3 gir1.2-gtk-3.0 libgtk-3-0 libglib2.0-bin dconf-cli --no-install-recommends

# Create system directory
print_ok "Creating system directories..."
mkdir -p /opt/edyou/shutdown-dialog
mkdir -p /usr/local/bin

# Copy files
print_ok "Copying files..."
cp shutdown_dialog.py /opt/edyou/shutdown-dialog/
cp shutdown_listener.sh /opt/edyou/shutdown-dialog/
# Logos are embedded directly in shutdown_dialog.py

chmod +x /opt/edyou/shutdown-dialog/shutdown_dialog.py
chmod +x /opt/edyou/shutdown-dialog/shutdown_listener.sh

# Create symlink
ln -sf /opt/edyou/shutdown-dialog/shutdown_listener.sh /usr/local/bin/edyou-shutdown
chmod +x /usr/local/bin/edyou-shutdown

# Setup sudo permissions (for root user)
print_ok "Setting up sudo permissions..."
SUDOERS_FILE="/etc/sudoers.d/edyou-shutdown"

if [ ! -f "$SUDOERS_FILE" ]; then
    echo "%sudo ALL=(ALL) NOPASSWD: /usr/bin/python3 /opt/edyou/shutdown-dialog/shutdown_dialog.py, /usr/bin/systemctl poweroff, /usr/bin/systemctl reboot, /usr/bin/systemctl suspend" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 0440 "$SUDOERS_FILE"
fi

# Setup xbindkeys system-wide config
print_ok "Setting up xbindkeys system-wide..."
XBINDRC="/etc/xbindkeysrc"

if [ ! -f "$XBINDRC" ]; then
    touch "$XBINDRC"
fi
if ! grep -q "/opt/edyou/shutdown-dialog/shutdown_listener.sh" "$XBINDRC" 2>/dev/null; then
    cat >> "$XBINDRC" << EOF

# EDYOU OS Shutdown Dialog
"/opt/edyou/shutdown-dialog/shutdown_listener.sh"
Alt + F4
EOF
fi

chmod 644 "$XBINDRC"

# Create system-wide autostart for ALL users (existing and new)
print_ok "Creating system-wide autostart for all users..."
mkdir -p /etc/xdg/autostart

# Autostart helper: ensures user's ~/.xbindkeysrc exists and starts xbindkeys for X11 sessions
cat > /usr/local/bin/edyou-shutdown-autostart << 'EOF'
#!/bin/bash
# Autostart helper for EDYOU shutdown dialog.
# On X11: ensure ~/.xbindkeysrc exists and start xbindkeys.
# On Wayland: ensure GNOME dconf keybinding is registered.

SHUTDOWN_INDEX="custom5"
SHUTDOWN_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${SHUTDOWN_INDEX}/"

# ---- X11 / xbindkeys path ----
if [ -n "$DISPLAY" ] || [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
    XFILE="$HOME/.xbindkeysrc"
    if [ ! -f "$XFILE" ]; then
        cat > "$XFILE" <<'XEOF'
# EDYOU OS Shutdown Dialog
"/opt/edyou/shutdown-dialog/shutdown_listener.sh"
Alt + F4
XEOF
        chmod 600 "$XFILE"
    fi

    if command -v xbindkeys >/dev/null 2>&1; then
        if ! pgrep -u "$(id -u)" -x xbindkeys > /dev/null; then
            xbindkeys >/dev/null 2>&1 &
        fi
    fi
fi

# ---- Wayland / dconf + extension path (runs once per user) ----
# Enable the GNOME Shell extension (primary Wayland mechanism)
if command -v gnome-extensions >/dev/null 2>&1; then
    gnome-extensions enable shutdown-dialogue@edyouos 2>/dev/null || true
fi

# Also register dconf custom5 binding as fallback (for non-GNOME or X11)
if command -v dconf >/dev/null 2>&1; then
    CURRENT=$(dconf read /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings 2>/dev/null || echo "")
    if [ -z "$CURRENT" ] || [ "$CURRENT" = "@as []" ]; then
        dconf write "${SHUTDOWN_PATH}binding" "'<Alt>F4'"
        dconf write "${SHUTDOWN_PATH}command" "'bash -lc \"/opt/edyou/shutdown-dialog/shutdown_listener.sh\"'"
        dconf write "${SHUTDOWN_PATH}name" "'EDYOU Shutdown'"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings "['${SHUTDOWN_PATH}']"
    elif ! echo "$CURRENT" | grep -q "${SHUTDOWN_INDEX}"; then
        NEW="${CURRENT%]}, '${SHUTDOWN_PATH}']"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings "$NEW"
        dconf write "${SHUTDOWN_PATH}binding" "'<Alt>F4'"
        dconf write "${SHUTDOWN_PATH}command" "'bash -lc \"/opt/edyou/shutdown-dialog/shutdown_listener.sh\"'"
        dconf write "${SHUTDOWN_PATH}name" "'EDYOU Shutdown'"
    fi
fi
EOF
chmod 755 /usr/local/bin/edyou-shutdown-autostart

cat > /etc/xdg/autostart/edyou-shutdown.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=EDYOU OS Shutdown Dialog
Comment=Shows Shutdown Dialog on Alt+F4 on Desktop
Exec=/usr/local/bin/edyou-shutdown-autostart
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

chmod 644 /etc/xdg/autostart/edyou-shutdown.desktop

# Create /etc/skel entry so new users get the keybinding by default
print_ok "Adding /etc/skel/.xbindkeysrc for new users..."
mkdir -p /etc/skel
cat > /etc/skel/.xbindkeysrc << 'EOF'
# EDYOU OS Shutdown Dialog
"/opt/edyou/shutdown-dialog/shutdown_listener.sh"
Alt + F4
EOF
chmod 600 /etc/skel/.xbindkeysrc

# Ensure new users also get the autostart entry via /etc/skel
print_ok "Adding /etc/skel/.config/autostart/edyou-shutdown.desktop for new users..."
mkdir -p /etc/skel/.config/autostart
cp /etc/xdg/autostart/edyou-shutdown.desktop /etc/skel/.config/autostart/edyou-shutdown.desktop
chmod 644 /etc/skel/.config/autostart/edyou-shutdown.desktop


# Populate existing home directories (create .xbindkeysrc if missing)
print_ok "Creating .xbindkeysrc for existing users (if missing)..."
for d in /home/*; do
    if [ -d "$d" ]; then
        user=$(basename "$d")
        if id "$user" >/dev/null 2>&1; then
            if [ ! -f "$d/.xbindkeysrc" ]; then
                cat > "$d/.xbindkeysrc" <<'USR'
# EDYOU OS Shutdown Dialog
"/opt/edyou/shutdown-dialog/shutdown_listener.sh"
Alt + F4
USR
                chmod 600 "$d/.xbindkeysrc"
                chown "$user:$user" "$d/.xbindkeysrc"
            fi
        fi
    fi
done

# Ensure per-user autostart exists and try to start autostart helper for logged-in GUI users
print_ok "Installing per-user autostart and attempting immediate start for logged-in GUI users..."
for d in /home/*; do
    if [ -d "$d" ]; then
        user=$(basename "$d")
        if id "$user" >/dev/null 2>&1; then
            user_autostart_dir="$d/.config/autostart"
            mkdir -p "$user_autostart_dir"
            if [ ! -f "$user_autostart_dir/edyou-shutdown.desktop" ]; then
                cp /etc/xdg/autostart/edyou-shutdown.desktop "$user_autostart_dir/"
                chown -R "$user:$user" "$user_autostart_dir"
            fi

            # If user has a gnome-shell process, try to extract its env and start autostart helper in that session
            pid=$(pgrep -u "$user" gnome-shell | head -n1 || true)
            if [ -n "$pid" ]; then
                display=$(tr '\0' '\n' < /proc/$pid/environ | sed -n 's/^DISPLAY=//p' | tail -n1)
                dbus=$(tr '\0' '\n' < /proc/$pid/environ | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | tail -n1)
                xauth=$(tr '\0' '\n' < /proc/$pid/environ | sed -n 's/^XAUTHORITY=//p' | tail -n1)
                xdgrt=$(tr '\0' '\n' < /proc/$pid/environ | sed -n 's/^XDG_RUNTIME_DIR=//p' | tail -n1)
                if [ -z "$display" ]; then display=":0"; fi
                sudo -u "$user" env DISPLAY="$display" XAUTHORITY="$xauth" DBUS_SESSION_BUS_ADDRESS="$dbus" XDG_RUNTIME_DIR="$xdgrt" /usr/local/bin/edyou-shutdown-autostart >/dev/null 2>&1 || true
            fi
        fi
    fi
done

# ======================================================
# GNOME Wayland custom keybinding (system dconf + GSettings)
# Uses custom5 to avoid collision with plugin 39's custom0-4
# NOTE: Does NOT touch plugin 39's skeleton dconf or root's dconf.
# The autostart helper (run at graphical login) registers custom5
# in the user's dconf where DBus is always available.
# ======================================================
print_ok "Setting up GNOME custom keybinding for Wayland..."

SHUTDOWN_CUSTOM_INDEX="custom5"
SHUTDOWN_CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${SHUTDOWN_CUSTOM_INDEX}/"

# 1. Create system dconf default (fallback for users without user dconf override)
#    Does NOT require DBus — reads text files, writes binary DB
print_ok "Creating system dconf default..."
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/00-edyou-shutdown << EOF
[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['${SHUTDOWN_CUSTOM_PATH}']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${SHUTDOWN_CUSTOM_INDEX}]
name='EDYOU Shutdown'
binding='<Alt>F4'
command='bash -lc "/opt/edyou/shutdown-dialog/shutdown_listener.sh"'
EOF

# Ensure dconf profile contains the local system DB so local.d is applied
PROFILE="/etc/dconf/profile/user"
mkdir -p "$(dirname "$PROFILE")"
if [ ! -f "$PROFILE" ]; then
    cat > "$PROFILE" <<'PROF'
user-db:user
system-db:local
PROF
else
    if ! grep -q '^user-db:user' "$PROFILE" 2>/dev/null; then
        echo 'user-db:user' >> "$PROFILE"
    fi
    if ! grep -q '^system-db:local' "$PROFILE" 2>/dev/null; then
        echo 'system-db:local' >> "$PROFILE"
    fi
fi

# Update system dconf database (reads text files, no DBus needed)
if command -v dconf >/dev/null 2>&1; then
    if ! dconf update; then
        print_warn "dconf update failed — GSettings override will serve as fallback"
    fi
fi

# 2. Create GSettings override (more reliable than dconf on Wayland)
#    Also does NOT require DBus
print_ok "Creating GSettings override for GNOME..."
GSETTINGS_OVERRIDE="/usr/share/glib-2.0/schemas/90-edyou-shutdown.gschema.override"
mkdir -p /usr/share/glib-2.0/schemas
cat > "$GSETTINGS_OVERRIDE" << EOF
[org.gnome.settings-daemon.plugins.media-keys]
custom-keybindings=['${SHUTDOWN_CUSTOM_PATH}']

[org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.${SHUTDOWN_CUSTOM_INDEX}]
name='EDYOU Shutdown'
binding='<Alt>F4'
command='bash -lc "/opt/edyou/shutdown-dialog/shutdown_listener.sh"'
EOF

# Compile GSettings schemas (no DBus needed)
if command -v glib-compile-schemas >/dev/null 2>&1; then
    glib-compile-schemas /usr/share/glib-2.0/schemas/ || true
fi

# Create a login script for future sessions
print_ok "Setting up login hook for all users..."
LOGIN_HOOK="/etc/profile.d/edyou-shutdown.sh"

if [ ! -f "$LOGIN_HOOK" ]; then
    cat > "$LOGIN_HOOK" << 'EOF'
# Ensure user skeleton for xbindkeys exists for graphical sessions
if [ -n "$DISPLAY" ] || [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
    if command -v xbindkeys >/dev/null 2>&1; then
        # Create user's xbindkeysrc if not exists
        if [ ! -f ~/.xbindkeysrc ]; then
            cat > ~/.xbindkeysrc <<'XEOF'
# EDYOU OS Shutdown Dialog
"/opt/edyou/shutdown-dialog/shutdown_listener.sh"
Alt + F4
XEOF
            chmod 600 ~/.xbindkeysrc
        fi
    fi
fi
EOF
    chmod +x "$LOGIN_HOOK"
fi

# ======================================================
# GNOME Shell Extension (primary Wayland mechanism)
# ======================================================
print_ok "Installing GNOME Shell extension..."

EXT_UUID="shutdown-dialogue@edyouos"
EXT_DIR="/usr/share/gnome-shell/extensions/${EXT_UUID}"

mkdir -p "$EXT_DIR"
mkdir -p "$EXT_DIR/schemas"

cp -r "shutdown-dialogue@edyouos/extension.js" "$EXT_DIR/"
cp -r "shutdown-dialogue@edyouos/metadata.json" "$EXT_DIR/"
cp -r "shutdown-dialogue@edyouos/schemas/org.gnome.shell.extensions.shutdown-dialogue.gschema.xml" "$EXT_DIR/schemas/"

# Compile schemas in the extension directory
if command -v glib-compile-schemas >/dev/null 2>&1; then
    glib-compile-schemas "$EXT_DIR/schemas/" || true
fi

# Also compile globally so GSettings override and extension schema are available
if command -v glib-compile-schemas >/dev/null 2>&1; then
    glib-compile-schemas /usr/share/glib-2.0/schemas/ || true
fi

print_ok "GNOME Shell extension installed in ${EXT_DIR}"

print_ok "EDYOU OS Shutdown Dialog installed!"
print_ok "Works for ALL users (existing and new)"
print_ok "Alt+F4 on Desktop = Shutdown Dialog"
print_ok "Alt+F4 on Window = Close Window"

judge "Install EDYOU OS Shutdown Dialog"