#!/bin/bash

#================================================================================
# Multi-Language Build Orchestration Script
#================================================================================
# Processes language configurations and executes build operations
# for multiple target locales in sequence.

#--------------------------------------------------------------------------------
# Strict Error Handling
#--------------------------------------------------------------------------------
set -e
set -o pipefail
set -u

#--------------------------------------------------------------------------------
# Global Configuration
#--------------------------------------------------------------------------------
declare CONFIG_FILE="./data/all.json"
declare SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

#--------------------------------------------------------------------------------
# Error Handling Functions
#--------------------------------------------------------------------------------

# Terminates execution with error message to stderr.
# Arguments:
#   $1 - Error description
# Returns:
#   Non-zero exit code
fail() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Displays informational message to stdout.
# Arguments:
#   $1 - Message content
log() {
    echo "[INFO] $1"
}

# Displays warning message to stdout.
# Arguments:
#   $1 - Warning content
notice() {
    echo "[WARNING] $1"
}

# Saves build log file when build fails.
# Arguments:
#   $1 - Language mode identifier
#   $2 - Path to build log file
# Returns:
#   0 on success
save_build_log() {
    local target_lang="$1"
    local log_file="$2"
    
    if [[ ! -f "$log_file" ]]; then
        return 0
    fi
    
    local logs_dir="./build/logs"
    mkdir -p "$logs_dir"
    
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local output_log="$logs_dir/${timestamp}_${target_lang}.txt"
    
    notice "Saving build error log to: $output_log"
    
    # Save last 20 lines of build log
    echo "=== BUILD FAILED FOR LANGUAGE: $target_lang ===" > "$output_log"
    echo "=== Timestamp: $(date) ===" >> "$output_log"
    echo "=== Last 20 lines of build output: ===" >> "$output_log"
    echo "" >> "$output_log"
    tail -n 20 "$log_file" >> "$output_log"
    
    notice "Error log saved successfully"
}

#--------------------------------------------------------------------------------
# Dependency Management Functions
#--------------------------------------------------------------------------------

# Verifies required command availability and installs if missing.
# Arguments:
#   $1 - Command name to verify
#   $2 - Package name for installation
verify_command() {
    local cmd="$1"
    local pkg="$2"
    if ! command -v "$cmd" &> /dev/null; then
        log "Installing $pkg..."
        sudo apt-get update
        sudo apt-get install -y "$pkg"
    fi
}

#--------------------------------------------------------------------------------
# Argument Processing Functions
#--------------------------------------------------------------------------------

# Parses command-line arguments for configuration.
# Arguments:
#   $@ - All command-line arguments
# Sets:
#   CONFIG_FILE when -c/--config provided
process_cli_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--config)
                CONFIG_FILE="$2"
                log "Using config: $CONFIG_FILE"
                shift 2
                ;;
            *) fail "Usage: $0 -c <config.json>" ;;
        esac
    done
}

#--------------------------------------------------------------------------------
# Validation Functions
#--------------------------------------------------------------------------------

# Verifies configuration file accessibility.
# Arguments:
#   None (uses CONFIG_FILE global)
# Returns:
#   0 on success, non-zero on failure
check_config() {
    [[ -f "$CONFIG_FILE" ]] || fail "Config not found: $CONFIG_FILE"
    log "Config validated: $CONFIG_FILE"
}

# Verifies required build scripts exist.
# Arguments:
#   None
# Returns:
#   0 on success, non-zero on failure
check_build_chain() {
    [[ -f "./core/config.sh" ]] || fail "./core/config.sh missing"
    [[ -f "./build/build.sh" ]] || fail "./build/build.sh missing"
}

#--------------------------------------------------------------------------------
# Build Preparation Functions
#--------------------------------------------------------------------------------

