set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script installs the Eddie AI Assistant for the target system.
# Eddie is a cross-platform AI assistant that can help you with various tasks, such as homework, coding, and more.
# It is designed to be a helpful companion for users of all ages and skill levels.

EDDIE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EDDIE_BIN="$EDDIE_DIR/Eddie"
INSTALL_DIR="/opt/eddie"
DESKTOP_FILE="/usr/share/applications/eddie.desktop"

print_ok "Installing Eddie AI Assistant..."

if [ ! -f "$EDDIE_BIN" ]; then
    print_error "Error: Eddie binary not found in $EDDIE_DIR"
    exit 1
fi

print_ok "Installing Qt6 XCB dependencies..."
apt update || print_warn "apt update failed, continuing with cached metadata"
apt install $INTERACTIVE \
    libxcb-cursor0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-xfixes0 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxcb-xinput0 \
    libxcb-sync1 \
    libxcb-util1 \
    libegl1 \
    libegl-mesa0 \
    --no-install-recommends

# Ensure Qt6 XCB platform plugin can find its libraries
ldconfig
for xcb_lib in /usr/lib/x86_64-linux-gnu/libxcb-*.so.*; do
    xcb_soname="${xcb_lib%.so.*}"
    if [ ! -f "$xcb_soname.so" ]; then
        ln -sf "$xcb_lib" "$xcb_soname.so" 2>/dev/null || true
    fi
done

print_ok "Copying Eddie files..."
mkdir -p "$INSTALL_DIR"
cp "$EDDIE_BIN" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/Eddie"

if [ -f "$EDDIE_DIR/icon.svg" ]; then
    cp "$EDDIE_DIR/icon.svg" "$INSTALL_DIR/"
    ICON_PATH="$INSTALL_DIR/icon.svg"
else
    ICON_PATH="utilities-terminal"
fi

print_ok "Creating Eddie wrapper script..."
cat > "$INSTALL_DIR/eddie-wrapper.sh" << 'WRAPPER'
#!/bin/bash
# Eddie wrapper: use native display server, fallback if needed
PLATFORM="xcb"
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    PLATFORM="wayland"
fi

if ! QT_QPA_PLATFORM=$PLATFORM "$(dirname "$0")/Eddie" "$@"; then
    if [ "$PLATFORM" = "wayland" ]; then
        exec QT_QPA_PLATFORM=xcb "$(dirname "$0")/Eddie" "$@"
    else
        exec QT_QPA_PLATFORM=wayland "$(dirname "$0")/Eddie" "$@"
    fi
fi
WRAPPER
chmod +x "$INSTALL_DIR/eddie-wrapper.sh"

print_ok "Creating desktop entry..."
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Eddie
Comment=Eddie AI Assistant
Exec=$INSTALL_DIR/eddie-wrapper.sh
Icon=$ICON_PATH
Terminal=false
Categories=Utility;Development;
StartupNotify=true
EOF

chmod 644 "$DESKTOP_FILE"

print_ok "Eddie installed successfully."
