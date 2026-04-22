#!/bin/bash
# ============================================================================
# 65-gdm-custom-theme-mod - GNOME Shell 46+ GDM Custom Theme
# ============================================================================
# This plugin extracts the existing GDM gresource, applies custom CSS
# modifications, recompiles, and installs the new theme binary.
# ============================================================================

set -e
set -o pipefail
set -u

# Import EDYOUOS helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../core/logging.sh"
source "${SCRIPT_DIR}/../../core/config.sh"

print_ok "Starting GDM custom theme application"

# ============================================================================
# CONFIGURATION
# ============================================================================

GNOME_SHELL_PATH="/usr/share/gnome-shell"
THEME_DIR="${GNOME_SHELL_PATH}/theme"
WORK_DIR="/tmp/gdm-theme-build-$$"
BACKUP_DIR="${THEME_DIR}.backup-$(date +%s)"
RESOURCE_NAME="gnome-shell-theme.gresource"
GRESOURCE_PREFIX="/org/gnome/shell/theme"
ASSETS_DIR="${SCRIPT_DIR}/assets"
ASSETS_PIXMAPS="${ASSETS_DIR}/pixmaps"
ASSETS_BACKGROUNDS="${ASSETS_DIR}/backgrounds"
ASSETS_DCONF="${ASSETS_DIR}/dconf"

# Determine which gresource file to use (Ubuntu vs generic GNOME)
if [ -f "${THEME_DIR}/gdm-theme.gresource" ]; then
    SOURCE_GRESOURCE="${THEME_DIR}/gdm-theme.gresource"
    print_ok "Detected Ubuntu gdm-theme.gresource"
elif [ -f "${THEME_DIR}/gnome-shell-theme.gresource" ]; then
    SOURCE_GRESOURCE="${THEME_DIR}/gnome-shell-theme.gresource"
    print_ok "Detected generic gnome-shell-theme.gresource"
else
    print_error "No gresource file found in ${THEME_DIR}"
    exit 1
fi

# ============================================================================
# STEP 1: BACKUP EXISTING GRESOURCE
# ============================================================================

print_ok "Backing up existing gresource"
mkdir -p "${BACKUP_DIR}"
cp "${SOURCE_GRESOURCE}" "${BACKUP_DIR}/${RESOURCE_NAME}.original"
print_ok "Backed up to: ${BACKUP_DIR}/${RESOURCE_NAME}.original"
judge "Backup gresource"

# ============================================================================
# STEP 2: PREPARE WORKING DIRECTORY
# ============================================================================

print_ok "Preparing build workspace"
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

# Create subdirectories for organization
mkdir -p extract
mkdir -p build
mkdir -p resources

print_ok "Build workspace: ${WORK_DIR}"
judge "Setup workspace"

# ============================================================================
# STEP 3: EXTRACT EXISTING GRESOURCE
# ============================================================================

print_ok "Extracting existing gresource"

# Use gresource to dump the XML structure
if ! gresource dump "${SOURCE_GRESOURCE}" > extract/structure.xml 2>/dev/null; then
    print_error "Failed to extract gresource structure"
    exit 1
fi

judge "Extract gresource structure"

# Verify extraction
if ! grep -q "org/gnome/shell/theme" extract/structure.xml; then
    print_error "Could not find expected resource paths in gresource"
    exit 1
fi

print_ok "Confirmed valid gresource structure"

# ============================================================================
# STEP 4: EXTRACT EXISTING CSS FILES
# ============================================================================

print_ok "Extracting existing CSS files"

# Extract gdm.css if it exists
if gresource dump "${SOURCE_GRESOURCE}" "/org/gnome/shell/theme/gdm.css" > extract/gdm.css.original 2>/dev/null; then
    print_ok "Extracted original gdm.css"
else
    print_warn "No gdm.css in original gresource, will create new"
    touch extract/gdm.css.original
fi

# Extract gnome-shell.css if it exists
if gresource dump "${SOURCE_GRESOURCE}" "/org/gnome/shell/theme/gnome-shell.css" > extract/gnome-shell.css.original 2>/dev/null; then
    print_ok "Extracted original gnome-shell.css"
else
    print_warn "No gnome-shell.css in original gresource"
    touch extract/gnome-shell.css.original
fi

judge "Extract CSS files"

# ============================================================================
# STEP 5: CREATE CUSTOM CSS OVERRIDE
# ============================================================================

print_ok "Creating custom GDM CSS overrides"

