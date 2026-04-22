#!/bin/bash

set -e
set -o pipefail
set -u

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$PROJECT_ROOT/core/logging.sh"
source "$PROJECT_ROOT/core/config.sh"

# Display EDYOU OS ASCII Logo in Green
echo -e "${Green}███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗     ██████╗ ███████╗${Font}"
echo -e "${Green}██╔════╝██╔══██╗╚██╗ ██╔╝██╔═══██╗██║   ██║    ██╔═══██╗██╔════╝${Font}"
echo -e "${Green}█████╗  ██║  ██║ ╚████╔╝ ██║   ██║██║   ██║    ██║   ██║███████╗${Font}"
echo -e "${Green}██╔══╝  ██║  ██║  ╚██╔╝  ██║   ██║██║   ██║    ██║   ██║╚════██║${Font}"
echo -e "${Green}███████╗██████╔╝   ██║   ╚██████╔╝╚██████╔╝    ╚██████╔╝███████║${Font}"
echo -e "${Green}╚══════╝╚═════╝    ╚═╝    ╚═════╝  ╚═════╝      ╚═════╝ ╚══════╝${Font}"
echo ""
print_ok "Starting EDYOUOS build process..."
print_ok "Target business name: $TARGET_BUSINESS_NAME"
print_ok "Target build version: $TARGET_BUILD_VERSION"
print_ok "Target Ubuntu version: $TARGET_UBUNTU_VERSION"
print_ok "Target Ubuntu mirror: $BUILD_UBUNTU_MIRROR"
echo ""

function bind_signal() {
    print_ok "Bind signal..."
    trap umount_on_exit EXIT
    judge "Bind signal"
}

function clean() {
    print_ok "Cleaning up..."
    sudo umount "$PROJECT_ROOT/build/new_building_os/sys" || sudo umount -lf "$PROJECT_ROOT/build/new_building_os/sys" || true
    sudo umount "$PROJECT_ROOT/build/new_building_os/proc" || sudo umount -lf "$PROJECT_ROOT/build/new_building_os/proc" || true
    sudo umount "$PROJECT_ROOT/build/new_building_os/dev" || sudo umount -lf "$PROJECT_ROOT/build/new_building_os/dev" || true
    sudo umount "$PROJECT_ROOT/build/new_building_os/run" || sudo umount -lf "$PROJECT_ROOT/build/new_building_os/run" || true
    sudo rm -rf "$PROJECT_ROOT/build/new_building_os" || true
    judge "Clean up rootfs"
    sudo rm -rf "$PROJECT_ROOT/build/image" || true
    judge "Clean up image"
    sudo rm -rf "$PROJECT_ROOT/build/tmp" || true
    judge "Clean up tmp"
    sudo rm -f "$PROJECT_ROOT/build/$TARGET_NAME.iso" || true
    judge "Clean up iso"
}

function setup_host() {
    print_ok "Setting up host environment..."
    sudo apt update
    sudo apt install -y \
        binutils debootstrap squashfs-tools xorriso grub-pc-bin \
        grub-efi-amd64 grub2-common mtools dosfstools \
        --no-install-recommends
    judge "Install required tools"

    print_ok "Creating new_building_os directory..."
    sudo mkdir -p "$PROJECT_ROOT/build/new_building_os"
    judge "Create new_building_os directory"

    print_ok "Setting up mods executable..."
    find "$PROJECT_ROOT/plugins" -type f -name "*.sh" -exec chmod +x {} \;
    judge "Set up mods executable"
}

function download_base_system() {
    print_ok "Calling debootstrap to download base debian system..."
    sudo debootstrap --arch=amd64 --variant=minbase --include=git "$TARGET_UBUNTU_VERSION" "$PROJECT_ROOT/build/new_building_os" "$BUILD_UBUNTU_MIRROR"
    judge "Download base system"
}

