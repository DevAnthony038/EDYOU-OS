set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Ensuring Ubuntu Pro advertisement is disabled"
FILE="/etc/apt/apt.conf.d/20apt-esm-hook.conf"
if [[ -e "$FILE" ]]; then
  print_ok "Removing existing Ubuntu Pro advertisement file: $FILE"
  rm -f "$FILE"
  judge "Remove Ubuntu Pro advertisement file"
else
  print_ok "Ubuntu Pro advertisement file does not exist, nothing to do"
fi
judge "Ensure Ubuntu Pro advertisement is disabled"