# Build our custom CSS in the build directory
cat > build/gdm.css << 'GDMCSS_EOF'
/* ============================================================================
   Production GDM Custom Theme - GNOME Shell 46+ for EDYOUOS
   ============================================================================ */

/* ============================================================================
   GLOBAL COLOR VARIABLES AND ACCENT OVERRIDES
   ============================================================================ */

:root {
  --accent-color: #3584e4;
  --accent-color-rgb: rgb(53, 132, 228);
  accent-color: #3584e4;
  -st-accent-color: #3584e4;
  -st-accent-bg-color: #3584e4;
  --bg-color: #1a1a1a;
  --fg-color: #ffffff;
  --border-color: #333333;
  --disabled-color: #666666;
  --border-width: 1px;
  --radius: 6px;
}

/* ============================================================================
   STAGE AND ROOT CONTAINERS
   ============================================================================ */

stage {
  background-color: #1a1a1a;
  background: url(file:///usr/share/backgrounds/login-bg.png) center/cover no-repeat;
  font-family: "Cantarell", sans-serif;
  font-size: 12pt;
  color: #ffffff;
}

/* ============================================================================
   LOGIN BACKGROUND AND DIALOGS
   ============================================================================ */

#lockDialogGroup {
  background: url(file:///usr/share/backgrounds/login-bg.png) center/cover no-repeat;
  background-color: #1a1a1a;
}

#screenShieldGroup {
  background: url(file:///usr/share/backgrounds/login-bg.png) center/cover no-repeat;
  background-color: #1a1a1a;
}

#screenShieldContents {
  background-color: rgba(26, 26, 26, 0.95);
}

#loginDialog {
  background-color: rgba(26, 26, 26, 0.98);
  border-radius: 12px;
  border: 1px solid #444444;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.8);
}

/* ============================================================================
   LOGIN DIALOG INTERNALS
   ============================================================================ */

.login-dialog-button-box {
  spacing: 12px;
}

.login-dialog {
  background-color: transparent;
}

.login-dialog-user-list {
  width: 400px;
  spacing: 12px;
}

.login-dialog-user-list-item {
  background-color: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  padding: 12px;
  border: 1px solid transparent;
  transition-duration: 200ms;
}

.login-dialog-user-list-item:hover {
  background-color: rgba(255, 255, 255, 0.10);
  border: 1px solid rgba(53, 132, 228, 0.5);
}

.login-dialog-user-list-item:active,
.login-dialog-user-list-item:selected {
  background-color: rgba(53, 132, 228, 0.2);
  border: 1px solid #3584e4;
}

.login-dialog-user-list-item .user-widget-label {
  color: #ffffff;
  font-size: 14pt;
  font-weight: 600;
}

.login-dialog-user-list-item .user-widget-label:disabled {
  color: #999999;
}

/* ============================================================================
   BUTTONS AND CONTROLS
   ============================================================================ */

StButton,
.button,
button {
  background-color: #3584e4;
  color: #ffffff;
  border-radius: 6px;
  padding: 8px 16px;
  border: 1px solid #2975d4;
  transition-duration: 200ms;
  font-weight: 600;
  text-align: center;
  min-height: 36px;
  min-width: 80px;
}

StButton:hover,
.button:hover,
button:hover {
  background-color: #4492f7;
  border-color: #3876db;
}

StButton:active,
.button:active,
button:active,
StButton:focus,
.button:focus,
button:focus {
  background-color: #246ee5;
  border-color: #1560d0;
}

StButton:disabled,
.button:disabled,
button:disabled {
  background-color: #666666;
  color: #999999;
  border-color: #555555;
}

.login-dialog-button {
  background-color: #3584e4;
  color: #ffffff;
  border-radius: 6px;
  padding: 10px 24px;
  border: none;
  font-weight: 700;
  font-size: 12pt;
  min-height: 40px;
}

.login-dialog-button:hover {
  background-color: #4492f7;
}

.login-dialog-button:focus {
  background-color: #246ee5;
  outline: 2px solid rgba(53, 132, 228, 0.5);
  outline-offset: 2px;
}

.cancel-button,
.secondary-button {
  background-color: #444444;
  color: #ffffff;
  border: 1px solid #555555;
}

.cancel-button:hover,
.secondary-button:hover {
  background-color: #555555;
}

/* ============================================================================
   TEXT ENTRIES AND INPUT FIELDS
   ============================================================================ */

StEntry,
.entry,
input {
  background-color: rgba(255, 255, 255, 0.1);
  color: #ffffff;
  caret-color: #3584e4;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  padding: 8px 12px;
  transition-duration: 200ms;
}

