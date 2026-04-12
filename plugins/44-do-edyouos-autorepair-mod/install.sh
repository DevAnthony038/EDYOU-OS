set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Adding new command to this OS: do_edyouos_autorepair..."
cp ./do-edyouos-autorepair.sh /usr/local/bin/do_edyouos_autorepair
chmod +x /usr/local/bin/do_edyouos_autorepair
judge "Add new command do_edyouos_autorepair"
