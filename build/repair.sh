#!/bin/bash

set -e
set -o pipefail
set -u

PKG_TEMP_FILE=$(mktemp)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
export SQUASH_FILE="$PROJECT_ROOT/build/image/casper/filesystem.squashfs"
export DCONF_FILE="$PROJECT_ROOT/build/image/casper/default-dconf.ini"
trap 'rm -f "$PKG_TEMP_FILE"' EXIT

Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Font="\033[0m"
OK="${Green}[  OK  ]${Font}"
ERROR="${Red}[FAILED]${Font}"
WARNING="${Yellow}[ WARN ]${Font}"

function print_ok() { echo -e "${OK} ${Blue} $1 ${Font}"; }
function print_error() { echo -e "${ERROR} ${Red} $1 ${Font}"; }
function print_warn() { echo -e "${WARNING} ${Yellow} $1 ${Font}"; }

function judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 succeeded"
    sleep 0.2
  else
    print_error "$1 failed"
    exit 1
  fi
}

function clean_up() {
  print_ok "Cleaning up old files..."
  sudo umount /mnt/edyouos_squashfs >/dev/null 2>&1 || true
  sudo rm -rf /mnt/edyouos_squashfs >/dev/null 2>&1 || true
  print_ok "Cleanup succeeded"
}

check_apt_format() {
    local old_format=false
    local new_format=false
    
    if [ -f "/etc/apt/sources.list" ]; then
        if grep -v '^#' /etc/apt/sources.list | grep -q '[^[:space:]]'; then
            old_format=true
        fi
    fi
    
    if [ -f "/etc/apt/sources.list.d/ubuntu.sources" ]; then
        if grep -v '^#' /etc/apt/sources.list.d/ubuntu.sources | grep -q '[^[:space:]]'; then
            new_format=true
        fi
    fi
    
    if $old_format && $new_format; then echo "both";
    elif $old_format; then echo "old";
    elif $new_format; then echo "new";
    else echo "none"; fi
}

find_fastest_mirror() {
    echo "Testing mirror speeds..." >&2
    local codename=$(lsb_release -cs)
    
    local mirrors=(
        "https://archive.ubuntu.com/ubuntu/"
        "https://mirror.aarnet.edu.au/pub/ubuntu/archive/"
        "https://mirror.fsmg.org.nz/ubuntu/"
        "https://mirrors.neterra.net/ubuntu/archive/"
        "https://mirror.csclub.uwaterloo.ca/ubuntu/"
        "https://mirrors.dotsrc.org/ubuntu/"
        "https://mirrors.nic.funet.fi/ubuntu/"
        "https://mirror.ubuntu.ikoula.com/"
        "https://mirror.xtom.com.hk/ubuntu/"
        "https://mirror.piconets.webwerks.in/ubuntu-mirror/ubuntu/"
        "https://ftp.udx.icscoe.jp/Linux/ubuntu/"
        "https://ftp.kaist.ac.kr/ubuntu/"
        "https://ubuntu.mirror.garr.it/ubuntu/"
        "https://ftp.uni-stuttgart.de/ubuntu/"
        "https://mirror.i3d.net/pub/ubuntu/"
        "https://mirroronet.pl/pub/mirrors/ubuntu/"
        "https://ubuntu.mobinhost.com/ubuntu/"
        "http://sg.archive.ubuntu.com/ubuntu/"
        "https://mirror.enzu.com/ubuntu/"
    )
    
    declare -A results
    local private_mirror_found=""
    
    for mirror in "${mirrors[@]}"; do
        echo "Testing $mirror ..." >&2
        local hostname=$(echo "$mirror" | awk -F'/' '{print $3}')
        local ip_address=$(getent ahostsv4 "$hostname" | awk '{print $1; exit}' 2>/dev/null) || true
        
        if [ -n "$ip_address" ]; then
            if echo "$ip_address" | grep -E -q '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)'; then
                echo "  Found private IP $ip_address. Selecting $mirror immediately." >&2
                private_mirror_found="$mirror"
                break
            fi
        fi
        
        local response="$(curl -o /dev/null -s -w "%{http_code} %{time_total}\n" --connect-timeout 1 --max-time 3 "${mirror}dists/${codename}/Release")"
        local http_code=$(echo "$response" | awk '{print $1}')
        local time_total=$(echo "$response" | awk '{print $2}')
        
        if [ "$http_code" -eq 200 ]; then
            results["$mirror"]="$time_total"
            echo "  Success: $time_total seconds" >&2
        else
            echo "  Failed: HTTP code $http_code" >&2
            results["$mirror"]="9999"
        fi
    done
    
    if [ -n "$private_mirror_found" ]; then
        echo >&2
        echo "=== Private mirror selected ===" >&2
        echo "Using $private_mirror_found" >&2
        echo >&2
        echo "$private_mirror_found"
    else
        local sorted_mirrors="$(
            for url in "${!results[@]}"; do
                echo "$url ${results[$url]}"
            done | sort -k2 -n
        )"
        
        echo >&2
        echo "=== Mirrors sorted by response time ===" >&2
        echo "$sorted_mirrors" >&2
        echo >&2
        
        local fastest_mirror="$(echo "$sorted_mirrors" | head -n 1 | awk '{print $1}')"
        
        if [[ "$fastest_mirror" == "" || "${results[$fastest_mirror]}" == "9999" ]]; then
            echo "No usable mirror found, using default mirror" >&2
            fastest_mirror="http://archive.ubuntu.com/ubuntu/"
        fi
        
        echo "Fastest mirror found: $fastest_mirror" >&2
        echo >&2
        echo "$fastest_mirror"
    fi
}

