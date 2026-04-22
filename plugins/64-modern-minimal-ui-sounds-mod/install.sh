#!/bin/bash

#================================================================================
# Modern Minimal UI Sounds Installation Script
#================================================================================

set -e          # Exit immediately if any command fails
set -o pipefail # Exit if any command in a pipeline fails
set -u          # Treat unset variables as an error

#================================================================================
# Global Variables
#================================================================================
SOUNDS_DOWNLOAD_DIR="./sounds"
SOUNDS_ZIP="${SOUNDS_DOWNLOAD_DIR}/modern-minimal-ui-sounds.zip"
SOUNDS_EXTRACT_DIR="${SOUNDS_DOWNLOAD_DIR}/modern-minimal-ui-sounds-main"
SOUNDS_INSTALL_DIR="/usr/share/sounds/modern-minimal-ui-sounds"
SOUND_THEME_NAME="modern-minimal-ui-sounds"
MAX_RETRIES=3
RETRY_DELAY=5

# Primary and fallback URLs
declare -a DOWNLOAD_URLS=(
    "https://github.com/DevAnthony038/modern-minimal-ui-sounds/archive/refs/heads/main.zip"
    "https://github.com/cadecomposer/modern-minimal-ui-sounds/archive/refs/heads/main.zip"
)

#================================================================================
# Helper Functions
#================================================================================

cleanup_failed_download() {
    if [[ -f "$SOUNDS_ZIP" ]]; then
        print_warn "Cleaning up corrupted file"
        rm -f "$SOUNDS_ZIP"
    fi
}

validate_zip_file() {
    if [[ ! -f "$SOUNDS_ZIP" ]]; then
        return 1
    fi
    
    if unzip -t "$SOUNDS_ZIP" &>/dev/null; then
        return 0
    else
        cleanup_failed_download
        return 1
    fi
}

download_with_retry() {
    local url="$1"
    local attempt=1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        print_info "Download attempt $attempt/$MAX_RETRIES"
        cleanup_failed_download
        
        if wget --timeout=30 --tries=2 "$url" -O "$SOUNDS_ZIP" 2>/dev/null; then
            if validate_zip_file; then
                print_ok "Download valid"
                return 0
            fi
        fi
        
        print_warn "Attempt $attempt failed"
        ((attempt++))
        [ $attempt -le $MAX_RETRIES ] && sleep $RETRY_DELAY
    done
    
    return 1
}

set_gnome_sound_theme() {
    print_info "Setting sound theme to $SOUND_THEME_NAME..."
    
    if gsettings set org.gnome.desktop.sound theme-name "$SOUND_THEME_NAME" 2>/dev/null; then
        print_ok "Sound theme configured"
        return 0
    else
        print_warn "Failed to set theme automatically. You may need to set it manually in GNOME Tweaks > Sound."
        return 1
    fi
}

#================================================================================
# Main
#================================================================================

print_ok "Installing Modern Minimal UI Sounds..."
mkdir -p "$SOUNDS_DOWNLOAD_DIR"

# Try multiple URLs
success=0
for url in "${DOWNLOAD_URLS[@]}"; do
    if download_with_retry "$url"; then
        success=1
        break
    fi
done

[ $success -eq 0 ] && { print_error "Download failed"; exit 1; }

# Extract
print_info "Extracting sounds..."
unzip -q -O UTF-8 "$SOUNDS_ZIP" -d "$SOUNDS_DOWNLOAD_DIR/" || \
    { print_error "Extraction failed"; cleanup_failed_download; exit 1; }

# Install sounds to system directory
print_info "Installing sounds..."
sudo mkdir -p "$SOUNDS_INSTALL_DIR"
sudo cp -r "$SOUNDS_EXTRACT_DIR"/* "$SOUNDS_INSTALL_DIR/" || \
    { print_error "Installation failed"; exit 1; }

# Set GNOME sound theme
set_gnome_sound_theme

# Cleanup
# this will remove the entire sounds directory, including the zip and extracted files, which is fine since we only need the installed sounds in the system directory
rm -rf "$SOUNDS_DOWNLOAD_DIR"


print_ok "Modern Minimal UI Sounds installation completed!"