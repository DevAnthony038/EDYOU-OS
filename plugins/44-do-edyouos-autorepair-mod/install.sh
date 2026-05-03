set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Adding new command to this OS: edyouos-autorepair..."
cp ./edyouos-autorepair.sh /usr/local/bin/edyouos-autorepair
chmod +x /usr/local/bin/edyouos-autorepair
judge "Add new command edyouos-autorepair"
