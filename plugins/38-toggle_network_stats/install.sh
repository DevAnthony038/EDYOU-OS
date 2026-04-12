set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u   


print_ok "Adding new command to this OS: toggle_network_stats..."
cat << EOF > /usr/local/bin/toggle_network_stats
#!/bin/bash
status=\$(LC_ALL=C gnome-extensions show "network-stats@gnome.noroadsleft.xyz" | grep "State" | awk '{print \$2}')
if [ "\$status" == "ENABLED" ] || [ "\$status" == "ACTIVE" ]; then
    gnome-extensions disable network-stats@gnome.noroadsleft.xyz
    echo "Disabled network state display"
else
    gnome-extensions enable network-stats@gnome.noroadsleft.xyz
    echo "Enabled network state display"
fi
EOF
chmod +x /usr/local/bin/toggle_network_stats
judge "Add new command toggle_network_stats"