set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script installs the Gnome Extension Notification Bottom Right for the target system.

print_ok "Install Gnome Extension Notification Bottom Right"
cp ./noti-bottom-right@edyouos /usr/share/gnome-shell/extensions/noti-bottom-right@edyouos -rf
judge "Install Gnome Extension Notification Bottom Right"
