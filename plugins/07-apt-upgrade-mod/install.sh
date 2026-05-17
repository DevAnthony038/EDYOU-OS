set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script updates the packages for the target system. This is necessary because debootstrap may not have the latest package list.

print_ok "Updating packages..."
wait_network
apt -y upgrade
judge "Upgrade packages"