generate_old_format() {
    local mirror="$1"
    local codename="$2"
    echo "Generating old format sources.list"
    sudo tee /etc/apt/sources.list >/dev/null <<EOF
deb $mirror $codename main restricted universe multiverse
deb $mirror $codename-updates main restricted universe multiverse
deb $mirror $codename-backports main restricted universe multiverse
deb $mirror $codename-security main restricted universe multiverse
EOF
}

generate_new_format() {
    local mirror="$1"
    local codename="$2"
    echo "Generating new format sources.list"
    sudo tee /etc/apt/sources.list.d/ubuntu.sources >/dev/null <<EOF
Types: deb
URIs: $mirror
Suites: $codename
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: $mirror
Suites: $codename-updates
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: $mirror
Suites: $codename-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: $mirror
Suites: $codename-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
}

update_apt_mirrors() {
    sudo apt update
    sudo apt install -y curl lsb-release libc-bin
    
    local format=$(check_apt_format)
    echo "Current APT source format: $format"
    
    local codename=$(lsb_release -cs)
    echo "Ubuntu codename: $codename"
    
    echo "Finding fastest mirror..."
    local fastest_mirror=$(find_fastest_mirror)
    
    case "$format" in
        "none"|"old")
            generate_old_format "$fastest_mirror" "$codename"
            ;;
        "new"|"both")
            [[ "$format" == "both" ]] && sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
            generate_new_format "$fastest_mirror" "$codename"
            ;;
    esac
    
    sudo apt update
    echo "APT source optimization completed!"
    
    local aptVersion=$(apt --version | head -n 1 | awk '{print $2}')
    local apt_major_version=$(echo "$aptVersion" | cut -d. -f1)
    
    if [[ $apt_major_version -ge 3 && "$format" == "old" ]]; then
        echo "APT 3.0+, converting to new format"
        sudo apt modernize-sources
    fi
}

clean_up

print_ok "Checking ISO and system compatibility..."

DISK_INFO_FILE="$PROJECT_ROOT/build/image/.disk/info"
if [ ! -f "$DISK_INFO_FILE" ]; then
    print_error ".disk/info not found!"
    exit 1
fi

ISO_PRODUCT=$(awk '{print $1}' "$DISK_INFO_FILE")
ISO_VERSION=$(awk '{print $2}' "$DISK_INFO_FILE")
ISO_CODENAME=$(awk '{print $3}' "$DISK_INFO_FILE")
ISO_ARCH=$(awk '{print $6}' "$DISK_INFO_FILE")

if [ ! -f "/etc/lsb-release" ]; then
    print_error "/etc/lsb-release not found!"
    exit 1
fi

source /etc/lsb-release
SYS_PRODUCT=$DISTRIB_ID
SYS_VERSION=$DISTRIB_RELEASE
SYS_CODENAME=$DISTRIB_CODENAME
SYS_ARCH=$(dpkg --print-architecture)

