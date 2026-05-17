set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script installs systemd and its dependencies for the target system.

print_ok "Installing systemd"

apt update
apt install $INTERACTIVE \
    libterm-readline-gnu-perl \
    systemd-sysv \
    wget \
    krb5-locales \
    publicsuffix \
    libnss-systemd \
    networkd-dispatcher \
    shared-mime-info \
    dmsetup \
    xdg-user-dirs \
    ca-certificates \
    --no-install-recommends
judge "Install systemd"