StEntry:focus,
.entry:focus,
input:focus {
  background-color: rgba(255, 255, 255, 0.15);
  border: 1px solid #3584e4;
  box-shadow: 0 0 0 2px rgba(53, 132, 228, 0.3);
}

StEntry:hover,
.entry:hover,
input:hover {
  background-color: rgba(255, 255, 255, 0.12);
  border: 1px solid rgba(255, 255, 255, 0.3);
}

StEntry:disabled,
.entry:disabled,
input:disabled {
  background-color: rgba(0, 0, 0, 0.2);
  color: #999999;
  border: 1px solid #555555;
}

/* ============================================================================
   TOGGLES AND SWITCHES
   ============================================================================ */

StToggle,
.toggle-switch {
  background-color: #444444;
  border-radius: 12px;
  width: 52px;
  height: 28px;
  border: 1px solid #555555;
  transition-duration: 200ms;
}

StToggle:checked,
.toggle-switch:checked {
  background-color: #3584e4;
  border-color: #2975d4;
}

StToggle:hover,
.toggle-switch:hover {
  background-color: #555555;
}

StToggle:checked:hover,
.toggle-switch:checked:hover {
  background-color: #4492f7;
}

/* ============================================================================
   SLIDERS AND PROGRESS BARS
   ============================================================================ */

StSlider,
.slider {
  -st-slider-handle-radius: 8px;
  -st-slider-height: 6px;
  height: 28px;
}

.slider {
  background-color: rgba(255, 255, 255, 0.1);
  border-radius: 3px;
}

.slider-handle {
  width: 16px;
  height: 16px;
  border-radius: 8px;
  background-color: #3584e4;
  border: 2px solid rgba(255, 255, 255, 0.2);
  transition-duration: 100ms;
}

.slider-handle:hover {
  background-color: #4492f7;
}

.slider-handle:active {
  background-color: #246ee5;
}

.progress-bar {
  background-color: #666666;
  border-radius: 3px;
  height: 6px;
}

.progress-bar-filled {
  background-color: #3584e4;
  border-radius: 3px;
  height: 6px;
  transition-duration: 200ms;
}

/* ============================================================================
   TEXT AND TYPOGRAPHY
   ============================================================================ */

.login-dialog-prompt {
  color: #ffffff;
  font-size: 12pt;
  font-weight: 500;
}

.login-dialog-banner {
  color: #ffffff;
  font-size: 18pt;
  font-weight: 700;
  text-align: center;
  margin-bottom: 24px;
}

.label {
  color: #ffffff;
  font-size: 11pt;
}

.dim-label {
  color: #999999;
  font-size: 10pt;
}

/* ============================================================================
   SELECTION AND FOCUS STATES
   ============================================================================ */

:selected,
.selected,
:focus {
  background-color: rgba(53, 132, 228, 0.25);
  color: #ffffff;
  outline: none;
}

*:focus {
  outline: 2px solid rgba(53, 132, 228, 0.5);
  outline-offset: 1px;
}

/* ============================================================================
   MODAL DIALOGS AND OVERLAYS
   ============================================================================ */

.modal-dialog {
  background-color: rgba(26, 26, 26, 0.98);
  border: 1px solid #444444;
  border-radius: 12px;
  box-shadow: 0 12px 48px rgba(0, 0, 0, 0.9);
  padding: 24px;
}

.modal-dialog-button-box {
  spacing: 12px;
  margin-top: 24px;
}

/* ============================================================================
   TOP PANEL AND CLOCK
   ============================================================================ */

#panel {
  background-color: rgba(26, 26, 26, 0.95);
  font-size: 12pt;
  font-weight: 500;
  color: #ffffff;
  border-bottom: 1px solid #333333;
}

#panelLeft,
#panelCenter,
#panelRight {
  spacing: 6px;
}

.panel-button {
  background-color: transparent;
  color: #ffffff;
  padding: 8px 12px;
  border-radius: 0;
  border: none;
  transition-duration: 200ms;
}

.panel-button:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.panel-button:active,
.panel-button:focus {
  background-color: rgba(53, 132, 228, 0.25);
}

#clock {
  color: #ffffff;
  font-size: 14pt;
  font-weight: 600;
  text-align: center;
}

/* ============================================================================
   NOTIFICATIONS AND MENUS
   ============================================================================ */

