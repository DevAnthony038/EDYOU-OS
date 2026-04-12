set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Install Gnome Extension EDYOUOS Location Switcher"
cp ./loc@edyouos.com /usr/share/gnome-shell/extensions/loc@edyouos.com -rf
judge "Install Gnome Extension EDYOUOS Location Switcher"
