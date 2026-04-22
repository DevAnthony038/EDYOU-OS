#!/bin/bash

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This plugin installs educational and creative tools for students, including:
# - MicroPython: A Python implementation for microcontrollers, ideal for learning programming and electronics.
# - Thonny: A beginner-friendly Python IDE that simplifies coding and debugging.
# - GIMP: A powerful image editor for creating and editing graphics.
# - Scratch: A visual programming language that allows students to create interactive stories, games, and animations.
# - Pidgin: A versatile chat client that supports multiple protocols, perfect for LAN communication in classrooms.
#--------------------------------------------------------------------------------------------------------------------

function apt_update_with_retry() {
    local retries=3
    local delay=5
    local attempt=1

    while :; do
        print_ok "Refreshing package metadata (attempt $attempt/$retries)"
        if apt-get update >/dev/null 2>&1; then
            print_ok "Repository metadata refreshed"
            return 0
        fi

        if [ "$attempt" -ge "$retries" ]; then
            print_warn "Repository update failed after $retries attempts. Falling back to cached metadata."
            return 1
        fi

        print_warn "Repository update failed, retrying in $delay seconds..."
        sleep "$delay"
        attempt=$((attempt + 1))
    done
}

function install_tool() {
    local pkg="$1"
    local binary="$2"

    print_ok "Installing $pkg"

    if ! apt-cache show "$pkg" >/dev/null 2>&1; then
        print_warn "Package $pkg is not available in the current repositories. Skipping."
        return 1
    fi

    if ! apt install $INTERACTIVE -y "$pkg" --no-install-recommends >/dev/null 2>&1; then
        print_warn "Installation failed for $pkg. It may be unavailable or repository access may be broken."
        return 1
    fi

    judge "Install $pkg"

    if [ -n "$binary" ]; then
        if command -v "$binary" >/dev/null 2>&1; then
            print_ok "$pkg is installed and available"
        else
            print_warn "$pkg installed but binary '$binary' was not found in PATH"
            return 1
        fi
    fi

    return 0
}

function install_safe_tool() {
    local pkg="$1"
    local binary="$2"

    if ! install_tool "$pkg" "$binary"; then
        print_warn "Attempting once more for $pkg after refreshing metadata"
        apt_update_with_retry
        install_tool "$pkg" "$binary" || print_warn "Failed to install $pkg after retry"
    fi
}

print_ok "Installing educational and creative tools"

wait_network
apt_update_with_retry

install_safe_tool "micropython" "micropython"
install_safe_tool "thonny" "thonny"
install_safe_tool "gimp" "gimp"
install_safe_tool "scratch" "scratch"
install_safe_tool "minetest" "minetest"
install_safe_tool "pidgin" "pidgin"

print_ok "Educational tools installation completed"
print_info "If any packages could not be installed, verify repository access or add the required Debian/Ubuntu sources."
