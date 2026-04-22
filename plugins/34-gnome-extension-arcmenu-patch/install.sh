set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Patching Arc Menu..."

print_ok "Patch Arc Menu logo..."
sudo mkdir -p /usr/share/gnome-shell/extensions/arcmenu@arcmenu.com/icons/
mv ./logo.png /usr/share/gnome-shell/extensions/arcmenu@arcmenu.com/icons/edyouos-logo.png
judge "Patch Arc Menu logo"

print_ok "Patch Arc Menu text..."
sed -i 's/Unpin from ArcMenu/Unpin from Start menu/g' /usr/share/gnome-shell/extensions/arcmenu@arcmenu.com/appMenu.js
sed -i 's/Pin to ArcMenu/Pin to Start menu/g' /usr/share/gnome-shell/extensions/arcmenu@arcmenu.com/appMenu.js
judge "Patch Arc Menu text"