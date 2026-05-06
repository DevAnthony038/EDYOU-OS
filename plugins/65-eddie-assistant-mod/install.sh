#!/bin/bash

set -e
set -o pipefail
set -u

print_ok "Installing Eddie - EDYOU OS AI Assistant..."

# Install dependencies from main.py
print_ok "Installing dependencies..."
apt install $INTERACTIVE python3 python3-pip python3-venv git --no-install-recommends

# Install Python packages
print_ok "Installing Python packages..."
pip3 install --break-system-packages PyQt6 openai

# Create system directory
print_ok "Creating system directories..."
mkdir -p /opt/edyou/eddies
mkdir -p /usr/local/bin

# Download Eddie from GitHub
print_ok "Downloading Eddie..."
EDDIE_DIR="/opt/edyou/eddies"
GITHUB_URL="https://github.com/CrazxVillager/Eddie"

# Clone the repository
if [ ! -d "$EDDIE_DIR/.git" ]; then
    git clone "$GITHUB_URL" "$EDDIE_DIR" || {
        print_error "Failed to clone Eddie repository"
        exit 1
    }
else
    cd "$EDDIE_DIR"
    git pull || print_warn "Failed to update Eddie"
fi

# Make main.py executable
chmod +x "$EDDIE_DIR/main.py"

# Create symlink
ln -sf "$EDDIE_DIR/main.py" /usr/local/bin/eddies
chmod +x /usr/local/bin/eddies

# Create desktop entry for Eddie
print_ok "Creating desktop entry..."
cat > /usr/share/applications/eddies.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Eddie - EDYOU OS AI Assistant
Comment=AI Assistant for EDYOU OS
Exec=eddies
Icon=/opt/edyou/eddies/icon.png
Terminal=false
Categories=Utility;Development;
EOF

chmod 644 /usr/share/applications/eddies.desktop


# Update dconf database
dconf update 2>/dev/null || true

# Setup for ALL users (existing and new)
print_ok "Setting up for all users..."

# Create skeleton for new users
mkdir -p /etc/skel/.local/share/applications

# Create autostart for all users
cat > /etc/xdg/autostart/eddies.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Eddie AI Assistant
Comment=Runs Eddie in background
Exec=eddies --background
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

chmod 644 /etc/xdg/autostart/eddies.desktop

print_ok "Eddie installed successfully!"
print_ok "Available as app in start menu"
print_ok "Pinned to dash/panel"

judge "Install Eddie AI Assistant"