.notification {
  background-color: rgba(44, 44, 44, 0.95);
  border: 1px solid #555555;
  border-radius: 8px;
  color: #ffffff;
  padding: 12px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.6);
}

.notification-button {
  background-color: #3584e4;
  color: #ffffff;
  border-radius: 4px;
  padding: 6px 12px;
  font-size: 10pt;
  margin-top: 8px;
}

.notification-button:hover {
  background-color: #4492f7;
}

.popup-menu {
  background-color: rgba(44, 44, 44, 0.98);
  border: 1px solid #555555;
  border-radius: 8px;
  color: #ffffff;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.6);
}

.popup-menu-item {
  padding: 12px;
  color: #ffffff;
  transition-duration: 200ms;
}

.popup-menu-item:hover {
  background-color: rgba(53, 132, 228, 0.25);
  color: #ffffff;
}

.popup-menu-item:active {
  background-color: rgba(53, 132, 228, 0.4);
}

/* ============================================================================
   SCROLLBARS
   ============================================================================ */

.scrollbar {
  min-width: 8px;
  min-height: 8px;
  background-color: rgba(255, 255, 255, 0.1);
  border-radius: 4px;
}

.scrollbar:hover {
  background-color: rgba(255, 255, 255, 0.15);
}

/* ============================================================================
   CUSTOM ACCENT COLOR APPLICATION
   ============================================================================ */

*:selected {
  -st-accent-color: #3584e4;
  -st-accent-bg-color: rgba(53, 132, 228, 0.25);
}

.highlighted {
  -st-accent-color: #3584e4;
}

/* ============================================================================
   GDM-SPECIFIC OVERRIDES
   ============================================================================ */

#lockScreenContents {
  background-color: transparent;
}

#lockScreenIndicator {
  color: #ffffff;
  font-size: 11pt;
  spacing: 6px;
}

.login-dialog-user-widget {
  color: #ffffff;
}

.login-dialog .user-list {
  width: 400px;
}

.gnome-shell-theme-override {
  accent-color: #3584e4 !important;
  background-color: #1a1a1a !important;
  color: #ffffff !important;
}

/* ============================================================================
   UNIVERSAL ACCENT COLOR ENFORCEMENT
   ============================================================================ */

* {
  accent-color: #3584e4 !important;
}
GDMCSS_EOF

judge "Create custom CSS"

# Also create gnome-shell.css as a copy (required by gresource manifest)
cp build/gdm.css build/gnome-shell.css
print_ok "Created gnome-shell.css override"

# Install GDM branding assets from plugin assets directory
print_ok "Installing GDM branding assets from plugin"
if [ -d "${ASSETS_DIR}" ]; then
  if [ -f "${ASSETS_PIXMAPS}/edyouos-smaller.png" ]; then
    sudo install -m 644 "${ASSETS_PIXMAPS}/edyouos-smaller.png" /usr/share/pixmaps/edyouos-smaller.png || true
  fi
  if [ -f "${ASSETS_BACKGROUNDS}/login-bg.png" ]; then
    sudo install -m 644 "${ASSETS_BACKGROUNDS}/login-bg.png" /usr/share/backgrounds/login-bg.png || true
  fi
  if [ -f "${ASSETS_DCONF}/greeter.dconf-defaults.ini" ]; then
    sudo install -m 644 "${ASSETS_DCONF}/greeter.dconf-defaults.ini" /etc/gdm3/greeter.dconf-defaults || true
  fi
  if [ -f "${ASSETS_DCONF}/dconf.ini" ]; then
    sudo install -m 644 "${ASSETS_DCONF}/dconf.ini" "${WORK_DIR}/dconf.ini" || true
  fi
  print_ok "GDM branding assets installed from ${ASSETS_DIR}"
else
  print_warn "No assets directory found at ${ASSETS_DIR}; skipping asset install"
fi

# Inline migrated dconf installer (previously in plugins/39-dconf-patch)
print_ok "Running migrated dconf installer (inline)"

# Export DBus session for dconf operations
print_ok "Exporting dbus session for dconf operations"
export $(dbus-launch) || true
judge "Export dbus session"

print_ok "Loading dconf settings for org.gnome (from assets)"
if [ -f "${ASSETS_DCONF}/dconf.ini" ]; then
  sudo dconf load /org/gnome/ < "${ASSETS_DCONF}/dconf.ini" || true
  judge "Load dconf settings for org.gnome"
else
  print_warn "No dconf.ini in ${ASSETS_DCONF}; skipping"
fi

