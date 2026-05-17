set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script configures the network manager for the target system. 
# This is necessary to ensure that the target system can connect to the network and access the internet.

print_ok "Configuring network manager..."
cat << EOF > /etc/NetworkManager/NetworkManager.conf
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=dnsmasq

[ifupdown]
managed=false
EOF
dpkg-reconfigure network-manager
judge "Configure network manager"

print_ok "Configuring netplan..."
cat << EOF > /etc/netplan/01-network-manager-all.yaml
network:
  version: 2
  renderer: NetworkManager
EOF
judge "Configure netplan"
