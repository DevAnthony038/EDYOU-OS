set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Adding new command to this OS: edyouos-upgrade..."
cp ./edyouos-upgrade.sh /usr/local/bin/edyouos-upgrade
chmod +x /usr/local/bin/edyouos-upgrade
judge "Add new command edyouos-upgrade"

