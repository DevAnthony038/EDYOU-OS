#!/bin/bash

#=================================================
#    EDYOUOS Auto-Repair Tool (edyouos-autorepair.sh)
#=================================================
# This script automatically detects the current
# system version, downloads the corresponding
# repair ISO, mounts it, and executes the
# REPAIR.sh script found inside.
#
# Do NOT run this script as root. Run it as a normal
# user with sudo privileges.
#=================================================

set -e
set -o pipefail
set -u

# --- Global Variables ---
ISO_MNT_POINT="/mnt/edyouos_iso_repair"
DOWNLOAD_DIR="$HOME/Downloads/edyouos_repair_temp"
# FILE_PREFIX will be set after system detection (e.g., "EDYOUOS-1.4.1")
FILE_PREFIX=""
SHA256_FILE=""

# --- Color and Print Functions ---
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Font="\033[0m"
OK="${Green}[  OK  ]${Font}"
ERROR="${Red}[FAILED]${Font}"
WARNING="${Yellow}[ WARN ]${Font}"

function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}

function print_error() {
  echo -e "${ERROR} ${Red} $1 ${Font}"
}

function print_warn() {
  echo -e "${WARNING} ${Yellow} $1 ${Font}"
}

function judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 succeeded"
    sleep 0.2
  else
    print_error "$1 failed"
    # Cleanup will be triggered by the trap
    exit 1
  fi
}

# --- Cleanup Function ---
# This function is responsible for unmounting the ISO
# and deleting all temporary download files.
function clean_up() {
  print_ok "Cleaning up repair files..."
  sudo umount "$ISO_MNT_POINT" >/dev/null 2>&1 || true
  sudo rm -rf "$ISO_MNT_POINT" >/dev/null 2>&1 || true
  
  # Only remove files if FILE_PREFIX was set
  if [ -n "$FILE_PREFIX" ]; then
    print_ok "Removing ${DOWNLOAD_DIR}/${FILE_PREFIX}* ..."
    sudo rm -rf "$DOWNLOAD_DIR" >/dev/null 2>&1 || true
  fi
  print_ok "Cleanup succeeded"
}

# --- Trap ---
# Ensures clean_up is called on script exit (success or failure)
trap 'clean_up' EXIT

# --- Initial Run ---
# Clean up any leftover files from a previous failed run
clean_up

# --- Pre-flight Checks ---
print_ok "Ensure current user is not root..."
if [[ "$(id -u)" -eq 0 ]]; then
    print_error "This script must not be run as root. Please run as a normal user with sudo privileges."
    exit 1
fi
judge "User check"

print_ok "Installing required packages (aria2, curl, jq)..."
sudo apt install -y aria2 curl jq || (sudo apt update && sudo apt install -y aria2 curl jq)
judge "Install required packages"

# --- 1. System Detection ---
print_ok "Detecting current system version..."
if [ ! -f "/etc/lsb-release" ]; then
    print_error "System /etc/lsb-release file not found. Is this an installed EDYOUOS?"
    exit 1
fi

source /etc/lsb-release # Loads $DISTRIB_ID, $DISTRIB_RELEASE, $DISTRIB_CODENAME
SYS_PRODUCT=$DISTRIB_ID
SYS_VERSION=$DISTRIB_RELEASE   # e.g., 1.4.1
SYS_CODENAME=$DISTRIB_CODENAME # e.g., questing
SYS_ARCH=$(dpkg --print-architecture)

# Get base version (e.g., "1.4.1" -> "1.4")
SYS_BASE_VERSION=$(echo "$SYS_VERSION" | cut -d'.' -f1-2)
# Set global prefix for filenames and cleanup
FILE_PREFIX="EDYOUOS-$SYS_VERSION"

print_ok "System detected:  ${Blue}$SYS_PRODUCT $SYS_VERSION ($SYS_CODENAME) $SYS_ARCH${Font}"
print_ok "Download target:  ${Blue}Base $SYS_BASE_VERSION, Full $SYS_VERSION${Font}"
judge "System detection"

# --- 2. Download Logic ---
CURRENT_LANG=${LANG%%.*}
print_ok "Current system language detected: ${CURRENT_LANG}"
mkdir -p "$DOWNLOAD_DIR"

