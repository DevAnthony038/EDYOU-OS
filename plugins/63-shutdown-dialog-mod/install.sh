set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Installing EDYOU OS Shutdown Dialog..."

# Install dependencies
print_ok "Installing dependencies..."
apt install $INTERACTIVE xdotool xbindkeys python3 gir1.2-gtk-3.0 libgtk-3-0 --no-install-recommENDS

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

if ! grep -q "edyou-shutdown" "$XBINDRC" 2>/dev/null; then
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

cat > /etc/xdg/autostart/edyou-shutdown.desktop << EOF
[Desktop Entry]
Type=Application
Name=EDYOU OS Shutdown Dialog
Comment=Shows Shutdown Dialog on Alt+F4 on Desktop
Exec=/bin/bash -c 'if [ ! -f ~/.xbindkeysrc ]; then echo "\" /opt/edyou/shutdown-dialog/shutdown_listener.sh\"\\nAlt + F4" > ~/.xbindkeysrc; fi; xbindkeys'
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
X-Ubuntu-Autostart-enabled=true
EOF

chmod 644 /etc/xdg/autostart/edyou-shutdown.desktop

# Start xbindkeys for currently logged in user
print_ok "Starting xbindkeys for current user..."
pkill -9 xbindkeys 2>/dev/null || true

# Create user xbindkeysrc if not exists
if [ ! -f "$HOME/.xbindkeysrc" ]; then
    cat > "$HOME/.xbindkeysrc" << EOF
# EDYOU OS Shutdown Dialog
"/opt/edyou/shutdown-dialog/shutdown_listener.sh"
Alt + F4
EOF
    chmod 600 "$HOME/.xbindkeysrc"
fi

# Try to start xbindkeys (will work for the current user)
if command -v xbindkeys >/dev/null 2>&1; then
    xbindkeys 2>/dev/null || print_warn "Could not start xbindkeys now. Will start on next login."
fi

# Create a login script for future sessions
print_ok "Setting up login hook for all users..."
LOGIN_HOOK="/etc/profile.d/edyou-shutdown.sh"

if [ ! -f "$LOGIN_HOOK" ]; then
    cat > "$LOGIN_HOOK" << EOF
# Start xbindkeys for EDYOU OS Shutdown Dialog
if command -v xbindkeys >/dev/null 2>&1; then
    if ! pgrep -x "xbindkeys" > /dev/null; then
        xbindkeys 2>/dev/null &
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