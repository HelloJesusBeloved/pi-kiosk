#!/bin/bash

set -e


###############################################################################
# Repository Location
###############################################################################

# Set how many directories below the repository root this script is located.
REPO_ROOT_DEPTH=1

# Find the absolute path of the directory containing this script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Start at the script directory, then walk upward to the repository root.
REPO_ROOT="$SCRIPT_DIR"

for ((i = 0; i < REPO_ROOT_DEPTH; i++))
do
    REPO_ROOT="$(dirname "$REPO_ROOT")"
done


###############################################################################
# Installation Locations
###############################################################################

BIN_DIR="$HOME/.local/bin"

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

STATE_DIR="$HOME/.local/share/pi-kiosk"

SUMMARY_STATE_FILE="$STATE_DIR/network-watchdog-summary.state"


###############################################################################
# Source Files
###############################################################################

SUMMARY_SCRIPT="$REPO_ROOT/network-watchdog/summary/network-watchdog-summary.sh"

SUMMARY_SERVICE="$REPO_ROOT/network-watchdog/summary/systemd/network-watchdog-summary.service"

SUMMARY_TIMER="$REPO_ROOT/network-watchdog/summary/systemd/network-watchdog-summary.timer"


###############################################################################
# Configuration Options
###############################################################################

# Each option uses the format:
#
#     Display Name=value
#
# Add, remove, or change options here without changing the menu logic below.


SUMMARY_NTFY_ENABLED_OPTIONS=(
    "Enabled=true"
    "Disabled=false"
)


SUMMARY_NTFY_SERVER_OPTIONS=(
    "NerdVPN ntfy server=https://ntfy.nerdvpn.de"
    "ntfy.sh=https://ntfy.sh"
)


SUMMARY_NTFY_TOPIC_OPTIONS=(
    "Pi Kiosk Summary=pi-kiosk-summary"
    "Hostname=$(hostname)"
)


###############################################################################
# Configuration Functions
###############################################################################

choose_option() {

    local prompt="$1"

    shift

    local options=("$@")

    local selection
    local value


    echo
    echo "$prompt"
    echo


    select selection in "${options[@]}"
    do
        if [[ -n "$selection" ]]
        then
            value="${selection#*=}"

            echo "$value"

            return 0
        fi

        echo "Invalid selection."
    done

}


configure_summary_state() {

    mkdir -p "$STATE_DIR"


    ###########################################################################
    # Existing Configuration
    ###########################################################################

    if [[ -f "$SUMMARY_STATE_FILE" ]]
    then
        echo
        echo "Existing Network Watchdog Summary configuration found:"
        echo
        cat "$SUMMARY_STATE_FILE"
        echo

        read -r -p "Keep the existing configuration? [Y/n]: " KEEP_EXISTING

        if [[ -z "$KEEP_EXISTING" || "$KEEP_EXISTING" =~ ^[Yy]$ ]]
        then
            echo "Keeping existing configuration."
            return 0
        fi

        echo
        echo "Existing configuration will be overwritten."

    else
        echo
        echo "No Network Watchdog Summary configuration found."
        echo "Let's configure it now."

    fi


    ###########################################################################
    # Select Configuration
    ###########################################################################

    SUMMARY_NTFY_ENABLED=$(choose_option \
        "Enable ntfy notifications?" \
        "${SUMMARY_NTFY_ENABLED_OPTIONS[@]}")


    SUMMARY_NTFY_SERVER=$(choose_option \
        "Select the ntfy server:" \
        "${SUMMARY_NTFY_SERVER_OPTIONS[@]}")


    SUMMARY_NTFY_TOPIC=$(choose_option \
        "Select the ntfy topic:" \
        "${SUMMARY_NTFY_TOPIC_OPTIONS[@]}")


    ###########################################################################
    # Write Configuration
    ###########################################################################

    cat > "$SUMMARY_STATE_FILE" << EOF
SUMMARY_NTFY_ENABLED=$SUMMARY_NTFY_ENABLED
SUMMARY_NTFY_SERVER=$SUMMARY_NTFY_SERVER
SUMMARY_NTFY_TOPIC=$SUMMARY_NTFY_TOPIC
EOF


    chmod 600 "$SUMMARY_STATE_FILE"


    echo
    echo "Network Watchdog Summary configuration saved:"
    echo
    cat "$SUMMARY_STATE_FILE"
    echo

}


###############################################################################
# Configure Network Watchdog Summary
###############################################################################

echo "Configuring Network Watchdog Daily Summary..."

configure_summary_state


###############################################################################
# Install Scripts and systemd Units
###############################################################################

echo "Installing Network Watchdog Daily Summary..."

mkdir -p "$BIN_DIR"
mkdir -p "$SYSTEMD_USER_DIR"


# Install the summary script as executable.

if install -m 755 "$SUMMARY_SCRIPT" "$BIN_DIR/network-watchdog-summary.sh"
then
    echo "Installed network-watchdog-summary.sh"
else
    echo "ERROR: Failed to install network-watchdog-summary.sh"
    exit 1
fi


# Install the systemd service.

if install -m 644 "$SUMMARY_SERVICE" "$SYSTEMD_USER_DIR/network-watchdog-summary.service"
then
    echo "Installed network-watchdog-summary.service"
else
    echo "ERROR: Failed to install network-watchdog-summary.service"
    exit 1
fi


# Install the systemd timer.

if install -m 644 "$SUMMARY_TIMER" "$SYSTEMD_USER_DIR/network-watchdog-summary.timer"
then
    echo "Installed network-watchdog-summary.timer"
else
    echo "ERROR: Failed to install network-watchdog-summary.timer"
    exit 1
fi


###############################################################################
# Reload systemd User Daemon
###############################################################################

echo
echo "Reloading systemd user daemon..."

systemctl --user daemon-reload


###############################################################################
# Enable and Start Timer
###############################################################################

echo
echo "Configuring network-watchdog-summary.timer..."


# Rebuild the enablement symlink in case the WantedBy= setting changed.

systemctl --user disable network-watchdog-summary.timer 2>/dev/null || true


if systemctl --user enable network-watchdog-summary.timer
then
    echo "network-watchdog-summary.timer enabled successfully."
else
    echo "ERROR: Failed to enable network-watchdog-summary.timer."
    exit 1
fi


# Start the timer, or restart it if it is already running.

if systemctl --user is-active --quiet network-watchdog-summary.timer
then
    echo "network-watchdog-summary.timer is already running. Restarting..."

    if systemctl --user restart network-watchdog-summary.timer
    then
        echo "network-watchdog-summary.timer restarted successfully."
    else
        echo "ERROR: Failed to restart network-watchdog-summary.timer."
        exit 1
    fi

else
    echo "network-watchdog-summary.timer is not running. Starting..."

    if systemctl --user start network-watchdog-summary.timer
    then
        echo "network-watchdog-summary.timer started successfully."
    else
        echo "ERROR: Failed to start network-watchdog-summary.timer."
        exit 1
    fi
fi


###############################################################################
# Verify Installation
###############################################################################

echo
echo "Verifying installation..."

if systemctl --user is-enabled --quiet network-watchdog-summary.timer
then
    echo "Timer: enabled"
else
    echo "ERROR: Timer is not enabled."
    exit 1
fi


if systemctl --user is-active --quiet network-watchdog-summary.timer
then
    echo "Timer: active"
else
    echo "ERROR: Timer is not active."
    exit 1
fi


echo
echo "Network Watchdog Daily Summary installed successfully."
echo
echo "Next scheduled run:"
systemctl --user list-timers network-watchdog-summary.timer --no-pager
