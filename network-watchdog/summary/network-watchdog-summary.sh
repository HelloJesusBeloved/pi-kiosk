#!/usr/bin/env bash


set -euo pipefail


STATE_FILE="$HOME/.local/share/pi-kiosk/network-watchdog.state"
SUMMARY_STATE_FILE="$HOME/.local/share/pi-kiosk/network-watchdog-summary.state"


###############################################################################
# Load State
###############################################################################

if [[ ! -f "$STATE_FILE" ]]
then
    echo "Network watchdog state file not found: $STATE_FILE"
    exit 1
fi

if [[ ! -f "$SUMMARY_STATE_FILE" ]]
then
    echo "Network watchdog summary state file not found: $SUMMARY_STATE_FILE"
    exit 1
fi

source "$STATE_FILE"
source "$SUMMARY_STATE_FILE"


###############################################################################
# Configuration
###############################################################################

HOSTNAME="$(hostname)"
CURRENT_TIME="$(date '+%F %T')"


###############################################################################
# Build Summary
###############################################################################

MESSAGE="📊 Daily Network Watchdog Summary

Host: ${HOSTNAME}
Time: ${CURRENT_TIME}

Version: ${VERSION}

Recovery Count: ${RECOVERY_COUNT}
Wi-Fi Reconnects: ${WIFI_RECONNECTS}
NetworkManager Restarts: ${NM_RESTARTS}
Reboots: ${REBOOTS}
Consecutive Reboots: ${CONSECUTIVE_REBOOTS}

Watchdog Reboot: ${WATCHDOG_REBOOT}
Last Watchdog Reboot: ${WATCHDOG_REBOOT_TIME}

Last Failure: ${LAST_FAILURE}
Failure Time: ${LAST_FAILURE_TIME}
Last Success: ${LAST_SUCCESS_TIME}"


###############################################################################
# Send Summary
###############################################################################

if [[ "$SUMMARY_NTFY_ENABLED" != "true" ]]
then
    exit 0
fi


curl \
    --silent \
    --show-error \
    --fail \
    --max-time 10 \
    -H "Title: ${HOSTNAME} - Daily Watchdog Summary" \
    -H "Priority: low" \
    -H "Tags: computer,bar_chart" \
    -d "$MESSAGE" \
    "${SUMMARY_NTFY_SERVER}/${SUMMARY_NTFY_TOPIC}"
