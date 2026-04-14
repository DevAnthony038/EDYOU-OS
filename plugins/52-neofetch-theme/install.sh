set -e
set -o pipefail
set -u

source /root/plugins/logging.sh
source /root/plugins/config.sh

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
NEOFETCH_SOURCE="$SCRIPT_DIR/neofetch"
NEOFETCH_TARGET="/usr/bin/neofetch"

print_ok "Installing neofetch theme..."

if [ ! -f "$NEOFETCH_SOURCE" ]; then
    print_error "Neofetch source file not found: $NEOFETCH_SOURCE"
    exit 1
fi

if [ -f "$NEOFETCH_TARGET" ]; then
    print_ok "Removing existing neofetch..."
    sudo rm -f "$NEOFETCH_TARGET" || {
        print_error "Failed to remove existing neofetch"
        exit 1
    }
fi

sudo install -m 755 "$NEOFETCH_SOURCE" "$NEOFETCH_TARGET" || {
    print_error "Failed to install neofetch to $NEOFETCH_TARGET"
    exit 1
}

if [ -x "$NEOFETCH_TARGET" ]; then
    print_ok "Neofetch installed successfully to $NEOFETCH_TARGET"
else
    print_error "Neofetch installed but not executable"
    exit 1
fi

judge "Install neofetch theme"