set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# This script updates the /etc/issue and /etc/issue.net files for the target system.
# The /etc/issue file is displayed before the login prompt, and the /etc/issue.net file is displayed before the login prompt for remote logins. 
# Updating these files is necessary to ensure that the target system displays the correct information about the business name and build version when users log in.

print_ok "Updating /etc/issue"
cat << EOF > /etc/issue
$TARGET_BUSINESS_NAME $TARGET_BUILD_VERSION \n \l

EOF
judge "Update /etc/issue"

print_ok "Updating /etc/issue.net"
cat << EOF > /etc/issue.net
$TARGET_BUSINESS_NAME $TARGET_BUILD_VERSION
EOF
judge "Update /etc/issue.net"

