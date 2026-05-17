set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script removes the bash history and temporary files for the target system.
# This is necessary to ensure that the target system does not contain any unnecessary files and to protect the privacy of the user.

print_ok "Removing bash history and temporary files..."
rm -rf /tmp/* ~/.bash_history
judge "Remove bash history and temporary files"

# Disable history in bash to avoid saving commands
export HISTSIZE=0
