set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Patch plymouth"
cp ./logo_128.png      /usr/share/plymouth/themes/spinner/bgrt-fallback.png
cp ./edyouos_text.png /usr/share/plymouth/ubuntu-logo.png
cp ./edyouos_text.png /usr/share/plymouth/themes/spinner/watermark.png
#---
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme spinner
fi
update-initramfs -u
#---
judge "Patch plymouth and update initramfs"
