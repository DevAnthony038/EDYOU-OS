set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script installs the Gnome Extension EDYOUOS Switcher for the target system.

print_ok "Install Gnome Extension EDYOUOS Switcher"
cp ./switcher@edyouos /usr/share/gnome-shell/extensions/switcher@edyouos -rf
judge "Install Gnome Extension EDYOUOS Switcher"