# Source of truth for direct ISO links (version -> language -> google drive link or "empty" if not available. peak concept i know ヾ(⌐■_■)ノ)
VERSION_TXT_URL="https://edyou-os.vercel.app/version.txt"
VERSION_TXT_FILE="${DOWNLOAD_DIR}/version.txt"

print_ok "Fetching version map from ${VERSION_TXT_URL}..."
if ! curl -sSL "$VERSION_TXT_URL" -o "$VERSION_TXT_FILE"; then
  print_error "Could not fetch version mapping from ${VERSION_TXT_URL}."
  exit 1
fi

get_link_for() {
  local version="$1"; local lang="$2"
  awk -v ver="$version" -v lang="$lang" '{
    col = index($0, ":"); if (col==0) next
    left = substr($0,1,col-1)
    right = substr($0,col+1)
    gsub(/^[ \t]+|[ \t]+$/, "", left)
    gsub(/^[ \t]+|[ \t]+$/, "", right)
    split(left, parts, /[ \t]+/)
    if (parts[1]==ver && parts[2]==lang) { print right; exit }
  }' "$VERSION_TXT_FILE" || true
}

GOOGLE_LINK=$(get_link_for "$SYS_VERSION" "$CURRENT_LANG")
if [ -z "$GOOGLE_LINK" ] || [ "$GOOGLE_LINK" = "empty" ]; then
  print_warn "No direct ISO link for ${SYS_VERSION} ${CURRENT_LANG}. Trying en_US fallback..."
  GOOGLE_LINK=$(get_link_for "$SYS_VERSION" "en_US")
fi

# If still empty, try base-version (e.g., 1.0) entries matching language
if [ -z "$GOOGLE_LINK" ] || [ "$GOOGLE_LINK" = "empty" ]; then
  print_warn "Exact full version not found; trying base-version (${SYS_BASE_VERSION}) fallback..."
  BEST_LINK=$(awk -v base="$SYS_BASE_VERSION" -v lang="$CURRENT_LANG" '{ col = index($0, ":"); if (col==0) next; left=substr($0,1,col-1); right=substr($0,col+1); gsub(/^[ \t]+|[ \t]+$/,"",left); gsub(/^[ \t]+|[ \t]+$/,"",right); split(left,parts,/[ \t]+/); ver=parts[1]; l=parts[2]; if((ver==base || index(ver, base ".")==1) && l==lang && right!="empty" && right!="") print ver " " right }' "$VERSION_TXT_FILE" | sort -V | tail -n1 | cut -d' ' -f2-)
  if [ -n "$BEST_LINK" ]; then
    GOOGLE_LINK="$BEST_LINK"
    print_ok "Using available ${SYS_BASE_VERSION} patch for ${CURRENT_LANG}: ${GOOGLE_LINK}"
  else
    # try en_US within base
    BEST_LINK=$(awk -v base="$SYS_BASE_VERSION" -v lang="en_US" '{ col = index($0, ":"); if (col==0) next; left=substr($0,1,col-1); right=substr($0,col+1); gsub(/^[ \t]+|[ \t]+$/,"",left); gsub(/^[ \t]+|[ \t]+$/,"",right); split(left,parts,/[ \t]+/); ver=parts[1]; l=parts[2]; if((ver==base || index(ver, base ".")==1) && l==lang && right!="empty" && right!="") print ver " " right }' "$VERSION_TXT_FILE" | sort -V | tail -n1 | cut -d' ' -f2-)
    if [ -n "$BEST_LINK" ]; then
      GOOGLE_LINK="$BEST_LINK"
      print_ok "Using available ${SYS_BASE_VERSION} patch for en_US: ${GOOGLE_LINK}"
    fi
  fi
fi

if [ -z "$GOOGLE_LINK" ] || [ "$GOOGLE_LINK" = "empty" ]; then
  print_error "Keine ISO-Download-URL gefunden für ${SYS_VERSION} (${CURRENT_LANG})."
  exit 1
fi

print_ok "Found ISO download link: ${GOOGLE_LINK}"

ISO_FILE_PATH="${DOWNLOAD_DIR}/${FILE_PREFIX}.iso"

# extract host and file id helpers
extract_drive_id() {
  local url="$1"
  id=$(echo "$url" | sed -n 's/.*[?&]id=\([^&]*\).*/\1/p')
  if [ -n "$id" ]; then echo "$id"; return; fi
  id=$(echo "$url" | sed -n 's#.*/d/\([^/?&]*\).*#\1#p')
  if [ -n "$id" ]; then echo "$id"; return; fi
  id=$(echo "$url" | sed -n 's#.*/uc\?id=\([^&]*\).*#\1#p')
  if [ -n "$id" ]; then echo "$id"; return; fi
  echo ""
}

