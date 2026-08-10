#!/bin/bash


set -e


REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user/"


# Move the old Autostart Desktop file to Achive folder
mkdir -p $HOME/Setup/Archive
mv $HOME/.config/autostart/firefox.desktop $HOME/Setup/Archive


# Install the new scripts/systemd services with normal 755 (read, write, and executable) permissions
install -m 755 $REPO_ROOT/network-watchdog/network-watchdog.sh $BIN_DIR
install -m 755 $REPO_ROOT/firefox-kiosk/firefox-kiosk.sh $BIN_DIR

install -m 755 $REPO_ROOT/network-watchdog/systemd/network-watchdog.service $SYSTEMD_USER_DIR
install -m 755 $REPO_ROOT/firefox-kiosk/systemd/firefox-kiosk.service $SYSTEMD_USER_DIR


# Start the service's
systemctl --user start firefox-kiosk.service network-watchdog.service
