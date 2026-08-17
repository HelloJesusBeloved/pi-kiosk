#!/bin/bash

set -e


###############################################################################
# Repository Location
###############################################################################

# Set how many directories below the repository root this script is located.
REPO_ROOT_DEPTH=3

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


###############################################################################
# Source Files
###############################################################################

SUMMARY_SCRIPT="$REPO_ROOT/network-watchdog/summary/network-watchdog-summary.sh"

SUMMARY_SERVICE="$REPO_ROOT/network-watchdog/summary/systemd/network-watchdog-summary.service"

SUMMARY_TIMER="$REPO_ROOT/network-watchdog/summary/systemd/network-watchdog-summary.timer"


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
