set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script cleans up the /root/.config/ directory and root's gnome-shell extensions to ensure that there are no conflicts with the new settings and extensions that will be applied by the other plugins.
# It uninstalls the gnome-extensions-cli tool, removes the mimeapps.list file, removes the dconf directory, removes the gnome-shell extensions directory, uninstalls all pipx packages, and removes the pipx home directory and cache directory.
# This ensures that the root user starts with a clean slate for the new configuration and extensions.

print_ok "Cleaning up /root/.config/ and root's gnome-shell extensions"
/usr/bin/pipx uninstall gnome-extensions-cli
rm /root/.config/mimeapps.list
rm /root/.config/dconf -rf
rm /root/.local/share/gnome-shell/extensions -rf
/usr/bin/pipx uninstall-all
PIPX_HOME=$(pipx environment --value PIPX_HOME)
rm "$PIPX_HOME" -rf
rm /root/.cache -rf
judge "Clean up /root/.config/ and root's gnome-shell extensions"

