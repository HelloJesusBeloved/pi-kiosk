#!/bin/bash


# This script copys network-watchdog.sh to ~/local/bin

NETWORK_WATCHDOG_SCRIPT_LOCATION="$HOME/Code/Projects/pi-kiosk/network-watchdog/network-watchdog.sh"

cp $NETWORK_WATCHDOG_SCRIPT_LOCATION $HOME/.local/bin