ISO_MAJOR_MINOR=$(echo "$ISO_VERSION" | cut -d'.' -f1-2)
SYS_MAJOR_MINOR=$(echo "$SYS_VERSION" | cut -d'.' -f1-2)

if [[ "$ISO_MAJOR_MINOR" != "$SYS_MAJOR_MINOR" ]]; then
    print_error "Version Mismatch (Major.Minor)."
    exit 1
elif [[ "$ISO_VERSION" != "$SYS_VERSION" ]]; then
    print_warn "Version Mismatch (Patch)."
    read -p "Force continue? (y/N): " force_confirm
    if [[ "$force_confirm" != "y" ]]; then
        exit 1
    fi
fi

print_ok "ISO: $ISO_PRODUCT $ISO_VERSION ($ISO_CODENAME) $ISO_ARCH"
print_ok "System: $SYS_PRODUCT $SYS_VERSION ($SYS_CODENAME) $SYS_ARCH"

[[ "$SYS_PRODUCT" != "$ISO_PRODUCT" ]] && print_error "Product mismatch!" && exit 1
[[ "$SYS_CODENAME" != "$ISO_CODENAME" ]] && print_error "Codename mismatch!" && exit 1
[[ "$SYS_ARCH" != "$ISO_ARCH" ]] && print_error "Architecture mismatch!" && exit 1

print_ok "System compatible with repair ISO."
judge "System compatibility check"

echo -e "${Yellow}WARNING: This will repair $ISO_PRODUCT ($ISO_CODENAME).${Font}"
echo -e "${Yellow}Some files may be overwritten. Continue?${Font}"
read -p "(y/N): " confirm
[[ "$confirm" != "y" ]] && print_error "Aborted." && exit 1

[[ "$(id -u)" -eq 0 ]] && print_error "Don't run as root!" && exit 1

if command -v dracut &> /dev/null || dpkg -l dracut 2>/dev/null | grep -q "^ii"; then
    print_error "dracut not supported!"
    exit 1
fi
print_ok "No conflicting initramfs system."

print_ok "Installing curl..."
sudo apt install -y curl || sudo apt update && sudo apt install -y curl
judge "Install curl"

print_ok "Verifying ISO content..."
(cd "$PROJECT_ROOT/build/image" && sudo md5sum -c md5sum.txt)
judge "ISO integrity verification"

print_ok "Mounting filesystem.squashfs..."
sudo mkdir -p /mnt/edyouos_squashfs
sudo mount -o loop,ro "$SQUASH_FILE" /mnt/edyouos_squashfs
judge "Mount squashfs"

print_ok "Backing up APT configuration..."
sudo mkdir /etc/apt/preferences.d.bak >/dev/null 2>&1 || true
sudo rsync -Aax /etc/apt/preferences.d/ /etc/apt/preferences.d.bak/ >/dev/null 2>&1 || true
judge "Backup APT config"

