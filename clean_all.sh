#!/bin/bash

#================================================================================
# Build Workspace Cleanup Script
#================================================================================
# Removes temporary build artifacts and unmounts mounted filesystems
# to clean the workspace after build operations.

#--------------------------------------------------------------------------------
# Strict Error Handling
#--------------------------------------------------------------------------------
set -e
set -o pipefail
set -u

#--------------------------------------------------------------------------------
# Path Configuration
#--------------------------------------------------------------------------------
declare SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
declare PROJECT_ROOT="$SCRIPT_DIR"

#--------------------------------------------------------------------------------
# Filesystem Management Functions
#--------------------------------------------------------------------------------

# Unmounts a mounted filesystem if currently active.
# Arguments:
#   $1 - Mount point path to unmount
# Behavior:
#   - Attempts lazy unmount if standard unmount fails
unmount_path() {
    local mount_target="$1"
    if mountpoint -q "$mount_target" 2>/dev/null; then
        echo "  → Unmounting: $mount_target"
        sudo umount "$mount_target" || sudo umount -lf "$mount_target" || true
    fi
}

# Removes directory and all contents if present.
# Arguments:
#   $1 - Directory path to remove
# Behavior:
#   - Silently succeeds if directory does not exist
erase_directory() {
    local dir_target="$1"
    if [ -d "$dir_target" ]; then
        echo "  → Deleting: $dir_target"
        sudo rm -rf "$dir_target" || true
    fi
}

#--------------------------------------------------------------------------------
# Cleanup Orchestration Functions
#--------------------------------------------------------------------------------

# Main cleanup routine.
# Performs unmounting followed by directory removal.
execute_cleanup() {
    echo "================================================================================"
    echo "Starting cleanup process..."
    echo "================================================================================"
    
    echo ""
    echo "Step 1: Unmounting filesystems..."
    unmount_path "$PROJECT_ROOT/build/new_building_os/sys"
    unmount_path "$PROJECT_ROOT/build/new_building_os/proc"
    unmount_path "$PROJECT_ROOT/build/new_building_os/dev"
    unmount_path "$PROJECT_ROOT/build/new_building_os/run"
    
    echo ""
    echo "Step 2: Removing build directories..."
    erase_directory "$PROJECT_ROOT/build/new_building_os"
    erase_directory "$PROJECT_ROOT/build/image"
    erase_directory "$PROJECT_ROOT/build/dist"
    
    echo ""
    echo "================================================================================"
    echo "Cleanup completed successfully!"
    echo "================================================================================"
}

#--------------------------------------------------------------------------------
# Script Entry Point
#--------------------------------------------------------------------------------
cd "$PROJECT_ROOT"
execute_cleanup