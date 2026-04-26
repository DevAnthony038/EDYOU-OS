#!/bin/bash

# Shutdown Dialog Listener
INSTALL_DIR="/opt/edyou/shutdown-dialog"
LOCK_FILE="/tmp/shutdown_listener.lock"

# Check if DISPLAY is set - required for GUI
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    exit 0
fi

# Check if xdotool is available
if ! command -v xdotool >/dev/null 2>&1; then
    exit 0
fi

# Check lock (prevents infinite loop AND multiple dialogs)
if [ -f "$LOCK_FILE" ]; then
    exit 0
fi

# Create lock
touch "$LOCK_FILE" || exit 0

# Get Window ID and name (with error handling)
winid=$(xdotool getactivewindow 2>/dev/null) || winid=""
winname=$(xdotool getactivewindow getwindowname 2>/dev/null) || winname=""

# If no valid window ID, skip
if [ -z "$winid" ] || [ "$winid" = "0" ]; then
    rm -f "$LOCK_FILE"
    exit 0
fi

# If Desktop - show dialog BUT check if already running
if [[ "$winname" == "Desktop" || "$winname" == "Desktop Icons"* || "$winname" == "desktop" || -z "$winname" ]]; then
    
    # Check if dialog already running - prevents multiple dialogs
    if pgrep -f "shutdown_dialog.py" > /dev/null 2>&1; then
        rm -f "$LOCK_FILE"
        exit 0
    fi
    
    # Show dialog
    python3 "$INSTALL_DIR/shutdown_dialog.py" 2>/dev/null
    
else
    # Window - close it
    xdotool windowclose "$winid" 2>/dev/null
fi

# Remove lock
rm -f "$LOCK_FILE"