print_ok "Resetting APT configuration..."
sudo rm /etc/apt/preferences.d/* >/dev/null 2>&1 || true

print_ok "Updating mirrors..."
update_apt_mirrors
judge "Update mirrors"

print_ok "Updating Mozilla PPA..."
sudo rm -f /etc/apt/sources.list.d/mozillateam*
sudo rsync -Aax /mnt/edyouos_squashfs/etc/apt/sources.list.d/mozillateam* /etc/apt/sources.list.d/
sudo apt update
judge "Update Mozilla PPA"

print_ok "Generating package list..."
MANIFEST_FILE="$PROJECT_ROOT/build/image/casper/filesystem.manifest-desktop"

cut -d' ' -f1 "$MANIFEST_FILE" | grep -v '^linux-' | grep -v '^lib' | grep -v '^plymouth-' | grep -v '^software-properties-' | grep -v '^python3-software-properties-' | grep -v '=' > "$PKG_TEMP_FILE"

if [ ! -s "$PKG_TEMP_FILE" ]; then
    print_ok "No missing packages."
else
    if xargs sudo apt install --no-install-recommends --allow-change-held-packages -y < "$PKG_TEMP_FILE" > /tmp/edyouos-fast-install.log 2>&1; then
        print_ok "Fast install mode succeeded."
        rm -f /tmp/edyouos-fast-install.log
    else
        print_warn "Fast mode failed. Trying robust mode..."
        
        PKG_INSTALL_LOG="/tmp/edyouos-pkg-install.log"
        while read -r pkg; do
            [ -n "$pkg" ] && sudo apt install --no-install-recommends -y "$pkg" > "$PKG_INSTALL_LOG" 2>&1 || print_warn "Failed: $pkg"
        done < "$PKG_TEMP_FILE"
        
        rm -f "$PKG_INSTALL_LOG"
        print_ok "Robust mode finished."
    fi
fi
judge "Install missing packages"

print_ok "Removing obsolete packages..."
sudo apt purge -y \
  distro-info software-properties-gtk ubuntu-advantage-tools \
  ubuntu-pro-client ubuntu-pro-client-l10n ubuntu-release-upgrader-gtk \
  ubuntu-report ubuntu-settings update-notifier-common update-manager \
  update-manager-core update-notifier ubuntu-release-upgrader-core \
  ubuntu-advantage-desktop-daemon kgx --allow-change-held-packages
judge "Remove obsolete packages"

install_spg_clean() {
    print_ok "Installing software-properties-gtk clean..."
    
    SP_BUILD_DIR=$(mktemp -d)
    sudo apt install -y --no-install-recommends \
        software-properties-common python3-dateutil gir1.2-handy-1 libgtk3-perl dpkg-dev
    judge "Build deps"
    
    pushd "$SP_BUILD_DIR" > /dev/null
        apt-get download "software-properties-gtk"
        judge "Download"
        
        DEB_FILE=$(ls *.deb | head -n 1)
        mkdir original
        dpkg-deb -R "$DEB_FILE" original
        
        sed -i '/^Depends:/s/, *ubuntu-pro-client//; /^Depends:/s/, *ubuntu-advantage-desktop-daemon//' original/DEBIAN/control
        
        MOD_DEB="modified-software-properties-gtk.deb"
        dpkg-deb -b original "$MOD_DEB"
        sudo apt install -y "./$MOD_DEB"
        
    popd > /dev/null
    rm -rf "$SP_BUILD_DIR"
    judge "Install modified SPG"
    
    TARGET_PY_FILE="/usr/lib/python3/dist-packages/softwareproperties/gtk/SoftwarePropertiesGtk.py"
    if [ -f "$TARGET_PY_FILE" ]; then
        sudo cp "$TARGET_PY_FILE" "${TARGET_PY_FILE}.bak"
        sudo sed -i '/^from \.UbuntuProPage import UbuntuProPage$/d' "$TARGET_PY_FILE"
        sudo sed -i '/^[[:space:]]*def init_ubuntu_pro/,/^[[:space:]]*$/d' "$TARGET_PY_FILE"
        sudo sed -i '/^[[:space:]]*if is_current_distro_lts()/,/self.init_ubuntu_pro()/d' "$TARGET_PY_FILE"
        judge "Patch SPG"
    fi
}

install_spg_clean

print_ok "Upgrading GNOME extensions..."
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/usr/share/gnome-shell/extensions/ /usr/share/gnome-shell/extensions/
judge "Upgrade GNOME extensions"

print_ok "Upgrading icons and themes..."
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/usr/share/icons/ /usr/share/icons/
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/usr/share/themes/ /usr/share/themes/
judge "Upgrade icons/themes"

print_ok "Installing Intel SOF..."
sudo rsync -Aax --update /mnt/edyouos_squashfs/lib/firmware/intel/sof* /lib/firmware/intel/
sudo rsync -Aax --update /mnt/edyouos_squashfs/usr/local/bin/sof-* /usr/local/bin/
sudo rsync -Aax --update /mnt/edyouos_squashfs/usr/share/alsa/ucm2/ /usr/share/alsa/ucm2/
judge "Install Intel SOF"

print_ok "Upgrading backgrounds..."
sudo rsync -Aax --update /mnt/edyouos_squashfs/usr/share/backgrounds/ /usr/share/backgrounds/
sudo rsync -Aax --update /mnt/edyouos_squashfs/usr/share/gnome-background-properties/ /usr/share/gnome-background-properties/
judge "Upgrade backgrounds"

print_ok "Upgrading APT configuration..."
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/etc/apt/apt.conf.d/ /etc/apt/apt.conf.d/
judge "Upgrade APT config"

print_ok "Upgrading APT preferences..."
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/etc/apt/preferences.d/ /etc/apt/preferences.d/
judge "Upgrade APT prefs"

sudo apt-mark hold software-properties-gtk base-files plymouth-theme-spinner software-properties-common || true

print_ok "Upgrading session files..."
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/usr/share/gnome-session/sessions/ /usr/share/gnome-session/sessions/
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/usr/share/wayland-sessions/ /usr/share/wayland-sessions/
judge "Upgrade sessions"

print_ok "Upgrading pixmaps..."
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/usr/share/pixmaps/ /usr/share/pixmaps/
judge "Upgrade pixmaps"

print_ok "Upgrading /etc/skel/..."
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/etc/skel/ /etc/skel/
judge "Upgrade skel"

print_ok "Upgrading python-apt templates..."
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/usr/share/python-apt/templates/ /usr/share/python-apt/templates/
sudo rsync -Aax --update --delete /mnt/edyouos_squashfs/usr/share/distro-info/ /usr/share/distro-info/
judge "Upgrade templates"

print_ok "Upgrading deskmon..."
sudo rsync -Aax /mnt/edyouos_squashfs/usr/local/bin/deskmon /usr/local/bin/deskmon
sudo rsync -Aax /mnt/edyouos_squashfs/etc/systemd/user/deskmon.service /etc/systemd/user/deskmon.service
sudo rsync -Aax /mnt/edyouos_squashfs/etc/systemd/user/default.target.wants/deskmon.service /etc/systemd/user/default.target.wants/deskmon.service
judge "Upgrade deskmon"

print_ok "Updating version info..."
sudo rsync -Aax /mnt/edyouos_squashfs/usr/local/bin/do_edyouos_upgrade /usr/local/bin/do_edyouos_upgrade
sudo rsync -Aax /mnt/edyouos_squashfs/usr/local/bin/do-edyouos-autorepair /usr/local/bin/do-edyouos-autorepair
sudo rsync -Aax /mnt/edyouos_squashfs/usr/local/bin/toggle_network_stats /usr/local/bin/toggle_network_stats
sudo rsync -Aax /mnt/edyouos_squashfs/usr/bin/add-apt-repository /usr/bin/add-apt-repository
sudo rsync -Aax /mnt/edyouos_squashfs/etc/lsb-release /etc/lsb-release
sudo rsync -Aax /mnt/edyouos_squashfs/etc/issue /etc/issue
sudo rsync -Aax /mnt/edyouos_squashfs/etc/issue.net /etc/issue.net
sudo rsync -Aax /mnt/edyouos_squashfs/etc/os-release /etc/os-release
sudo rsync -Aax /mnt/edyouos_squashfs/usr/lib/os-release /usr/lib/os-release
sudo rsync -Aax /mnt/edyouos_squashfs/etc/legal /etc/legal
sudo rsync -Aax /mnt/edyouos_squashfs/etc/sysctl.d/20-apparmor-donotrestrict.conf /etc/sysctl.d/20-apparmor-donotrestrict.conf
sudo rsync -Aax /mnt/edyouos_squashfs/var/lib/flatpak/repo/config /var/lib/flatpak/repo/config
sudo rsync -Aax /mnt/edyouos_squashfs/usr/share/plymouth/themes/spinner/bgrt-fallback.png /usr/share/plymouth/themes/spinner/bgrt-fallback.png
sudo rsync -Aax /mnt/edyouos_squashfs/usr/share/plymouth/themes/spinner/watermark.png /usr/share/plymouth/themes/spinner/watermark.png
sudo rsync -Aax /mnt/edyouos_squashfs/usr/share/plymouth/ubuntu-logo.png /usr/share/plymouth/ubuntu-logo.png
judge "Update version info"

print_ok "Applying dconf settings..."
cat "$DCONF_FILE" | dconf load /org/gnome/
judge "Apply dconf"

print_ok "Updating initramfs..."
sudo update-initramfs -u -k all
judge "Update initramfs"

print_ok "Updating GRUB..."
sudo update-grub
judge "Update GRUB"

print_ok "Upgrading packages..."
sudo apt upgrade -y
sudo apt autoremove --purge -y
judge "Package upgrade"

print_ok "Upgrade complete! Please reboot."

clean_up