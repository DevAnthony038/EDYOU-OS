set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script replaces the Ubuntu logo text with custom edyouos images.

print_ok "Replacing Ubuntu logo text images"
cp -f ./ubuntu-logo-text.png /usr/share/pixmaps/ubuntu-logo-text.png
cp -f ./ubuntu-logo-text-dark.png /usr/share/pixmaps/ubuntu-logo-text-dark.png
judge "Replace Ubuntu logo text images"