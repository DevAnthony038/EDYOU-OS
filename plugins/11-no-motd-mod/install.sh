set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script removes the motd and update-manager for the target system.
# This is necessary because the motd and update-manager may not be compatible with the target system, and they may cause issues with the target system.

print_ok "Removing Ubuntu motd and update-manager"
rm /etc/update-manager/ -rf
rm /etc/update-motd.d/ -rf
judge "Remove Ubuntu motd and update-manager"
