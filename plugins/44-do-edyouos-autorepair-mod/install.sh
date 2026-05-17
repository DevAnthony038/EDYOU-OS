set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script adds a new command "edyouos-autorepair" to the target system, which is a custom script that performs various repair and maintenance tasks for the target system.

print_ok "Adding new command to this OS: edyouos-autorepair..."
cp ./edyouos-autorepair.sh /usr/local/bin/edyouos-autorepair
chmod +x /usr/local/bin/edyouos-autorepair
judge "Add new command edyouos-autorepair"
