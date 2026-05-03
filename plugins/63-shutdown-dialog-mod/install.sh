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
cp shutdown-logo-light.png /opt/edyou/shutdown-dialog/
cp shutdown-logo-dark.png /opt/edyou/shutdown-dialog/

# Also copy logos to /usr/local/bin for the dialog to find them
cp shutdown-logo-light.png /usr/local/bin/
cp shutdown-logo-dark.png /usr/local/bin/

chmod +x /opt/edyou/shutdown-dialog/shutdown_dialog.py
chmod +x /opt/edyou/shutdown-dialog/shutdown_listener.sh

# Create symlink
ln -sf /opt/edyou/shutdown-dialog/shutdown_listener.sh /usr/local/bin/edyou-shutdown
chmod +x /usr/local/bin/edyou-shutdown

# Setup sudo permissions (for root user)
print_ok "Setting up sudo permissions..."
SUDOERS_FILE="/etc/sudoers.d/edyou-shutdown"

if [ ! -f "$SUDOERS_FILE" ]; then
    echo "root ALL=(ALL) NOPASSWD: /bin/systemctl poweroff, /bin/systemctl reboot, /bin/systemctl suspend, /usr/bin/logout" | sudo tee "$SUDOERS_FILE" > /dev/null
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
# Only start xbindkeys in X11 sessions — skip for Wayland.
if [ -z "$DISPLAY" ] && [ "${XDG_SESSION_TYPE:-}" != "x11" ]; then
    exit 0
fi

# Ensure user's xbindkeys config exists and start xbindkeys (X11)
XFILE="$HOME/.xbindkeysrc"
if [ ! -f "$XFILE" ]; then
    cat > "$XFILE" <<'XEOF'
# EDYOU OS Shutdown Dialog
"/opt/edyou/shutdown-dialog/shutdown_listener.sh"
Alt + F4
XEOF
    chmod 600 "$XFILE"
fi

# Start xbindkeys if available and not running for this user
if command -v xbindkeys >/dev/null 2>&1; then
    if ! pgrep -u "$(id -u)" -x xbindkeys > /dev/null; then
        xbindkeys >/dev/null 2>&1 &
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
            if [ ! -d "$user_autostart_dir" ]; then
                mkdir -p "$user_autostart_dir"
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

# Create dconf system defaults to register a GNOME custom-keybinding (works under Wayland)
print_ok "Creating dconf system default for GNOME custom keybinding..."
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/00-edyou-shutdown << 'EOF'
[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
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

# Update system dconf database (best-effort)
if command -v dconf >/dev/null 2>&1; then
    dconf update || true
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

print_ok "EDYOU OS Shutdown Dialog installed!"
print_ok "Works for ALL users (existing and new)"
print_ok "Alt+F4 on Desktop = Shutdown Dialog"
print_ok "Alt+F4 on Window = Close Window"

judge "Install EDYOU OS Shutdown Dialog"