# Apply explicit dconf values (use sudo where needed)
sudo dconf write /org/gtk/settings/file-chooser/sort-directories-first true || true
sudo dconf write /org/gnome/desktop/input-sources/xkb-options "@as []" || true
sudo dconf write /org/gnome/desktop/input-sources/mru-sources "@a(ss) [('xkb','us')]" || true
sudo dconf write /org/gnome/desktop/sound/theme-name "'modern-minimal-ui-sounds'" || true
judge "Load dconf settings"

print_ok "Enforcing Modern Minimal UI Sounds as default"
if [ -d "/usr/share/sounds/modern-minimal-ui-sounds" ]; then
  sudo mkdir -p /etc/dconf/db/local.d
  sudo tee /etc/dconf/db/local.d/00-edyouos-sound-theme > /dev/null <<'EOF'
[org/gnome/desktop/sound]
theme-name='modern-minimal-ui-sounds'
EOF

  sudo mkdir -p /etc/dconf/db/local.d/locks
  echo "/org/gnome/desktop/sound/theme-name" | sudo tee /etc/dconf/db/local.d/locks/00-edyouos-sound-theme > /dev/null
  sudo dconf update || true
  judge "Enforce default sound theme"
else
  print_warn "Sound theme modern-minimal-ui-sounds is not installed; skipping enforce step"
fi

print_ok "Configuring input sources (from CONFIG_INPUT_METHOD if set)"
if [ -z "${CONFIG_INPUT_METHOD:-}" ]; then
  print_warn "CONFIG_INPUT_METHOD not set; skipping input source configuration"
else
  sudo dconf write /org/gnome/desktop/input-sources/sources "$CONFIG_INPUT_METHOD" || true
  judge "Configure input sources"
fi

print_ok "Configuring weather location (from CONFIG_WEATHER_LOCATION if set)"
if [ -z "${CONFIG_WEATHER_LOCATION:-}" ]; then
  print_warn "CONFIG_WEATHER_LOCATION not set; skipping weather configuration"
else
  sudo dconf write /org/gnome/shell/extensions/openweatherrefined/locs "$CONFIG_WEATHER_LOCATION" || true
  judge "Configure weather location"
fi

print_ok "Copying root's dconf settings to /etc/skel"
sudo mkdir -p /etc/skel/.config/dconf
if [ -f /root/.config/dconf/user ]; then
  sudo cp /root/.config/dconf/user /etc/skel/.config/dconf/user || true
  judge "Copy root's dconf settings to /etc/skel"
else
  print_warn "/root/.config/dconf/user not found; skipping skel copy"
fi

print_ok "dconf installation (inline) complete"
judge "dconf migrated inline"

# ============================================================================
# STEP 6: CREATE GRESOURCE MANIFEST
# ============================================================================

print_ok "Creating gresource manifest"

cat > build/gresource.xml << 'GRESOURCE_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/org/gnome/shell/theme">
    <!-- Custom EDYOUOS GDM theme CSS -->
    <file>gdm.css</file>
    <file>gnome-shell.css</file>
  </gresource>
</gresources>
GRESOURCE_EOF

judge "Create gresource manifest"

# ============================================================================
# STEP 7: COMPILE GRESOURCE
# ============================================================================

print_ok "Compiling gresource with glib-compile-resources"

if ! command -v glib-compile-resources &> /dev/null; then
    print_error "glib-compile-resources not found. Install with: apt install libglib2.0-dev"
    exit 1
fi

cd build/
if ! glib-compile-resources \
    --sourcedir=. \
    --target="${RESOURCE_NAME}" \
    gresource.xml; then
    print_error "gresource compilation failed"
    exit 1
fi

if [ ! -f "${RESOURCE_NAME}" ]; then
    print_error "Compiled gresource not found"
    exit 1
fi

judge "Compile gresource"

# Verify compilation success
print_ok "Verifying compiled gresource"
FILE_SIZE=$(stat -f%z "${RESOURCE_NAME}" 2>/dev/null || stat -c%s "${RESOURCE_NAME}")
if [ "$FILE_SIZE" -lt 10000 ]; then
    print_warn "Warning: gresource is very small (${FILE_SIZE} bytes), may be incomplete"
fi

# Verify content
if ! gresource dump "${RESOURCE_NAME}" | grep -q "org/gnome/shell/theme"; then
    print_error "Compiled gresource doesn't contain expected resource paths"
    exit 1
fi

print_ok "gresource verified: $(numfmt --to=iec-i --suffix=B $FILE_SIZE 2>/dev/null || echo "$FILE_SIZE bytes")"
cd ..

