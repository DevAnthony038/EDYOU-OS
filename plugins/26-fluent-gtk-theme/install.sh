#!/bin/bash

#================================================================================
# Fluent GTK Theme Installation Script
#================================================================================

set -e          # Exit immediately if any command fails
set -o pipefail # Exit if any command in a pipeline fails
set -u          # Treat unset variables as an error

#================================================================================
# Global Variables
#================================================================================
THEME_DOWNLOAD_DIR="./themes"
THEME_ZIP="${THEME_DOWNLOAD_DIR}/fluent-gtk-theme.zip"
THEME_EXTRACT_DIR="${THEME_DOWNLOAD_DIR}/fluent-gtk-theme"
MAX_RETRIES=3
RETRY_DELAY=5

# Primary and fallback URLs (für Redundanz)
declare -a DOWNLOAD_URLS=(
    "https://github.com/vinceliuice/Fluent-gtk-theme/archive/refs/heads/master.zip"
    "https://github.com/DevAnthony038/Fluent-gtk-theme/archive/refs/heads/master.zip"
)

#================================================================================
# Helper Functions
#================================================================================

cleanup_failed_download() {
    if [[ -f "$THEME_ZIP" ]]; then
        print_warn "Cleaning up corrupted file"
        rm -f "$THEME_ZIP"
    fi
}

validate_zip_file() {
    if [[ ! -f "$THEME_ZIP" ]]; then
        return 1
    fi
    
    if unzip -t "$THEME_ZIP" &>/dev/null; then
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
        
        if wget --timeout=30 --tries=2 "$url" -O "$THEME_ZIP" 2>/dev/null; then
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

#================================================================================
# Main
#================================================================================

print_ok "Installing Fluent GTK Theme"
mkdir -p "$THEME_DOWNLOAD_DIR"

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
print_info "Extracting..."
unzip -q -O UTF-8 "$THEME_ZIP" -d "$THEME_DOWNLOAD_DIR/" || \
    { print_error "Extraction failed"; cleanup_failed_download; exit 1; }

# Rename the extracted directory to match expected name
mv "$THEME_DOWNLOAD_DIR/Fluent-gtk-theme-master" "$THEME_EXTRACT_DIR"

# Install
print_info "Installing theme..."
(cd "$THEME_EXTRACT_DIR" && ./install.sh --tweaks noborder round) || \
    { print_error "Installation failed"; exit 1; }

print_ok "Fluent theme installed successfully!"
