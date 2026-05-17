set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script removes some of the usr-is-merged folders for the target system.
# This is necessary to ensure that the target system does not contain any unnecessary files and to reduce the size of the target system.
# The usr-is-merged folders are not needed for the target system, and they may cause issues with the target system if they are present.

print_ok "Removing some usr-is-merged folders..."
rm -rf /bin.usr-is-merged
rm -rf /lib.usr-is-merged
rm -rf /sbin.usr-is-merged
judge "Remove some usr-is-merged folders"