function mount_folders() {
    print_ok "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    judge "Reload systemd daemon"

    print_ok "Mounting /dev /run from host to new_building_os..."
    sudo mount --bind /dev "$PROJECT_ROOT/build/new_building_os/dev"
    sudo mount --bind /run "$PROJECT_ROOT/build/new_building_os/run"
    judge "Mount /dev /run"

    print_ok "Mounting /proc /sys /dev/pts within chroot..."
    sudo chroot "$PROJECT_ROOT/build/new_building_os" mount none -t proc /proc
    sudo chroot "$PROJECT_ROOT/build/new_building_os" mount none -t sysfs /sys
    sudo chroot "$PROJECT_ROOT/build/new_building_os" mount none -t devpts /dev/pts
    judge "Mount /proc /sys /dev/pts"

    print_ok "Copying plugins to new_building_os/root..."
    sudo cp -r "$PROJECT_ROOT/plugins" "$PROJECT_ROOT/build/new_building_os/root/plugins"
    sudo cp "$PROJECT_ROOT/core/config.sh" "$PROJECT_ROOT/build/new_building_os/root/plugins/config.sh"
    sudo cp "$PROJECT_ROOT/core/logging.sh" "$PROJECT_ROOT/build/new_building_os/root/plugins/logging.sh"
}

function run_chroot() {
    print_ok "Running install_all_plugins.sh in new_building_os..."
    print_warn "============================================"
    print_warn "   The following will run in chroot ENV!"
    print_warn "============================================"
    sudo chroot "$PROJECT_ROOT/build/new_building_os" /usr/bin/env DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-readline} /root/plugins/install_all_plugins.sh -
    print_warn "============================================"
    print_warn "   chroot ENV execution completed!"
    print_warn "============================================"
    judge "Run install_all_plugins.sh in new_building_os"

    print_ok "Sleeping for 5 seconds to allow chroot to exit cleanly..."
    sleep 5
}

function umount_folders() {
    print_ok "Cleaning plugins from new_building_os/root..."
    sudo rm -rf "$PROJECT_ROOT/build/new_building_os/root/plugins"
    judge "Clean up new_building_os /root/plugins"

    print_ok "Unmounting /proc /sys /dev/pts within chroot..."
    sudo chroot "$PROJECT_ROOT/build/new_building_os" umount /dev/pts || sudo chroot "$PROJECT_ROOT/build/new_building_os" umount -lf /dev/pts
    sudo chroot "$PROJECT_ROOT/build/new_building_os" umount /sys || sudo chroot "$PROJECT_ROOT/build/new_building_os" umount -lf /sys
    sudo chroot "$PROJECT_ROOT/build/new_building_os" umount /proc || sudo chroot "$PROJECT_ROOT/build/new_building_os" umount -lf /proc
    judge "Unmount /proc /sys /dev/pts"

    print_ok "Unmounting /dev /run outside of chroot..."
    sudo umount "$PROJECT_ROOT/build/new_building_os/dev" || sudo umount -lf "$PROJECT_ROOT/build/new_building_os/dev"
    sudo umount "$PROJECT_ROOT/build/new_building_os/run" || sudo umount -lf "$PROJECT_ROOT/build/new_building_os/run"
    judge "Unmount /dev /run /proc /sys"
}

