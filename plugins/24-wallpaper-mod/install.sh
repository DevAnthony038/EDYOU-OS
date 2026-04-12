set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Cleaning and reinstalling wallpaper"
rm /usr/share/gnome-background-properties/* -rf
rm /usr/share/backgrounds/* -rf
mv ./dark-bck.png /usr/share/backgrounds/
mv ./light-bck.png /usr/share/backgrounds/
cat << EOF > /usr/share/gnome-background-properties/fluent.dark.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
<wallpaper deleted="false">
<name>Fluent Building Dark</name>
<filename>/usr/share/backgrounds/dark-bck.png</filename>
<options>zoom</options>
<shade_type>solid</shade_type>
</wallpaper>
</wallpapers>
EOF
cat << EOF > /usr/share/gnome-background-properties/fluent.light.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
<wallpaper deleted="false">
    <name>Fluent Building Light</name>
    <filename>/usr/share/backgrounds/light-bck.png</filename>
    <options>zoom</options>
    <shade_type>solid</shade_type>
</wallpaper>
</wallpapers>
EOF
judge "Clean and reinstall wallpaper"
