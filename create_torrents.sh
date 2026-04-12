#!/bin/bash

#================================================================================
# Interactive Torrent Creator for EDYOU OS ISOs
#================================================================================
# Allows manual selection and creation of torrent files for built ISOs
# with fast, free trackers.

#--------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DIST_DIR="./build/dist"
LOGS_DIR="./build/logs"

#--------------------------------------------------------------------------------
# Source Dependencies
#--------------------------------------------------------------------------------
source "$SCRIPT_DIR/core/logging.sh"

#--------------------------------------------------------------------------------
# Tracker Configuration (Fast, Free Trackers)
#--------------------------------------------------------------------------------
declare -a TRACKERS=(
    "udp://tracker.openbittorrent.com:80/announce"
    "udp://tracker.opentrackr.org:1337/announce"
    "udp://tracker.internetwarriors.net:1337/announce"
    "udp://exodus.desync.com:6969/announce"
    "udp://tracker.cyberia.is:6969/announce"
    "udp://tracker.torrent.eu.org:451/announce"
    "udp://tracker.tiny-vps.com:6969/announce"
    "udp://retracker.lanta-net.ru:2710/announce"
    "udp://open.stealth.si:80/announce"
    "udp://tracker.0x.tf:6969/announce"
)

#--------------------------------------------------------------------------------
# Utility Functions
#--------------------------------------------------------------------------------

# Checks if required tools are available
check_dependencies() {
    if ! command -v mktorrent &> /dev/null; then
        print_error "mktorrent not found. Installing..."
        sudo apt-get update && sudo apt-get install -y mktorrent || {
            print_error "Failed to install mktorrent"
            exit 1
        }
    fi
}

# Lists all ISO files in current directory
list_iso_files() {
    find . -maxdepth 1 -name "*.iso" -type f | sort
}

# Validates user input for ISO selection
validate_selection() {
    local selection="$1"
    local max_index=$2

    # Check for empty input
    [[ -z "$selection" ]] && return 1

    # Check each number
    for num in $selection; do
        # Check if it's a valid number
        [[ ! "$num" =~ ^[0-9]+$ ]] && return 1

        # Check if it's in valid range
        [[ $num -lt 1 || $num -gt $max_index ]] && return 1
    done

    return 0
}

# Creates torrent file for selected ISO
create_torrent() {
    local iso_path="$1"
    local iso_name=$(basename "$iso_path")
    local torrent_name="${iso_name%.iso}.torrent"

    print_info "Processing torrent for: $iso_name"

    # Check if torrent already exists
    if [[ -f "$torrent_name" ]]; then
        print_warn "Torrent already exists: $torrent_name"
        return 1  # Warning
    fi

    # Build mktorrent command with all trackers
    local mktorrent_cmd=(mktorrent -o "$torrent_name")
    for tracker in "${TRACKERS[@]}"; do
        mktorrent_cmd+=(-a "$tracker")
    done
    mktorrent_cmd+=("$iso_path")

    # Execute mktorrent and capture output
    local mktorrent_output
    if mktorrent_output=$("${mktorrent_cmd[@]}" 2>&1); then
        print_ok "Torrent created: $torrent_name"
        return 0  # Success
    else
        print_error "Failed to create torrent for $iso_name"
        
        # Create log file with last 20 lines of output
        local log_file="${LOGS_DIR}/torrent_creation_failed_$(date +%Y%m%d_%H%M%S).log"
        mkdir -p "$LOGS_DIR"
        echo "Torrent creation failed for: $iso_name" > "$log_file"
        echo "Command: ${mktorrent_cmd[*]}" >> "$log_file"
        echo "Last 20 lines of output:" >> "$log_file"
        echo "$mktorrent_output" | tail -20 >> "$log_file"
        
        print_error "Log saved to: $log_file"
        return 2  # Error
    fi
}

#--------------------------------------------------------------------------------
# Main Function
#--------------------------------------------------------------------------------

main() {
    echo
    print_info "EDYOU OS Interactive Torrent Creator"

    # Check if dist directory exists
    if [[ ! -d "$DIST_DIR" ]]; then
        print_error "Directory $DIST_DIR not found!"
        print_info "Run 'make current' or 'make fast' first to build ISOs"
        exit 1
    fi

    # Check dependencies
    check_dependencies

    # Change to dist directory
    cd "$DIST_DIR" || {
        print_error "Cannot access $DIST_DIR"
        exit 1
    }

    # List ISO files and get array
    IFS=$'\n' read -r -d '' -a iso_files < <(list_iso_files)

    if [[ ${#iso_files[@]} -eq 0 ]]; then
        print_error "No ISO files found in $DIST_DIR"
        print_info "Run 'make current' or 'make fast' first to build ISOs"
        exit 1
    fi

    # Display available ISOs
    echo
    print_info "Available ISOs:"
    for i in "${!iso_files[@]}"; do
        local num=$((i + 1))
        local iso_name=$(basename "${iso_files[$i]}")
        print_info "$num. $iso_name"
    done
    echo

    # Get user selection
    local max_index=${#iso_files[@]}
    local selection=""
    local valid_selection=false

    print_info "Enter the numbers of ISOs to create torrents for:"
    print_info "Multiple selection: separate with spaces (e.g. '1 2 3')"
    print_info "Single selection: just enter the number (e.g. '1')"
    echo

    while [[ "$valid_selection" != true ]]; do
        read -p $'\033[32m[ INPT ]\033[0m \033[36mYour choice:\033[0m ' selection

        if validate_selection "$selection" "$max_index"; then
            valid_selection=true
        else
            print_warn "Invalid selection. Please enter numbers between 1-$max_index separated by spaces."
        fi
    done

    echo

    # Count selected ISOs
    local selection_count=$(echo "$selection" | wc -w)

    print_info "Processing $selection_count selected ISO(s)..."
    echo

    local created_count=0
    local skipped_count=0
    local failed_count=0

    # Process each selected ISO
    for num in $selection; do
        local index=$((num - 1))
        local iso_path="${iso_files[$index]}"

        create_torrent "$iso_path"
        local result=$?

        case $result in
            0) ((created_count++)) ;;
            1) ((skipped_count++)) ;;
            2) ((failed_count++)) ;;
        esac
        echo  # Add spacing between torrents
    done

    echo
    print_ok "Torrent creation completed!"
    print_info "Created: $created_count torrent(s)"
    if [[ $skipped_count -gt 0 ]]; then
        print_warn "Skipped: $skipped_count torrent(s) (already exist)"
    fi
    if [[ $failed_count -gt 0 ]]; then
        print_error "Failed: $failed_count torrent(s)"
    fi

    print_info "Torrent files are in: $DIST_DIR"
    echo
}

#--------------------------------------------------------------------------------
# Script Entry Point
#--------------------------------------------------------------------------------

# Run main function
main "$@"