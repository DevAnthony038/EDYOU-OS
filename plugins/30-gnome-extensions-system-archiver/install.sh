set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script archives the GNOME extensions to the system level for the target system.

print_ok "Archiving GNOME extensions to system level"
mv /root/.local/share/gnome-shell/extensions/* /usr/share/gnome-shell/extensions/
judge "Archive GNOME extensions"