url_host() { echo "$1" | awk -F/ '{print $3}' | sed 's/:.*//'; }

HOST=$(url_host "$GOOGLE_LINK" || echo "")
PREFER_GDOWN=0
if [[ "$HOST" == *drive.google.com* || "$HOST" == *docs.google.com* ]]; then
  PREFER_GDOWN=1
fi
# drive.usercontent is direct downloadable
if [[ "$HOST" == *drive.usercontent.google.com* ]]; then
  PREFER_GDOWN=0
fi

DL_OK=0
if [ $PREFER_GDOWN -eq 0 ]; then
  print_ok "Attempting direct download with curl/wget..."
  if command -v curl >/dev/null 2>&1; then
    if curl -L --fail "$GOOGLE_LINK" -o "$ISO_FILE_PATH"; then
      DL_OK=1
    fi
  fi
  if [ $DL_OK -eq 0 ] && command -v wget >/dev/null 2>&1; then
    if wget -O "$ISO_FILE_PATH" "$GOOGLE_LINK"; then
      DL_OK=1
    fi
  fi
  if [ $DL_OK -eq 1 ]; then
    # validate file type
    if command -v file >/dev/null 2>&1; then
      FTYPE=$(file -b --mime-type "$ISO_FILE_PATH" | tr '[:upper:]' '[:lower:]') || FTYPE=""
      if echo "$FTYPE" | grep -qE 'iso|x-iso|application/x-iso9660-image|application/octet-stream'; then
        print_ok "Downloaded ISO via direct HTTP(S): $ISO_FILE_PATH"
      else
        print_warn "Downloaded file type is '$FTYPE' — not an ISO. Falling back to gdown."
        DL_OK=0
      fi
    else
      # no 'file' available — check size
      SZ=$(stat -c%s "$ISO_FILE_PATH" || echo 0)
      if (( SZ < 1048576 )); then
        print_warn "Downloaded file is smaller than 1MB — likely not an ISO. Falling back to gdown."
        DL_OK=0
      else
        print_ok "Downloaded file size looks okay: $(numfmt --to=iec $SZ)"
      fi
    fi
  fi
fi

if [ $DL_OK -eq 0 ]; then
  print_warn "Using gdown in virtualenv to download Google Drive file..."
  if ! command -v python3 >/dev/null 2>&1; then
    print_error "python3 not found; cannot create virtualenv to run gdown"
    exit 1
  fi
  if ! python3 -m venv --help >/dev/null 2>&1; then
    print_ok "Installing python3-venv and python3-pip..."
    sudo apt update
    sudo apt install -y python3-venv python3-pip
  fi
  VENV_DIR="${DOWNLOAD_DIR}/gdown-venv"
  rm -rf "$VENV_DIR"
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/pip" install --upgrade pip
  "$VENV_DIR/bin/pip" install gdown

  FILE_ID=$(extract_drive_id "$GOOGLE_LINK")
  if [ -n "$FILE_ID" ]; then
    print_ok "Using Google Drive file id: $FILE_ID"
    if ! "$VENV_DIR/bin/gdown" "$FILE_ID" -O "$ISO_FILE_PATH"; then
      print_error "gdown failed to download file id $FILE_ID. Ensure the file is shared as 'Anyone with the link'."
      exit 1
    fi
  else
    if ! "$VENV_DIR/bin/gdown" "$GOOGLE_LINK" -O "$ISO_FILE_PATH"; then
      print_error "gdown failed to download from the provided link. Ensure the Google Drive file is shared publicly ('Anyone with the link')."
      exit 1
    fi
  fi
  # verify downloaded file
  if command -v file >/dev/null 2>&1; then
    FTYPE=$(file -b --mime-type "$ISO_FILE_PATH" | tr '[:upper:]' '[:lower:]') || FTYPE=""
    if ! echo "$FTYPE" | grep -qE 'iso|x-iso|application/x-iso9660-image|application/octet-stream'; then
      print_error "Downloaded file is not an ISO (detected: $FTYPE). Aborting."
      exit 1
    fi
  fi
  print_ok "Downloaded ISO via gdown: $ISO_FILE_PATH"
