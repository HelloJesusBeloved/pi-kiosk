#!/bin/bash


set -e


REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user/"

OLD_FILE="$HOME/.config/autostart/firefox.desktop"
NEW_LOCATION="$HOME/Setup/Archive"

NM_PERMISSION_SCRIPT="$REPO_ROOT/network-watchdog/setup/grant-user-NMrestart-permission.sh"


# Move the old Autostart Desktop file to Achive folder
mkdir -p $NEW_LOCATION


if [ -f "$OLD_FILE" ]; then
    mv "$OLD_FILE" "$NEW_LOCATION"
    echo "Moved $OLD_FILE"
else
    echo "$OLD_FILE not found; nothing to move"
fi


# Install the new scripts/systemd services with normal 755 (read, write, and executable) permissions
mkdir -p $BIN_DIR
mkdir -p $SYSTEMD_USER_DIR

install -m 755 $REPO_ROOT/network-watchdog/network-watchdog.sh $BIN_DIR
install -m 755 $REPO_ROOT/firefox-kiosk/firefox-kiosk.sh $BIN_DIR

install -m 644 $REPO_ROOT/network-watchdog/systemd/network-watchdog.service $SYSTEMD_USER_DIR
install -m 644 $REPO_ROOT/firefox-kiosk/systemd/firefox-kiosk.service $SYSTEMD_USER_DIR


# Start the service's
# Reload the systemd user daemon so it see thes service files that were just added
systemctl --user daemon-reload

systemctl --user enable --now firefox-kiosk.service network-watchdog.service


# Give the current user permission to restart NetworkManager so network-watchdog can
chmod +x $NM_PERMISSION_SCRIPT
./$NM_PERMISSION_SCRIPT
