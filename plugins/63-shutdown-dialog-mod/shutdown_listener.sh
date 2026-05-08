#!/bin/bash

# Shutdown Dialog Listener
INSTALL_DIR="/opt/edyou/shutdown-dialog"
# Use a per-user lock file to avoid blocking other users' sessions
LOCK_FILE="/tmp/shutdown_listener.$(id -u).lock"

# Debug log for invocations (helps when called from xbindkeys)
LOGFILE="/tmp/shutdown_listener.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

# Detect whether the given window id should be considered the "desktop"
is_desktop_window() {
    local id="$1"
    # If xprop not available, fall back to name-based heuristics
    if ! command -v xprop >/dev/null 2>&1; then
        return 1
    fi
    # Query window type
    local types
    types=$(xprop -id "$id" _NET_WM_WINDOW_TYPE 2>/dev/null || true)
    if echo "$types" | grep -q "_NET_WM_WINDOW_TYPE_DESKTOP"; then
        return 0
    fi
    if echo "$types" | grep -q "_NET_WM_WINDOW_TYPE_DOCK"; then
        return 0
    fi
    # Some compositors (gnome-shell) may use special classes for the shell
    local wmclass
    wmclass=$(xprop -id "$id" WM_CLASS 2>/dev/null || true)
    if echo "$wmclass" | grep -qi "gnome-shell"; then
        return 0
    fi
    return 1
}

# Check if we are in a graphical session (basic guard). Some DEs set
# XDG_SESSION_TYPE instead of DISPLAY/WAYLAND_DISPLAY.
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ -z "${XDG_SESSION_TYPE:-}" ]; then
    exit 0
fi

# On Wayland, the GNOME Shell extension handles Alt+F4 at the compositor level.
# This listener should not attempt to intercept on Wayland.
if [ -n "$WAYLAND_DISPLAY" ] || [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
    exit 0
fi

# X11 path: use xdotool to detect and close windows
XDO_TOOL_AVAILABLE=0
if command -v xdotool >/dev/null 2>&1; then
    XDO_TOOL_AVAILABLE=1
fi

if [ "$XDO_TOOL_AVAILABLE" -eq 0 ]; then
    exit 0
fi

# Check lock (prevents multiple dialogs)
if [ -f "$LOCK_FILE" ]; then
    exit 0
fi

# Create lock and ensure it's removed on exit (trap protects against crashes)
touch "$LOCK_FILE" || exit 0
trap 'rm -f "$LOCK_FILE"' EXIT

# Log invocation and some env for debugging
log "invoked by user=$(id -un) pid=$$ DISPLAY=${DISPLAY:-<unset>} XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-<unset>}"

# Get active window info via xdotool
if [ -n "$DISPLAY" ]; then
    winid=$(xdotool getactivewindow 2>/dev/null || true)
    winname=$(xdotool getactivewindow getwindowname 2>/dev/null || true)
    log "xdotool winid=$winid winname=${winname:-<empty>}"

    # Treat no window, window 0, or desktop/dock/gnome-shell as Desktop
    if [[ -z "$winid" || "$winid" = "0" || -z "$winname" ]] || is_desktop_window "$winid"; then
        log "decision=show_dialog (desktop)"
        if pgrep -u "$(id -u)" -f "shutdown_dialog.py" > /dev/null 2>&1; then
            log "dialog already running"
            exit 0
        fi
        nohup python3 "$INSTALL_DIR/shutdown_dialog.py" >>/tmp/shutdown_dialog.log 2>&1 &
        log "dialog started (pid=$!)"
        exit 0
    else
        log "decision=close_window winid=$winid"
        xdotool windowclose "$winid" 2>/dev/null || true
        exit 0
    fi
fi