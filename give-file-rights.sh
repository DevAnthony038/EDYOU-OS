#!/bin/bash

set -e
set -o pipefail
set -u

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

if [[ -f "$SCRIPT_DIR/core/logging.sh" ]]; then
    source "$SCRIPT_DIR/core/logging.sh"
else
    Green="\033[32m"
    Blue="\033[36m"
    Font="\033[0m"
    print_ok() { echo -e "${Green}[  OK  ]${Font} ${Blue} $1 ${Font}"; }
    print_warn() { echo -e "${Yellow}[ WARN ]${Font} ${Yellow} $1 ${Font}"; }
    print_error() { echo -e "${Red}[FAILED]${Font} ${Red} $1 ${Font}"; }
fi

declare -a SCRIPTS=(
    "build_all.sh"
    "clean_all.sh"
    "create_torrents.sh"
    "build/build.sh"
    "core/config.sh"
    "core/logging.sh"
    "build/repair.sh"
    "build/upgrade.sh"
    "plugins/install_all_plugins.sh"
)

set_execute_permission() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        print_warn "SKIPPED (not found): $file_path"
        return 1
    fi
    
    if [[ -x "$file_path" ]]; then
        print_ok "ALREADY executable: $file_path"
        return 0
    fi
    
    if chmod +x "$file_path" 2>/dev/null; then
        print_ok "GRANTED: $file_path"
        return 0
    else
        print_error "FAILED: $file_path"
        return 1
    fi
}

main() {
    echo ""
    local success_count=0
    local skipped_count=0
    local total_count=${#SCRIPTS[@]}
    
    print_info "Processing $total_count script(s)..."
    echo ""
    
    for script in "${SCRIPTS[@]}"; do
        if set_execute_permission "$script"; then
            ((success_count++)) || true
        else
            ((skipped_count++)) || true
        fi
    done
    
    echo ""
    print_info "Summary"
    echo ""
    echo "  Success: $success_count script(s)"
    echo "  Skipped: $skipped_count script(s)"
    echo "  Total:   $total_count script(s)"
    echo ""
    
    if [[ $success_count -eq $total_count ]]; then
        print_ok "All scripts processed!"
        return 0
    else
        print_info "Setup completed."
        return 0
    fi
}

cd "$SCRIPT_DIR"
main