function build_iso() {
    print_ok "Building ISO image..."

    print_ok "Creating image directory..."
    sudo rm -rf "$PROJECT_ROOT/build/image"
    mkdir -p "$PROJECT_ROOT/build/image/casper" "$PROJECT_ROOT/build/image/isolinux" "$PROJECT_ROOT/build/image/.disk"
    judge "Create image directory"

    print_ok "Copying kernel files as /casper/vmlinuz and /casper/initrd..."
    sudo cp "$PROJECT_ROOT/build/new_building_os/boot/vmlinuz-"*"-generic" "$PROJECT_ROOT/build/image/casper/vmlinuz"
    sudo cp "$PROJECT_ROOT/build/new_building_os/boot/initrd.img-"*"-generic" "$PROJECT_ROOT/build/image/casper/initrd"
    judge "Copy kernel files"

    print_ok "Copying repair.sh to /REPAIR.sh in the image..."
    sudo cp "$PROJECT_ROOT/plugins/39-dconf-patch/dconf.ini" "$PROJECT_ROOT/build/image/casper/default-dconf.ini"
    sudo cp "$PROJECT_ROOT/build/repair.sh" "$PROJECT_ROOT/build/image/REPAIR.sh"
    judge "Copy repair.sh to image"
    
    print_ok "Generating grub.cfg..."
    touch "$PROJECT_ROOT/build/image/$TARGET_NAME"
    cp "$PROJECT_ROOT/core/config.sh" "$PROJECT_ROOT/build/image/$TARGET_NAME"
    judge "Copy build args to disk"

    TRY_TEXT="Try and Install $TARGET_BUSINESS_NAME"
    cat << EOF > "$PROJECT_ROOT/build/image/isolinux/grub.cfg"

search --set=root --file /$TARGET_NAME

insmod all_video

set default="0"
set timeout=10

menuentry "$TRY_TEXT" {
   set gfxpayload=keep
   linux   /casper/vmlinuz boot=casper nopersistent quiet splash ---
   initrd  /casper/initrd
}

menuentry "$TRY_TEXT (Safe Graphics)" {
    set gfxpayload=keep
    linux   /casper/vmlinuz boot=casper nopersistent nomodeset ---
    initrd  /casper/initrd
}

if [ "\$grub_platform" == "efi" ]; then
    menuentry "Boot from next volume" {
        exit 1
    }

    menuentry "UEFI Firmware Settings" {
        fwsetup
    }
fi
EOF
    judge "Generate grub.cfg"

    print_ok "Generating manifes for filesystem..."
    sudo chroot "$PROJECT_ROOT/build/new_building_os" dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee "$PROJECT_ROOT/build/image/casper/filesystem.manifest" >/dev/null 2>&1
    judge "Generate manifest for filesystem"

    print_ok "Generating manifest for filesystem-desktop..."
    sudo cp -v "$PROJECT_ROOT/build/image/casper/filesystem.manifest" "$PROJECT_ROOT/build/image/casper/filesystem.manifest-desktop"
    for pkg in $TARGET_PACKAGE_REMOVE; do
        sudo sed -i "/$pkg/d" "$PROJECT_ROOT/build/image/casper/filesystem.manifest-desktop"
    done
    judge "Generate manifest for filesystem-desktop"

    print_ok "Compressing rootfs as squashfs on /casper/filesystem.squashfs..."
    sudo mksquashfs "$PROJECT_ROOT/build/new_building_os" "$PROJECT_ROOT/build/image/casper/filesystem.squashfs" \
        -noappend -no-duplicates -no-recovery \
        -wildcards -b 1M \
        -comp zstd -Xcompression-level 19 \
        -e "var/cache/apt/archives/*" \
        -e "root/*" \
        -e "root/.*" \
        -e "tmp/*" \
        -e "tmp/.*" \
        -e "swapfile"
    judge "Compress rootfs"

    print_ok "Verifying the integrity of filesystem.squashfs..."
    if sudo unsquashfs -s "$PROJECT_ROOT/build/image/casper/filesystem.squashfs"; then
        print_ok "Verification successful. The file appears to be valid."
    else
        print_err "Verification FAILED! The squashfs file is likely corrupt."
        exit 1
    fi
    
    print_ok "Generating filesystem.size on /casper/filesystem.size..."
    printf $(sudo du -sx --block-size=1 "$PROJECT_ROOT/build/new_building_os" | cut -f1) > "$PROJECT_ROOT/build/image/casper/filesystem.size"
    judge "Generate filesystem.size"

    print_ok "Generating README.diskdefines..."
    cat << EOF > "$PROJECT_ROOT/build/image/README.diskdefines"
#define DISKNAME  Try $TARGET_BUSINESS_NAME
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF
    judge "Generate README.diskdefines"

    DATE=`TZ="UTC" date +"%y%m%d%H%M"`
    cat << EOF > "$PROJECT_ROOT/build/image/README.md"
# $TARGET_BUSINESS_NAME $TARGET_BUILD_VERSION

$TARGET_BUSINESS_NAME is a custom Ubuntu-based Linux distribution that offers a familiar and easy-to-use experience for anyone moving to Linux.

This image is built with the following configurations:

- **Language**: $LANG_MODE
- **Version**: $TARGET_BUILD_VERSION
- **Date**: $DATE

$TARGET_BUSINESS_NAME is distributed with GPLv3 license. You can find the license on [GPL-v3](https://github.com/DevAnthony038/EDYOU-OS/blob/main/LICENSE).

## Please verify the checksum!!!

To verify the integrity of the image, you can calculate the md5sum of the image and compare it with the value in the file \`md5sum.txt\`.

To do this, run the following command in the terminal:

\`\`\`bash
md5sum -c md5sum.txt | grep -v 'OK'
\`\`\`

No output indicates that the image is correct.

## How to use

Press F12 to enter the boot menu when you start your computer. Select the USB drive to boot from.

## More information

For detailed instructions, please visit [$TARGET_BUSINESS_NAME Document](https://github.com/DevAnthony038/EDYOU-OS?tab=readme-ov-file#system-requirements).
EOF

    pushd "$PROJECT_ROOT/build/image"
    print_ok "Creating EFI boot image on /isolinux/efiboot.img..."
    (
        cd isolinux && \
        dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
        sudo mkfs.vfat efiboot.img && \
        mkdir efi && \
        sudo mount efiboot.img efi && \
        sudo grub-install --target=x86_64-efi --efi-directory=efi --uefi-secure-boot --removable --no-nvram && \
        sudo umount efi && \
        rm -rf efi
    )
    judge "Create EFI boot image"

    print_ok "Creating BIOS boot image on /isolinux/bios.img..."
    grub-mkstandalone \
        --format=i386-pc \
        --output=isolinux/core.img \
        --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
        --modules="linux16 linux normal iso9660 biosdisk search" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=isolinux/grub.cfg"
    judge "Create BIOS boot image"

    print_ok "Creating hybrid boot image on /isolinux/bios.img..."
    cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img
    judge "Create hybrid boot image"

    print_ok "Creating .disk/info..."
    echo "$TARGET_BUSINESS_NAME $TARGET_BUILD_VERSION $TARGET_UBUNTU_VERSION - Release amd64 ($(date +%Y%m%d))" | sudo tee .disk/info
    judge "Create .disk/info"

    print_ok "Creating md5sum.txt..."
    sudo /bin/bash -c "(find . -type f -print0 | xargs -0 md5sum | grep -v -e 'md5sum.txt' -e 'bios.img' -e 'efiboot.img' > md5sum.txt)"
    judge "Create md5sum.txt"

    print_ok "Creating dist directory..."
    sudo mkdir -p "$PROJECT_ROOT/build/dist"
    judge "Create dist directory"

    print_ok "Creating iso image..."
    export TMPDIR="$PROJECT_ROOT/build/tmp"
    mkdir -p "$TMPDIR"
    sudo xorriso \
        -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "$TARGET_NAME" \
        -eltorito-boot boot/grub/bios.img \
            -no-emul-boot \
            -boot-load-size 4 \
            -boot-info-table \
            --eltorito-catalog boot/grub/boot.cat \
            --grub2-boot-info \
            --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        -eltorito-alt-boot \
            -e EFI/efiboot.img \
            -no-emul-boot \
            -append_partition 2 0xef isolinux/efiboot.img \
        -output "$PROJECT_ROOT/build/dist/$TARGET_BUSINESS_NAME-$TARGET_BUILD_VERSION-$LANG_MODE-$DATE.iso" \
        -m "isolinux/efiboot.img" \
        -m "isolinux/bios.img" \
        -graft-points \
            "/EFI/efiboot.img=isolinux/efiboot.img" \
            "/boot/grub/grub.cfg=isolinux/grub.cfg" \
            "/boot/grub/bios.img=isolinux/bios.img" \
            "."

    judge "Create iso image"

    print_ok "Generating sha256 checksum..."
    SHA256_FILE="$PROJECT_ROOT/build/dist/$TARGET_BUSINESS_NAME-$TARGET_BUILD_VERSION-$LANG_MODE-$DATE.sha256"
    HASH=`sudo sha256sum "$PROJECT_ROOT/build/dist/$TARGET_BUSINESS_NAME-$TARGET_BUILD_VERSION-$LANG_MODE-$DATE.iso" | cut -d ' ' -f 1`
    sudo bash -c "echo 'SHA256: $HASH' > '$SHA256_FILE'" 2>/dev/null || true
    sudo chmod 666 "$SHA256_FILE" 2>/dev/null || true
    judge "Generate sha256 checksum"

    popd
}

function umount_on_exit() {
    sleep 2
    print_ok "Umount before exit..."
    sudo umount "$PROJECT_ROOT/build/new_building_os/sys" || sudo umount -lf "$PROJECT_ROOT/build/new_building_os/sys" || true
    sudo umount "$PROJECT_ROOT/build/new_building_os/proc" || sudo umount -lf "$PROJECT_ROOT/build/new_building_os/proc" || true
    sudo umount "$PROJECT_ROOT/build/new_building_os/dev" || sudo umount -lf "$PROJECT_ROOT/build/new_building_os/dev" || true
    sudo umount "$PROJECT_ROOT/build/new_building_os/run" || sudo umount -lf "$PROJECT_ROOT/build/new_building_os/run" || true
    judge "Umount before exit"
}

cd "$PROJECT_ROOT/build"
bind_signal
clean
setup_host
download_base_system
mount_folders
run_chroot
umount_folders
build_iso
echo "Build completed: $TARGET_NAME.iso"