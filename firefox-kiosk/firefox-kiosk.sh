#!/usr/bin/env bash

###############################################################################
# Firefox Kiosk Controller 
# Version: 3.0
#
# Responsibilities:
#   • Wait until SharePoint is reachable
#   • Launch Firefox
#   • Restart Firefox if it exits
#   • Keep detailed logs
#
# Responsibilities NOT handled here:
#   • Starting at login (systemd)
#   • Network troubleshooting/recovery (network-watchdog)
#   • Notifications (network-watchdog)
#   • Automatic controller restart (systemd)
###############################################################################

set -euo pipefail


###############################################################################
# Configuration
###############################################################################

# Website used to determine whether the kiosk has usable connectivity
SHAREPOINT_URL="https://fairmounthomesorg.sharepoint.com/sites/TVAnnouncementsHC"

# Firefox executable
FIREFOX="firefox-esr"

# Extra wait after SharePoint becomes reachable
NETWORK_SETTLE_TIME=3


###############################################################################
# Logging
###############################################################################

log() {

    echo "[$(date '+%F %T')] $*"

}


###############################################################################
# Wait for SharePoint
###############################################################################

wait_for_sharepoint() {

    log "Waiting for SharePoint..."

    while true
    do

        local http_code

        http_code=$(curl \
            --silent \
            --output /dev/null \
            --write-out "%{http_code}" \
            --max-time 15 \
            "$SHAREPOINT_URL")

        if [[ "$http_code" != "000" ]]
        then
            log "SharePoint responded with HTTP ${http_code}."

            return 0
        fi

        log "SharePoint is not reachable. Retrying in 10 seconds..."

        sleep 10

    done

}


###############################################################################
# Launch Firefox
###############################################################################

launch_firefox() {

    log "Launching Firefox..."

    "$FIREFOX"

}


###############################################################################
# Main
###############################################################################

main() {

    log "==========================================================="
    log "Firefox Kiosk Controller Starting"
    log "==========================================================="

    wait_for_sharepoint

    sleep "${NETWORK_SETTLE_TIME}"

    while true
    do

        if launch_firefox
        then
            exit_code=0
        else
            exit_code=$?
        fi

        log "Firefox exited (code ${exit_code})."

        log "Restarting Firefox in 10 seconds..."

        sleep 10

    done

}


###############################################################################
# Program Entry Point
###############################################################################

main

