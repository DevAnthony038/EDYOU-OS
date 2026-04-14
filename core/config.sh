#!/bin/bash

#================================================================================
#                           IMPORTANT NOTICE
#================================================================================
# This configuration file establishes the build environment variables
# for generating the EDYOUOS distribution image. Prior to initiating
# a build, modify the variables in this file to align with your requirements.
#
# IMPORTANT: This file must be sourced by the build orchestration scripts.
# DO NOT execute it directly.
#
# After making changes, invoke 'make' to commence the build process.

#================================================================================
# Build Runtime Environment
#================================================================================

export DEBIAN_FRONTEND=noninteractive
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export HOME=/root

# Specifies the package manager's interaction mode.
# Allowed values: "-y" for automated installation, or "" for prompting.
export INTERACTIVE="-y"

#================================================================================
# Localization Configuration
#================================================================================

# Primary locale for the target system.
# Supported locales: en_US, en_GB, zh_CN, zh_TW, zh_HK, ja_JP, ko_KR,
# vi_VN, th_TH, de_DE, fr_FR, es_ES, ru_RU, it_IT, pt_BR, pt_PT,
# ar_SA, nl_NL, sv_SE, pl_PL, tr_TR
export LANG_MODE="de_DE"

# Package identifier for language support installation.
# Valid options: zh, en, ja, ko, vi, th, de, fr, es, ru, it, pt, ar, nl, sv, pl, tr
export LANG_PACK_CODE="de"

export LC_ALL=$LANG_MODE.UTF-8
export LC_CTYPE=$LANG_MODE.UTF-8
export LC_TIME=$LANG_MODE.UTF-8
export LC_NAME=$LANG_MODE.UTF-8
export LC_ADDRESS=$LANG_MODE.UTF-8
export LC_TELEPHONE=$LANG_MODE.UTF-8
export LC_MEASUREMENT=$LANG_MODE.UTF-8
export LC_IDENTIFICATION=$LANG_MODE.UTF-8
export LC_NUMERIC=$LANG_MODE.UTF-8
export LC_PAPER=$LANG_MODE.UTF-8
export LC_MONETARY=$LANG_MODE.UTF-8
export LANG=$LANG_MODE.UTF-8
export LANGUAGE=$LANG_MODE:$LANG_PACK_CODE

# Language support packages to be provisioned.
export LANGUAGE_PACKS="language-pack-$LANG_PACK_CODE* language-pack-gnome-$LANG_PACK_CODE*"

# Output confirmation message.
echo "Language environment has been set to $LANG_MODE"

#================================================================================
# Base Distribution Configuration
#================================================================================

# Ubuntu release codename serving as the foundation.
# Recognized values:
#   - jammy    : Ubuntu 22.04 LTS
#   - noble   : Ubuntu 24.04 LTS  
#   - oracular: Ubuntu 24.10
#   - plucky  : Ubuntu 25.04
#   - questing: Ubuntu 25.10
export TARGET_UBUNTU_VERSION="noble"

# Debian package archive mirror location.
export BUILD_UBUNTU_MIRROR="http://archive.ubuntu.com/ubuntu/"

# Internal identifier for the distribution.
export TARGET_NAME="edyouos"

# Public-facing name for the distribution.
export TARGET_BUSINESS_NAME="EDYOUOS"

# Distribution version identifier.
export TARGET_BUILD_VERSION="1.0.1"

# Git branch or development fork identifier.
export TARGET_BUILD_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

#================================================================================
# Package Exclusion Configuration
#================================================================================

# Packages to be removed during the customization phase.
export TARGET_PACKAGE_REMOVE="
    ubiquity \
    casper \
    discover \
    laptop-detect \
    os-prober \
"

#================================================================================
# Software Center Configuration
#================================================================================

# Application store backend selection.
# Options:
#   none  : Omit store installation
#   web   : Provide web-based store access
#   flatpak: Integrate Flatpak package manager
#   snap  : Integrate Snap package manager
export STORE_PROVIDER="web"