# Removes previous build artifacts.
# Arguments:
#   None
prepare_workspace() {
    log "Removing old dist files..."
    sudo rm -rf ./build/dist/*
}

# Modifies configuration with language-specific values.
# Arguments:
#   $1 - JSON object containing lang_mode and other settings
update_config_with_lang() {
    local lang_spec="$1"
    # Debug: show what we're processing
    log "Processing language config: $lang_spec"
    
    local fields=$(jq -r 'keys[]' <<< "$lang_spec" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        fail "Failed to parse JSON config: $lang_spec"
    fi
    
    for field in $fields; do
        local env_varname=$(echo "$field" | tr '[:lower:]' '[:upper:]')
        local field_value=$(jq -r --arg k "$field" '.[$k]' <<< "$lang_spec" 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            fail "Failed to extract field '$field' from JSON"
        fi
        local escaped_val=$(echo "$field_value" | sed 's/[\/&]/\\&/g')
        sed -i "s|^export ${env_varname}=\".*\"|export ${env_varname}=\"${escaped_val}\"|" ./core/config.sh
    done
}

#--------------------------------------------------------------------------------
# Build Execution Functions
#--------------------------------------------------------------------------------

# Executes build process with minimal retry for transient failures.
# Arguments:
#   $1 - Language mode identifier
# Returns:
#   0 on successful build, non-zero on failure
run_build_with_retry() {
    local target_lang="$1"
    local build_log_file="./build/build_${target_lang}.log"
    
    log "Building LANG_MODE: $target_lang"
    log "Build output logged to: $build_log_file"
    
    if ./build/build.sh 2>&1 | tee "$build_log_file"; then
        log "Build succeeded for LANG_MODE: $target_lang"
        rm -f "$build_log_file"
        return 0
    else
        notice "Build failed for LANG_MODE: $target_lang"
        save_build_log "$target_lang" "$build_log_file"
        rm -f "$build_log_file"
        fail "Build failed for LANG_MODE: $target_lang (stopping all builds - see build/logs/ for details)"
    fi
}

#--------------------------------------------------------------------------------
# Output Generation Functions
#--------------------------------------------------------------------------------

# Creates torrent files from built ISO images.
# Arguments:
#   None
# Returns:
#   0 on success, non-zero if no torrents created
generate_distribution_files() {
    log "Generating torrent files..."
    
    [[ -d "./build/dist" ]] || { notice "No dist dir, skipping torrents"; return 0; }
    
    local iso_file_count=$(find ./build/dist -maxdepth 1 -name "*.iso" -type f 2>/dev/null | wc -l)
    [[ $iso_file_count -eq 0 ]] && { notice "No ISO files, skipping torrents"; return 0; }
    
    if ! command -v mktorrent &> /dev/null; then
        log "Installing mktorrent..."
        sudo apt-get update && sudo apt-get install -y mktorrent || { notice "mktorrent install failed"; return 0; }
    fi
    
    log "Found $iso_file_count ISO file(s)"
    
    local tracker_list=$(mktemp)
    declare -a announce_urls=()
    
    if curl -fsSL -o "$tracker_list" https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt; then
        while IFS= read -r tracker_entry; do
            [[ -n "$tracker_entry" ]] && [[ ! "$tracker_entry" =~ ^# ]] && announce_urls+=( -a "$tracker_entry" )
        done < "$tracker_list"
        rm -f "$tracker_list"
    else
        announce_urls=( -a "http://tracker.openbittorrent.com:80/announce" )
    fi
    
    log "Generating SHA256 checksums..."
    cd ./build/dist || return
    
    # Fix permissions for ISO files created with sudo
    sudo chown -R $USER:$USER . 2>/dev/null || true
    
    for iso_image in *.iso; do
        [[ -f "$iso_image" ]] || continue
        local output_name="${iso_image%.iso}"
        [[ -f "${output_name}.sha256" ]] || sha256sum "$iso_image" > "${output_name}.sha256"
    done
    
    local created_torrents=0
    for iso_image in *.iso; do
        [[ -f "$iso_image" ]] || continue
        local output_name="${iso_image%.iso}"
        local torrent_output="${output_name}.torrent"
        
        if mktorrent "${announce_urls[@]}" -o "$torrent_output" "$iso_image"; then
            ((created_torrents++)) || true
            log "Created: $torrent_output"
        fi
    done
    
    cd - > /dev/null || true
    
    [[ $created_torrents -gt 0 ]] || fail "No torrents created"
    log "Created $created_torrents torrent file(s)"
}

#--------------------------------------------------------------------------------
# Primary Execution Flow
#--------------------------------------------------------------------------------

# Main entry point for multi-language build process.
# Arguments:
#   $@ - Command-line arguments
# Returns:
#   0 on successful completion, non-zero on failure
main() {
    process_cli_args "$@"
    check_config
    check_build_chain
    prepare_workspace
    
    verify_command "jq" "jq"
    
    # Read language configurations as array
    declare -a language_configs=()
    while IFS= read -r config; do
        if [[ -n "$config" && "$config" != "[" && "$config" != "]" ]]; then
            language_configs+=("$config")
        fi
    done < <(jq -c '.[]' "$CONFIG_FILE")
    declare total_languages=${#language_configs[@]}
    
    log "Found $total_languages config(s)"
    
    for ((lang_index=0; lang_index<total_languages; lang_index++)); do
        declare lang_object="${language_configs[$lang_index]}"
        declare selected_lang=$(echo "$lang_object" | jq -r '.lang_mode')
        
        echo ""
        echo "================================================================================"
        echo "[INFO] Build #$((lang_index+1))/$total_languages -> LANG_MODE: $selected_lang"
        echo "================================================================================"
        
        update_config_with_lang "$lang_object"
        run_build_with_retry "$selected_lang"
        
        echo ""
    done
    
    echo ""
    echo "================================================================================"
    log "Build tasks completed!"
    echo "================================================================================"
    generate_distribution_files
    
    log "Done!"
}

#--------------------------------------------------------------------------------
# Script Entry Point
#--------------------------------------------------------------------------------
cd "$SCRIPT_DIR"
main "$@"