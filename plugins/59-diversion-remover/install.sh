set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script removes the diversion for initctl on the target system. 
# This is necessary to ensure that the target system can use the initctl command to manage services and daemons.

print_ok "Removing diversion..."
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
judge "Remove diversion"