judge "Verify gresource"

# ============================================================================
# STEP 8: INSTALL COMPILED GRESOURCE
# ============================================================================

print_ok "Installing custom gresource to system"

if [ ! -d "${THEME_DIR}" ]; then
    mkdir -p "${THEME_DIR}"
fi

# Install the new gresource
cp "build/${RESOURCE_NAME}" "${THEME_DIR}/${RESOURCE_NAME}"
chown root:root "${THEME_DIR}/${RESOURCE_NAME}"
chmod 644 "${THEME_DIR}/${RESOURCE_NAME}"

print_ok "Installed to: ${THEME_DIR}/${RESOURCE_NAME}"
judge "Install gresource to system"

# ============================================================================
# STEP 9: DISABLE YARU THEME TO PREVENT FALLBACK
# ============================================================================

print_ok "Disabling Yaru theme fallback"

YARU_LOCATIONS=(
    "/usr/share/themes/Yaru"
    "/usr/share/gnome-shell/extensions/yaru-colors@ubuntu.com"
)

for location in "${YARU_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        print_ok "Disabling: $location"
        if [ ! -d "${location}.disabled" ]; then
            mv "$location" "${location}.disabled" 2>/dev/null || print_warn "Could not disable $location"
        fi
    fi
done

judge "Disable Yaru theme"

# ============================================================================
# STEP 10: CONFIGURE GDM ENVIRONMENT
# ============================================================================

print_ok "Configuring GDM environment variables"

mkdir -p /etc/environment.d/
cat > /etc/environment.d/99-gdm-custom-theme.conf << 'ENV_EOF'
# Force GNOME Shell to load custom GDM theme at boot
GNOME_SHELL_THEME="/usr/share/gnome-shell/theme/gnome-shell-theme.gresource"
GTK_THEME="Adwaita:dark"
EOF

judge "Configure GDM environment"

# ============================================================================
# STEP 11: CLEAR CACHES TO FORCE RELOAD
# ============================================================================

print_ok "Clearing GNOME Shell theme caches"

# Clear system cache
if [ -d /var/cache/gnome-shell-* ]; then
    rm -rf /var/cache/gnome-shell-* 2>/dev/null || true
fi

# Clear user caches for root (running user during build)
if [ -d ~/.cache/gnome-shell-* ]; then
    rm -rf ~/.cache/gnome-shell-* 2>/dev/null || true
fi

print_ok "Caches cleared"
judge "Clear caches"

# ============================================================================
# STEP 12: FINAL VERIFICATION
# ============================================================================

print_ok "Verifying theme installation"

# Check gresource exists
if [ ! -f "${THEME_DIR}/${RESOURCE_NAME}" ]; then
    print_error "gresource not found after installation"
    exit 1
fi

# Check it's valid
if ! file "${THEME_DIR}/${RESOURCE_NAME}" | grep -q "Gio resource"; then
    print_error "Installed file is not a valid Gio resource"
    exit 1
fi

# Check CSS is inside
if ! gresource dump "${THEME_DIR}/${RESOURCE_NAME}" | grep -q "gdm.css"; then
    print_error "CSS not found in installed gresource"
    exit 1
fi

# Check Yaru is disabled
if [ -d "/usr/share/themes/Yaru" ]; then
    print_warn "Yaru theme is still active (may be reinstalled by updates)"
else
    print_ok "Yaru theme successfully disabled"
fi

print_ok "✓ GDM theme installation verified"
judge "Verify theme installation"

# ============================================================================
# CLEANUP
# ============================================================================

print_ok "Cleaning up temporary files"
cd /
rm -rf "${WORK_DIR}"
print_ok "Cleanup complete"

# ============================================================================
# SUMMARY
# ============================================================================

print_ok "=========================================="
print_ok "✓ GDM Custom Theme Successfully Applied"
print_ok "=========================================="
print_ok ""
print_ok "Installed: ${THEME_DIR}/${RESOURCE_NAME}"
print_ok "Backup:    ${BACKUP_DIR}/${RESOURCE_NAME}.original"
print_ok ""
print_ok "The custom GDM theme will be active after GDM restart or system reboot."
print_ok ""
print_ok "To verify the theme is loaded:"
print_ok "  gresource dump /usr/share/gnome-shell/theme/gnome-shell-theme.gresource | head -20"
print_ok ""
print_ok "To manually restart GDM:"
print_ok "  sudo systemctl restart gdm3"
print_ok ""
print_ok "=========================================="
