set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

if [ "$FIREFOX_PROVIDER" == "none" ]; then
    print_ok "We don't need to install firefox, please check the config file"
elif [ "$FIREFOX_PROVIDER" == "deb" ]; then
    print_ok "Adding Mozilla Firefox PPA"
    wait_network
    apt install $INTERACTIVE software-properties-common
    # Retry wrapper for transient network/API errors (Launchpad may return 504)
    retry_cmd() {
        local retries=5
        local count=0
        local delay=5
        while [ $count -lt $retries ]; do
            if "$@"; then
                return 0
            fi
            count=$((count+1))
            print_warn "Command failed: $* (attempt $count/$retries). Retrying in $delay seconds..."
            sleep $delay
            delay=$((delay*2))
        done
        return 1
    }

    # Try add-apt-repository up to 3 times with a fixed 5s delay.
    check_launchpad_status() {
        local status_url="https://isdown.app/status/canonical/ppa-launchpad-net"
        print_warn "Checking Launchpad PPA status: $status_url"
        if command -v curl >/dev/null 2>&1; then
            if curl -fsS "$status_url" 2>/dev/null | grep -qiE "down|unreachable|offline|is down"; then
                print_warn "Status page suggests the service may be down. See: $status_url"
            else
                print_ok "Status page reachable; issue may be network/DNS. See: $status_url"
            fi
        elif command -v wget >/dev/null 2>&1; then
            if wget -q -O- "$status_url" 2>/dev/null | grep -qiE "down|unreachable|offline|is down"; then
                print_warn "Status page suggests the service may be down. See: $status_url"
            else
                print_ok "Status page reachable; issue may be network/DNS. See: $status_url"
            fi
        else
            print_warn "No curl/wget available to check status page; please check: $status_url"
        fi
    }

    attempt=0
    max_attempts=3
    while [ $attempt -lt $max_attempts ]; do
        if add-apt-repository -y ppa:mozillateam/ppa; then
            break
        fi
        attempt=$((attempt+1))
        if [ $attempt -lt $max_attempts ]; then
            print_warn "add-apt-repository failed (attempt $attempt/$max_attempts). Retrying in 5 seconds..."
            sleep 5
        fi
    done
    if [ $attempt -ge $max_attempts ]; then
        print_error "add-apt-repository failed after $max_attempts attempts. Checking Launchpad status and falling back to manual source."
        check_launchpad_status || true
        codename=$(lsb_release -sc)
        cat > /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-${codename}.list <<EOF
