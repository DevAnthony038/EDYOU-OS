set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script sets up the initctl for the target system.
# initctl is a part of upstart, which is not compatible with systemd. We need to divert it to avoid conflicts.

print_ok "Setting up initctl..."
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl
judge "Set up initctl"
