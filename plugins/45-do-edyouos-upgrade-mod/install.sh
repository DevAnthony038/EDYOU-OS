set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Adding new command to this OS: do_edyouos_upgrade..."
cp ./do-edyouos-upgrade.sh /usr/local/bin/do_edyouos_upgrade
chmod +x /usr/local/bin/do_edyouos_upgrade
judge "Add new command do_edyouos_upgrade"