deb http://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu ${codename} main
EOF
        chown root:root /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-${codename}.list
        print_warn "Manual sources file created. If 'apt update' fails due to a missing signing key,"
        print_warn "import the PPA key manually (example):"
        print_warn "  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <KEYID>"
    fi
    if [ -n "$BUILD_FIREFOX_MIRROR" ]; then
        print_ok "Replace ppa.launchpadcontent.net with $BUILD_FIREFOX_MIRROR to get faster download speed"
        sed -i "s/ppa.launchpadcontent.net/$BUILD_FIREFOX_MIRROR/g" \
            /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(lsb_release -sc).sources
    fi
    cat << EOF > /etc/apt/preferences.d/mozilla-firefox
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox
Pin: version 1:1snap*
Pin-Priority: -1
EOF
    chown root:root /etc/apt/preferences.d/mozilla-firefox
    judge "Add Mozilla Firefox PPA"

    print_ok "Updating package list to refresh firefox package cache"
    apt update
    judge "Update package list"

    print_ok "Installing Firefox and locale package $FIREFOX_LOCALE_PACKAGE from PPA: ${BUILD_FIREFOX_MIRROR:-ppa.launchpadcontent.net}"
    # Final fallback: download official Firefox tarball from Mozilla and install to /opt/firefox
    download_firefox_tarball() {
        local tmpdir arch os lang url code
        tmpdir=$(mktemp -d) || return 1
        arch=$(uname -m)
        case "$arch" in
            x86_64|amd64) os=linux64 ;;
            aarch64|arm64) os=linux-aarch64 ;;
            *) os=linux32 ;;
        esac
        lang="en-US"
        if [ -n "${FIREFOX_LOCALE_PACKAGE:-}" ]; then
            if echo "$FIREFOX_LOCALE_PACKAGE" | grep -qi 'de'; then
                lang=de
            else
                code=$(echo "$FIREFOX_LOCALE_PACKAGE" | sed -n 's/.*-\([a-z][a-z]\).*/\1/p') || true
                if [ -n "$code" ]; then
                    lang=$code
                fi
            fi
        fi
        url="https://download.mozilla.org/?product=firefox-latest&os=${os}&lang=${lang}"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL -o "$tmpdir/firefox.tar.bz2" "$url" || { rm -rf "$tmpdir"; return 1; }
        elif command -v wget >/dev/null 2>&1; then
            wget -q -O "$tmpdir/firefox.tar.bz2" "$url" || { rm -rf "$tmpdir"; return 1; }
        else
            rm -rf "$tmpdir"
            return 1
        fi
        if [ -d /opt/firefox ]; then
            mv /opt/firefox /opt/firefox.bak-$(date +%s) || true
        fi
        mkdir -p /opt
        tar -xjf "$tmpdir/firefox.tar.bz2" -C /opt || { rm -rf "$tmpdir"; return 1; }
        ln -sf /opt/firefox/firefox /usr/bin/firefox
        chown -R root:root /opt/firefox
        chmod 0755 /opt/firefox/firefox
        rm -rf "$tmpdir"
        return 0
    }
    
    # If APT has no candidate for 'firefox' (Ubuntu often ships firefox as a snap),
    # attempt fallbacks (snap then flatpak). Use conditional checks so failures
    # don't abort the whole script immediately (we're inside the handler).
    if apt-cache policy firefox 2>/dev/null | grep -q "Candidate: (none)"; then
        print_warn "No APT candidate for 'firefox' — attempting snap/flatpak fallbacks"
        FFX_INSTALLED=0
        if command -v snap >/dev/null 2>&1; then
            print_ok "Trying to install firefox via snap..."
            if snap install firefox; then
                judge "Install Firefox (snap)"
                FFX_INSTALLED=1
            else
                print_warn "snap install failed"
            fi
        fi
        if [ $FFX_INSTALLED -eq 0 ] && command -v flatpak >/dev/null 2>&1; then
            print_ok "Trying to install firefox via flatpak..."
            if flatpak install -y flathub org.mozilla.firefox; then
                judge "Install Firefox (flatpak)"
                FFX_INSTALLED=1
            else
                print_warn "flatpak install failed"
            fi
        fi
        if [ $FFX_INSTALLED -eq 0 ]; then
            print_warn "Attempting to download official Firefox tarball as final fallback..."
            if download_firefox_tarball; then
                judge "Install Firefox (tarball)"
                FFX_INSTALLED=1
            else
                print_error "Firefox not available via APT, snap, flatpak, or tarball fallback."
                print_error "It may be a server-side issue; please check: https://isdown.app/status/canonical/ppa-launchpad-net"
                check_launchpad_status || true
                exit 1
            fi
        fi
    else
        if ! apt install $INTERACTIVE firefox $FIREFOX_LOCALE_PACKAGE --no-install-recommends; then
            print_warn "apt install failed — attempting snap/flatpak fallbacks"
            FFX_INSTALLED=0
            if command -v snap >/dev/null 2>&1; then
                print_ok "Trying to install firefox via snap..."
                if snap install firefox; then
                    judge "Install Firefox (snap)"
                    FFX_INSTALLED=1
                else
                    print_warn "snap install failed"
                fi
            fi
            if [ $FFX_INSTALLED -eq 0 ] && command -v flatpak >/dev/null 2>&1; then
                print_ok "Trying to install firefox via flatpak..."
                if flatpak install -y flathub org.mozilla.firefox; then
                    judge "Install Firefox (flatpak)"
                    FFX_INSTALLED=1
                else
                    print_warn "flatpak install failed"
                fi
            fi
            if [ $FFX_INSTALLED -eq 0 ]; then
                print_warn "Attempting to download official Firefox tarball as final fallback..."
                if download_firefox_tarball; then
                    judge "Install Firefox (tarball)"
                    FFX_INSTALLED=1
                else
                    print_error "Firefox install failed via apt and fallbacks, and tarball fallback failed."
                    print_error "It may be a server-side outage; please check: https://isdown.app/status/canonical/ppa-launchpad-net"
                    check_launchpad_status || true
                    exit 1
                fi
            fi
        else
            judge "Install Firefox"
        fi
    fi

    # If both Build mirror and Live mirror are set, replace Build mirror with Live mirror
    if [ -n "$BUILD_FIREFOX_MIRROR" ] && [ -n "$LIVE_FIREFOX_MIRROR" ]; then
        print_ok "Replace $BUILD_FIREFOX_MIRROR with $LIVE_FIREFOX_MIRROR..."
        sed -i "s/$BUILD_FIREFOX_MIRROR/$LIVE_FIREFOX_MIRROR/g" \
            /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(lsb_release -sc).sources
        judge "Replace BUILD_FIREFOX_MIRROR with LIVE_FIREFOX_MIRROR"
    # If only live mirror is set, replace ppa.launchpadcontent.net with live mirror
    elif [ -n "$LIVE_FIREFOX_MIRROR" ]; then
        print_ok "Replace ppa.launchpadcontent.net with $LIVE_FIREFOX_MIRROR..."
        sed -i "s/ppa.launchpadcontent.net/$LIVE_FIREFOX_MIRROR/g" \
            /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(lsb_release -sc).sources
        judge "Replace ppa.launchpadcontent.net with LIVE_FIREFOX_MIRROR"
    else
        print_warn "No BUILD_FIREFOX_MIRROR or LIVE_FIREFOX_MIRROR set, skip replacing mirror"
    fi
elif [ "$FIREFOX_PROVIDER" == "flatpak" ]; then
    print_ok "Installing firefox from flathub..."
    flatpak install -y flathub org.mozilla.firefox
    judge "Install firefox from flathub"
elif [ "$FIREFOX_PROVIDER" == "snap" ]; then
    print_ok "Installing firefox from snap..."
    snap install firefox
    judge "Install firefox from snap"
else
    print_error "Unknown firefox provider: $FIREFOX_PROVIDER"
    print_error "Please check the config file"
    exit 1
fi