# Mirror URL for Flatpak repository.
export FLATHUB_MIRROR=""
if [[ "$FLATHUB_MIRROR" != "" && "$STORE_PROVIDER" != "flatpak" ]]; then
    echo "Error: FLATHUB_MIRROR is set, but STORE_PROVIDER is not set to flatpak"
    exit 1
fi

# Mirror authentication key file URL.
export FLATHUB_GPG=""
if [[ "$FLATHUB_GPG" != "" && "$FLATHUB_MIRROR" == "" ]]; then
    echo "Error: FLATHUB_GPG is set, but FLATHUB_MIRROR is not set"
    exit 1
fi

#================================================================================
# Web Browser Configuration
#================================================================================

# Firefox installation methodology.
# Options:
#   none   : Omit browser installation
#   deb    : Install via official Mozilla PPA
#   flatpak: Install from Flatpak repository
#   snap   : Install from Snap Store
export FIREFOX_PROVIDER="deb"
if [[ "$FIREFOX_PROVIDER" == "flatpak" && "$STORE_PROVIDER" != "flatpak" ]]; then
    echo "Error: FIREFOX_PROVIDER is set to flatpak, but STORE_PROVIDER is not set to flatpak"
    exit 1
fi
if [[ "$FIREFOX_PROVIDER" == "snap" && "$STORE_PROVIDER" != "snap" ]]; then
    echo "Error: FIREFOX_PROVIDER is set to snap, but STORE_PROVIDER is not set to snap"
    exit 1
fi

# Mirror for Firefox package installation.
export BUILD_FIREFOX_MIRROR="ppa.launchpadcontent.net"
if [[ "$BUILD_FIREFOX_MIRROR" != "" && "$FIREFOX_PROVIDER" != "deb" ]]; then
    echo "Error: BUILD_FIREFOX_MIRROR is set, but FIREFOX_PROVIDER is not set to deb"
    exit 1
fi

# Live system Firefox mirror override.
export LIVE_FIREFOX_MIRROR="ppa.launchpadcontent.net"
if [[ "$FIREFOX_PROVIDER" == "deb" && -z "$LIVE_FIREFOX_MIRROR" ]]; then
    echo "Error: FIREFOX_PROVIDER is deb, but didn't set LIVE_FIREFOX_MIRROR"
    exit 1
fi

# Firefox localization package identifier.
export FIREFOX_LOCALE_PACKAGE="firefox-locale-$LANG_PACK_CODE*"
if [[ "$FIREFOX_LOCALE_PACKAGE" != "" && "$FIREFOX_PROVIDER" != "deb" ]]; then
    echo "Error: FIREFOX_LOCALE_PACKAGE is set, but FIREFOX_PROVIDER is not set to deb"
    exit 1
fi

#================================================================================
# Office Productivity Suite Configuration
#================================================================================

# OnlyOffice installation source selection.
# Options:
#   none   : Skip office suite installation
#   deb    : Install from official .deb package
#   flatpak: Install from Flatpak (functions regardless of STORE_PROVIDER)
#   snap   : Install from Snap Store
export ONLYOFFICE_PROVIDER="flatpak"

#================================================================================
# Input Method Configuration
#================================================================================

# Input method editor packages to be installed.
# Supported options:
#   ibus-rime         : Chinese Rime IME
#   ibus-libpinyin    : Chinese Pinyin input
#   ibus-chewing     : Traditional Chinese Chewing
#   ibus-table-cangjie: Cangjie table-based input
#   ibus-mozc        : Japanese input
#   ibus-hangul     : Korean Hangul input
#   ibus-unikey     : Vietnamese input
#   ibus-libthai    : Thai input support
export INPUT_METHOD_INSTALL=""

