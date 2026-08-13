#!/bin/bash


set -e


REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user/"

OLD_FILE="$HOME/.config/autostart/firefox.desktop"
NEW_LOCATION="$HOME/Setup/Archive"

NM_PERMISSION_SCRIPT="$REPO_ROOT/network-watchdog/setup/grant-user-NMrestart-permission.sh"
SUDOERS_FILE="/etc/sudoers.d/pi-watchdog"


# Move the old Autostart Desktop file to Achive folder
# Note: Only applys to my personal setup that I am updating to use firefox-kiosk, does nothing if there isn't a file to move
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

echo "Installed firefox-kiosk/network-watchdog.sh and .service"


###############################################################################
# Disable/Enable and Start or Restart services
# Reload the systemd user daemon
###############################################################################

systemctl --user daemon-reload


    for service in \
        firefox-kiosk.service \
        network-watchdog.service
    do

    echo "Configuring $service..."

    # Rebuild the enablement symlinks.
    #
    # This ensures that if the service's WantedBy= setting changed,
    # any old enablement is removed before the new one is created.

    systemctl --user disable "$service" 2>/dev/null || true

    if systemctl --user enable "$service"
    then
        echo "$service enabled successfully."
    else
        echo "ERROR: Failed to enable $service."
        exit 1
    fi


    # Start the service, or restart it if it is already running.

    if systemctl --user is-active --quiet "$service"
    then
        echo "$service is running. Restarting..."

        if systemctl --user restart "$service"
        then
            echo "$service restarted successfully."
        else
            echo "ERROR: Failed to restart $service."
            exit 1
        fi

    else
        echo "$service is not running. Starting..."

        if systemctl --user start "$service"
        then
            echo "$service started successfully."
        else
            echo "ERROR: Failed to start $service."
            exit 1
        fi
    fi

done


###############################################################################
# Ensure network-watchdog has permission to restart Network Manager
###############################################################################

if [ -f "$SUDOERS_FILE" ]; then
    echo "Correct permissions already in place"
else
    echo "Please give the current user permission to restart NetworkManager so network-watchdog can"
    chmod +x $NM_PERMISSION_SCRIPT
    sudo $NM_PERMISSION_SCRIPT
fi
