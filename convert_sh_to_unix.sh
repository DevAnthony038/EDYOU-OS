#!/bin/bash


# This script converts all .sh files in the current directory and its subdirectories to Unix line endings using dos2unix.
# It skips files in the build/new_building_os directory and logs the conversion status.
# this is very important because if the line endings are not correct, the scripts will not run properly.
# Usage: ./convert_sh_to_unix.sh


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/core/logging.sh"

if ! command -v dos2unix &> /dev/null; then
    print_info "dos2unix not found, installing..."
    sudo apt update && sudo apt install -y dos2unix
    judge "Install dos2unix"
fi

print_info "Converting all .sh files to Unix line endings..."
echo

while IFS= read -r -d '' file; do
    if file "$file" | grep -q "CRLF"; then
        dos2unix "$file" 2>/dev/null
        print_info "Converted: $file"
    else
        print_warn "Already Unix format: $file"
    fi
done < <(find . -type f -name "*.sh" -not -path "./build/new_building_os/*" -print0)

echo
print_ok "All .sh files processed"