fi
judge "Download EDYOUOS ISO"



# --- 3. Integrity Check ---
ISO_FILE_PATH=$(ls "${DOWNLOAD_DIR}/${FILE_PREFIX}"*.iso | head -n 1)
print_ok "Ensure downloaded ISO file exists..."
if [[ -f "$ISO_FILE_PATH" ]]; then
    print_ok "Downloaded ISO file found: $ISO_FILE_PATH"
else
    print_error "Downloaded ISO file not found in $DOWNLOAD_DIR matching '${FILE_PREFIX}*.iso'"
    exit 1
fi

print_ok "Verifying download integrity..."
ACTUAL_SHA256=$(sha256sum "$ISO_FILE_PATH" | awk '{print $1}')

if [ -n "$SHA256_FILE" ] && [ -f "$SHA256_FILE" ]; then
  # The sha256 file might have different formats, let's find the hash value robustly
  EXPECTED_SHA256=$(grep -o '[a-fA-F0-9]\{64\}' "$SHA256_FILE" | head -n 1 || true)
  if [ -n "$EXPECTED_SHA256" ] && [[ "$ACTUAL_SHA256" == "$EXPECTED_SHA256" ]]; then
    print_ok "SHA256 checksum verification passed."
  else
    print_ok "Expected SHA256: $EXPECTED_SHA256"
    print_ok "Actual SHA256:   $ACTUAL_SHA256"
    print_error "SHA256 checksum verification failed. The downloaded file may be corrupted."
    exit 1
  fi
else
  print_warn "No checksum file available; skipping SHA256 verification."
fi
judge "ISO integrity check"

# --- 4. Mount ISO ---
print_ok "Mounting the ISO to $ISO_MNT_POINT..."
sudo mkdir -p "$ISO_MNT_POINT"
sudo mount -o loop,ro "$ISO_FILE_PATH" "$ISO_MNT_POINT"
judge "Mount ISO"

# --- 5. Execute REPAIR.sh ---
REPAIR_SCRIPT_PATH="$ISO_MNT_POINT/REPAIR.sh"
print_ok "Checking for REPAIR.sh in ISO..."
if [ ! -f "$REPAIR_SCRIPT_PATH" ]; then
    print_error "REPAIR.sh not found at $REPAIR_SCRIPT_PATH!"
    print_error "The downloaded ISO may be invalid or incomplete."
    exit 1
fi
judge "Found REPAIR.sh"

print_ok "Executing repair script from ISO. This may take a while..."
print_ok "Follow the prompts from the repair script."
echo -e "${Yellow}======================================================${Font}"

# Execute the script from the ISO (run from ISO root to preserve relative paths)
print_ok "Running REPAIR.sh from ISO root..."
if [ -f "$ISO_MNT_POINT/.disk/info" ]; then
  print_ok ".disk/info found in ISO root."
else
  print_warn ".disk/info not found in ISO root; listing top-level ISO contents for debugging:"
  ls -la "$ISO_MNT_POINT" || true
fi

# Run REPAIR.sh with working directory set to the mount point so relative paths resolve correctly
LOG_FILE="${DOWNLOAD_DIR}/repair_run.log"
print_ok "Running REPAIR.sh from ISO root (trace -> ${LOG_FILE})..."
if [ -f "$ISO_MNT_POINT/.disk/info" ]; then
  print_ok ".disk/info found in ISO root. Contents:" 
  cat "$ISO_MNT_POINT/.disk/info" || true
else
  print_warn ".disk/info not found in ISO root; listing top-level ISO contents for debugging:"
  ls -la "$ISO_MNT_POINT" || true
fi

# Run with shell tracing and save output to a log for post-mortem
if (cd "$ISO_MNT_POINT" && bash -x "./REPAIR.sh" 2>&1 | tee "$LOG_FILE"); then
  print_ok "REPAIR.sh script completed successfully. Trace saved to ${LOG_FILE}"
else
  print_error "REPAIR.sh script failed. See trace at ${LOG_FILE}. Showing first 200 lines:" 
  head -n 200 "$LOG_FILE" || true
  exit 1
fi

echo -e "${Yellow}======================================================${Font}"
judge "System repair script execution"

# --- 6. Cleanup ---
# The 'trap' at the top will automatically call clean_up() here.
print_ok "Auto-repair process finished."
print_ok "Please reboot your system as recommended by the repair script."