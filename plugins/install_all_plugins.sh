#!/bin/bash

set -e
set -o pipefail
set -u
source /root/plugins/logging.sh
source /root/plugins/config.sh

print_ok "Building variables for plugins:"

echo "TARGET_UBUNTU_VERSION=$TARGET_UBUNTU_VERSION"
echo "BUILD_UBUNTU_MIRROR=$BUILD_UBUNTU_MIRROR"
echo "TARGET_NAME=$TARGET_NAME"
echo "TARGET_BUSINESS_NAME=$TARGET_BUSINESS_NAME"
echo "TARGET_BUILD_VERSION=$TARGET_BUILD_VERSION"

for plugin in "$SCRIPT_DIR"/*; do
    if [[ -d "$plugin" && -f "$plugin/install.sh" ]]; then
        print_info "Processing plugin: $plugin"
        (
            cd "$plugin" && \
            chmod +x install.sh && \
            bash "$plugin/install.sh"
        )
    fi
done