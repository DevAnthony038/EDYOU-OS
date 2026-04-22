#!/bin/bash
set -e
set -o pipefail
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/core/logging.sh" ]]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/core/logging.sh"
else
    Green="\033[32m"
    Red="\033[31m"
    Yellow="\033[33m"
    Blue="\033[36m"
    Font="\033[0m"
    INFO="${Blue}[ INFO ]${Font}"
    OK="${Green}[  OK  ]${Font}"
    ERROR="${Red}[FAILED]${Font}"
    WARNING="${Yellow}[ WARN ]${Font}"

    print_ok() { echo -e "${OK} ${Blue} $1 ${Font}"; }
    print_info() { echo -e "${INFO} ${White:-}${Blue:-} $1 ${Font}"; }
    print_warn() { echo -e "${WARNING} ${Yellow} $1 ${Font}"; }
    print_error() { echo -e "${ERROR} ${Red} $1 ${Font}"; }
fi

install_dos2unix_if_missing() {
    if ! command -v dos2unix >/dev/null 2>&1; then
        print_info "dos2unix not found, installing..."
        if command -v sudo >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y dos2unix
        else
            apt update && apt install -y dos2unix
        fi
        judge "Install dos2unix"
    fi
}

convert_shell_files() {
    print_info "Converting .sh files to Unix line endings..."
    echo

    local converted=0
    local skipped=0

    while IFS= read -r -d '' file; do
        if file "$file" | grep -q "CRLF"; then
            dos2unix "$file" >/dev/null 2>&1
            print_info "Converted: $file"
            converted=$((converted + 1))
        else
            print_warn "Already Unix format: $file"
            skipped=$((skipped + 1))
        fi
    done < <(find "$SCRIPT_DIR" -type f -name "*.sh" -not -path "$SCRIPT_DIR/build/new_building_os/*" -print0)

    echo
    print_ok "Shell conversion complete: $converted converted, $skipped already Unix format"
}

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

    if chmod +x "$file_path"; then
        print_ok "GRANTED: $file_path"
        return 0
    else
        print_error "FAILED: $file_path"
        return 1
    fi
}

apply_permissions() {
    local scripts=(
        "$SCRIPT_DIR/build_all.sh"
        "$SCRIPT_DIR/clean_all.sh"
        "$SCRIPT_DIR/create_torrents.sh"
        "$SCRIPT_DIR/build/build.sh"
        "$SCRIPT_DIR/core/config.sh"
        "$SCRIPT_DIR/core/logging.sh"
        "$SCRIPT_DIR/build/repair.sh"
        "$SCRIPT_DIR/build/upgrade.sh"
        "$SCRIPT_DIR/plugins/install_all_plugins.sh"
    )

    echo
    print_info "Granting execute permission to plugin scripts..."
    echo

    local success_count=0
    local skipped_count=0
    local total_count=${#scripts[@]}

    for script in "${scripts[@]}"; do
        if set_execute_permission "$script"; then
            success_count=$((success_count + 1))
        else
            skipped_count=$((skipped_count + 1))
        fi
    done

    echo
    print_info "Permission summary"
    echo
    echo "  Success: $success_count"
    echo "  Skipped: $skipped_count"
    echo "  Total:   $total_count"
    echo
}

main() {
    install_dos2unix_if_missing
    convert_shell_files
    apply_permissions
    print_ok "Conversion and permission update finished successfully."
}

cd "$SCRIPT_DIR"
main
