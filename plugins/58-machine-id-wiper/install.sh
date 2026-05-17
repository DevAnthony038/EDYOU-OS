set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script truncates the machine id for the target system. This is necessary to ensure that the target system has a unique machine id when it is first booted.

print_ok "Truncating machine id..."
truncate -s 0 /etc/machine-id
truncate -s 0 /var/lib/dbus/machine-id
judge "Truncate machine id"
