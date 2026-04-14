#!/bin/bash

#==========================
# EDYOUOS - Initial Setup Script
# This is the first version - no upgrade paths needed
#==========================

set -e
set -o pipefail
set -u
export DEBIAN_FRONTEND=noninteractive
export LATEST_VERSION="1.0.1"
export CODE_NAME="noble"
export OS_ID="EDYOUOS"

#==========================
# Color Definitions
#==========================

Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Font="\033[0m"
OK="\${Green}[  OK  ]\${Font}"
ERROR="\${Red}[FAILED]\${Font}"
WARNING="\${Yellow}[ WARN ]\${Font}"

#==========================
# Output Functions
#==========================

function print_ok() {
  echo -e "\${OK} \${Blue} $1 \${Font}"
}

function print_error() {
  echo -e "\${ERROR} \${Red} $1 \${Font}"
}

function print_warn() {
  echo -e "\${WARNING} \${Yellow} $1 \${Font}"
}

#==========================
# Helper Functions
#==========================

function judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 succeeded"
    sleep 0.2
  else
    print_error "$1 failed"
    exit 1
  fi
}

function ensureCurrentOsEdyouOs() {
    if ! grep -q "DISTRIB_ID=EDYOUOS" /etc/lsb-release 2>/dev/null; then
        print_warn "Current OS is not yet identified as EDYOUOS. This might be a fresh installation."
    fi
}

#==========================
# Apply System Identification
#==========================

function applyLsbRelease() {
  sudo bash -c "cat > /etc/os-release <<EOF
PRETTY_NAME=\"EDYOUOS $LATEST_VERSION\"
NAME=\"EDYOUOS\"
VERSION_ID=\"$LATEST_VERSION\"
VERSION=\"$LATEST_VERSION ($CODE_NAME)\"
VERSION_CODENAME=$CODE_NAME
ID=ubuntu
ID_LIKE=debian
HOME_URL=\"https://edyou-os.vercel.app\"
SUPPORT_URL=\"https://github.com/DevAnthony038/EDYOU-OS/discussions\"
BUG_REPORT_URL=\"https://github.com/DevAnthony038/EDYOU-OS/issues\"
PRIVACY_POLICY_URL=\"https://www.ubuntu.com/legal/terms-and-policies/privacy-policy\"
UBUNTU_CODENAME=$CODE_NAME
EOF"

  sudo bash -c "cat > /etc/lsb-release <<EOF
DISTRIB_ID=EDYOUOS
DISTRIB_RELEASE=$LATEST_VERSION
DISTRIB_CODENAME=$CODE_NAME
DISTRIB_DESCRIPTION=\"EDYOUOS $LATEST_VERSION\"
EOF"

  echo "EDYOUOS ${LATEST_VERSION} \n \l
" | sudo tee /etc/issue

  sudo cp /etc/os-release /usr/lib/os-release || true
}

#==========================
# Main Function
#==========================

function main() {
    print_ok "============================================"
    print_ok "EDYOUOS ${LATEST_VERSION} - Initial System Setup"
    print_ok "============================================"
    
    ensureCurrentOsEdyouOs
    
    print_ok "Configuring system identification files..."
    applyLsbRelease
    judge "System identification configuration"
    
    print_ok ""
    print_ok "============================================"
    print_ok "✓ EDYOUOS ${LATEST_VERSION} setup completed! ╰(*°▽°*)╯"
    print_ok "✓ System version: ${LATEST_VERSION}"
    print_ok "✓ Release codename: ${CODE_NAME}"
    print_ok "============================================"
}

main
