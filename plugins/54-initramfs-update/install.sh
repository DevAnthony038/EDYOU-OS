set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script updates the initramfs for the target system.
# This is necessary because the initramfs may not have the latest kernel modules and configuration for the target system.

# Update initramfs
update-initramfs -u -k all
judge "Update /etc/casper.conf"
