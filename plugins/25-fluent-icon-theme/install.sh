set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

#================================================================================
# This script is responsible for installing the Fluent icon theme and cursor theme.
# It downloads the themes from a specified URL, extracts them, and runs the installation scripts.
#================================================================================
# Note: The Fluent GTK theme is handled in a separate script (26-fluent-gtk-theme/install.sh) to allow users to choose whether to install it or not.
#================================================================================

#================================================================================
# Global Variables
#================================================================================
THEME_DOWNLOAD_DIR="./themes"
THEME_ZIP="${THEME_DOWNLOAD_DIR}/fluent-icon-theme.zip"
THEME_EXTRACT_DIR="${THEME_DOWNLOAD_DIR}/fluent-icon-theme"
MAX_RETRIES=3
RETRY_DELAY=5

# Primary and fallback URLs (für Redundanz)
declare -a DOWNLOAD_URLS=(
    "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/heads/master.zip"
    "https://github.com/DevAnthony038/Fluent-icon-theme/archive/refs/heads/master.zip"
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

print_ok "Downloading Fluent icon theme"
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

unzip -q -O UTF-8 "$THEME_ZIP" -d "$THEME_DOWNLOAD_DIR/"
judge "Download Fluent icon theme"

# Rename the extracted directory to match expected name
mv "$THEME_DOWNLOAD_DIR/Fluent-icon-theme-master" "$THEME_EXTRACT_DIR"

# 

print_ok "Installing Fluent icon theme"
(
    print_ok "Installing Fluent icon theme" && \
    cd ./themes/fluent-icon-theme/ && \
    ./install.sh standard
)
judge "Install Fluent icon theme"

#==============================================

print_ok "Installing Fluent cursor theme"
(
    print_ok "Installing Fluent cursor theme" && \
    cd ./themes/fluent-icon-theme/cursors/ && \
    ./install.sh
)
judge "Install Fluent cursor theme"
