#!/bin/bash

#================================================================================
# Terminal Output Styling and Runtime Utilities
#================================================================================
# Provides formatted console messaging and command execution validation
# functions for the EDYOUOS build system.

#--------------------------------------------------------------------------------
# ANSI Color Escape Sequences
#--------------------------------------------------------------------------------
export Green="\033[32m"
export Red="\033[31m"
export Yellow="\033[33m"
export Blue="\033[36m"
export White="\033[37m"
export Font="\033[0m"
export GreenBG="\033[42;37m"
export RedBG="\033[41;37m"

#--------------------------------------------------------------------------------
# Message Prefix Definitions
#--------------------------------------------------------------------------------
export INFO="${Blue}[ INFO ]${Font}"
export OK="${Green}[  OK  ]${Font}"
export ERROR="${Red}[FAILED]${Font}"
export WARNING="${Yellow}[ WARN ]${Font}"
export INPUT="${Green}[ INPT ]${Font}"

#--------------------------------------------------------------------------------
# Formatted Output Functions
#--------------------------------------------------------------------------------

# Renders success-message formatting to stdout.
# Arguments:
#   $1 - Message text to display
function print_ok() {
    echo -e "${OK} ${Blue} $1 ${Font}"
}

# Renders informational-message formatting to stdout.
# Arguments:
#   $1 - Message text to display
function print_info() {
    echo -e "${INFO} ${White} $1 ${Font}"
}

# Renders error-message formatting to stderr.
# Arguments:
#   $1 - Message text to display
function print_error() {
    echo -e "${ERROR} ${Red} $1 ${Font}"
}

# Renders warning-message formatting to stdout.
# Arguments:
#   $1 - Message text to display
function print_warn() {
    echo -e "${WARNING} ${Yellow} $1 ${Font}"
}
# Operation Validation Functions
#--------------------------------------------------------------------------------

# Evaluates execution status and reports results.
# Arguments:
#   $1 - Operation identifier for status messaging
# Behavior:
#   - Outputs success notification on zero exit code
#   - Outputs failure notification and terminates on non-zero exit
function judge() {
    if [[ 0 -eq $? ]]; then
        print_ok "$1 succeeded"
        sleep 0.2
    else
        print_error "$1 failed"
        exit 1
    fi
}

#--------------------------------------------------------------------------------
# Network Connectivity Functions
#--------------------------------------------------------------------------------

# Poll network endpoint until connectivity is established.
# Blocks until HTTP GET request succeeds against EDYOUOS endpoint.
function wait_network() {
    local WGET_OPTS="--spider -q --timeout=5 --tries=1"

    until wget $WGET_OPTS https://edyou-os.vercel.app/; do
        echo "Waiting for network (https://edyou-os.vercel.app) ... ETA: 25s"
        sleep 1
    done

    print_ok "Network is online. Continue..."
}

#--------------------------------------------------------------------------------
# Package Management Functions
#--------------------------------------------------------------------------------

# Attempts package installation when package exists in repository.
# Arguments:
#   $1 - Package name to install
# Behavior:
#   - Installs package using INTERACTIVE flag if available
#   - Outputs warning if package unavailable for target release
function install_opt() {
    print_ok "Installing $1... if available…"
    if apt-cache show $1 >/dev/null 2>&1; then
        apt install $INTERACTIVE -y $1 --no-install-recommends
        judge "Install $1"
    else
        print_warn "Package $1 is not available for $TARGET_UBUNTU_VERSION"
    fi
}

#--------------------------------------------------------------------------------
# Function Export for Child Process Access
#--------------------------------------------------------------------------------
export -f print_ok print_error print_warn judge wait_network print_info install_opt