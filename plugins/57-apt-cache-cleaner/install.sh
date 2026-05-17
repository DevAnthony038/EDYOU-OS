set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script cleans up the apt cache and log files for the target system. 
#This is necessary to reduce the size of the target system and to ensure that the target system does not contain any unnecessary files.

print_ok "Cleaning up apt cache..."
apt update
apt clean -y
rm -rf /var/cache/apt/archives/*
judge "Clean up apt cache"

print_ok "Cleaning up log files..."
rm -rf /var/log/*
judge "Clean up log files"
