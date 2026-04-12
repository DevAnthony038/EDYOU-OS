#!/bin/bash
set -e
set -o pipefail
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Load shared config/logging
if [[ -f "$PROJECT_ROOT/core/config.sh" && -f "$PROJECT_ROOT/core/logging.sh" ]]; then
    source "$PROJECT_ROOT/core/config.sh"
    source "$PROJECT_ROOT/core/logging.sh"
elif [[ -f "$PROJECT_ROOT/plugins/config.sh" && -f "$PROJECT_ROOT/plugins/logging.sh" ]]; then
    source "$PROJECT_ROOT/plugins/config.sh"
    source "$PROJECT_ROOT/plugins/logging.sh"
else
    echo "Could not find core/config.sh or plugins/config.sh"
    exit 1
fi

if [[ -z "${ONLYOFFICE_PROVIDER+x}" ]]; then
    ONLYOFFICE_PROVIDER="deb"
fi

function ensure_flatpak() {
    print_ok "Ensuring flatpak is installed"
    if ! command -v flatpak >/dev/null 2>&1; then
        apt update
        apt install $INTERACTIVE -y flatpak
        judge "Install flatpak"
    fi

    if ! flatpak remotes | grep -q '^flathub[[:space:]]'; then
        print_ok "Adding flathub remote"
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        judge "Add flathub remote"
    fi
}

function ensure_snap() {
    print_ok "Ensuring snapd is installed"
    if ! command -v snap >/dev/null 2>&1; then
        apt update
        apt install $INTERACTIVE -y snapd
        judge "Install snapd"
    fi
}

function install_flatpak_onlyoffice() {
    print_ok "Installing OnlyOffice from flathub"
    wait_network
    ensure_flatpak
    flatpak install -y flathub org.onlyoffice.desktopeditors
    judge "Install onlyoffice from flathub"
}

function install_snap_onlyoffice() {
    print_ok "Installing OnlyOffice from snap"
    wait_network
    ensure_snap
    snap install onlyoffice-desktopeditors
    judge "Install onlyoffice from snap"
}

function install_deb_onlyoffice() {
    print_ok "Installing OnlyOffice from official .deb package"
    wait_network
    apt update
    apt install $INTERACTIVE -y fonts-dejavu fonts-liberation fonts-crosextra-carlito ttf-mscorefonts-installer fonts-takao-gothic || true
    wget -qO /tmp/onlyoffice.deb "https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb"
    apt install $INTERACTIVE -y /tmp/onlyoffice.deb
    judge "Install onlyoffice from .deb"
    rm -f /tmp/onlyoffice.deb
}

print_ok "OnlyOffice provider: $ONLYOFFICE_PROVIDER"
case "$ONLYOFFICE_PROVIDER" in
    none)
        print_ok "Skipping OnlyOffice installation"
        ;;
    flatpak)
        install_flatpak_onlyoffice
        ;;
    snap)
        install_snap_onlyoffice
        ;;
    deb)
        install_deb_onlyoffice
        ;;
    *)
        print_error "Unknown ONLYOFFICE_PROVIDER: $ONLYOFFICE_PROVIDER"
        print_error "Please set ONLYOFFICE_PROVIDER to none, deb, flatpak, or snap"
        exit 1
        ;;
esac