# Enable Rime input method integration.
export CONFIG_IBUS_RIME="false"
if [[ "$CONFIG_IBUS_RIME" == "true" && "$INPUT_METHOD_INSTALL" != *"ibus-rime"* ]]; then
    echo "Error: CONFIG_IBUS_RIME is set to true, but INPUT_METHOD_INSTALL is not set to ibus-rime"
    exit 1
fi

# Keyboard layout composition definition.
export CONFIG_INPUT_METHOD="[('xkb', 'de')]"

#================================================================================
# System Tools Configuration
#================================================================================

# Enable modified software-properties-gtk integration.
export INSTALL_MODIFIED_SOFTWARE_PROPERTIES_GTK="true"

#================================================================================
# Time and Region Configuration
#================================================================================

# System timezone in IANA/zoneinfo format.
export TIMEZONE="Europe/Berlin"

# Default location for weather extension.
export CONFIG_WEATHER_LOCATION="[(uint32 0, 'Berlin, Germany', uint32 0, '52.5200,13.4050')]"

#================================================================================
# Live Environment Configuration
#================================================================================

# Package mirror for live boot system.
export LIVE_UBUNTU_MIRROR="http://de.archive.ubuntu.com/ubuntu/"

#================================================================================
# Desktop Applications
#================================================================================

# Pre-installed graphical applications.
export DEFAULT_APPS="
    gdebi \
    gnome-chess \
    gnome-clocks \
    gnome-weather \
    gnome-nettool \
    gnome-text-editor \
    seahorse \
    evince \
    shotwell \
    remmina remmina-plugin-rdp \
    rhythmbox rhythmbox-plugins \
    totem totem-plugins \
    transmission-gtk transmission-common \
    ffmpegthumbnailer \
    libgdk-pixbuf2.0-bin \
    usb-creator-gtk \
    baobab \
    file-roller \
    gnome-sushi \
    qalculate-gtk \
    yelp \
    gnome-shell-extension-prefs \
    gnome-user-docs \
    gnome-disk-utility \
    gnome-logs \
    gnome-system-monitor \
    gnome-sound-recorder \
    gnome-characters \
    gnome-bluetooth \
    gnome-power-manager \
    gnome-snapshot \
    gnome-font-viewer \
    gnome-browser-connector \
    gnome-control-center-faces \
    gnome-startup-applications \
    policykit-desktop-privileges
"

#================================================================================
# Command-Line Utilities
#================================================================================

# Pre-installed terminal tools.
export DEFAULT_CLI_TOOLS="
    curl \
    vim \
    nano \
    git \
    build-essential \
    make \
    gcc \
    g++ \
    dpkg-dev \
    net-tools \
    htop \
    httping \
    iputils-ping \
    iputils-tracepath \
    dnsutils \
    smartmontools \
    traceroute \
    whois \
    neofetch
    "

#================================================================================
# Flatpak Applications
#================================================================================

# Additional Flatpak applications.
export DEFAULT_FLATPAK_TOOLS=""

# Example Flatpak applications (commented out):
# export DEFAULT_FLATPAK_TOOLS="
#     chat.revolt.RevoltDesktop \
#     com.discordapp.Discord \
#     com.google.EarthPro \
#     com.jetbrains.Rider \
#     com.obsproject.Studio \
#     com.spotify.Client \
#     com.tencent.WeChat \
#     com.valvesoftware.Steam \
#     io.github.shiftey.Desktop \
#     net.agalwood.Motrix \
#     org.qbittorrent.qBittorrent \
#     org.signal.Signal \
#     org.gnome.Boxes \
#     org.kde.krita \
#     io.missioncenter.MissionCenter \
#     com.getpostman.Postman \
#     org.shotcut.Shotcut \
#     org.blender.Blender \
#     org.videolan.VLC \
#     com.wps.Office \
#     org.chromium.Chromium \
#     com.dosbox_x.DOSBox-X \
#     com.mojang.Minecraft \
#     org.codeblocks.codeblocks
#     "