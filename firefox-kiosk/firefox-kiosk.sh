#!/usr/bin/env bash

###############################################################################
# Firefox Kiosk Controller
#
# Responsibilities:
#   • Wait until the Pi is actually ready
#   • Launch Firefox
#   • Restart Firefox if it exits
#   • Keep detailed logs
#
# Responsibilities NOT handled here:
#   • Starting at login (systemd)
#   • Automatic service restart (systemd)
###############################################################################

set -euo pipefail

###############################################################################
# Configuration
###############################################################################

# Website to check if reachable for DNS Ping and Curl Checks
SHAREPOINT_URL="https://fairmounthomesorg.sharepoint.com/sites/TVAnnouncementsHC"

# Firefox executable
FIREFOX="firefox-esr"

# Maximum startup wait (4 hours)
MAX_STARTUP_WAIT=14400

# Retry interval while waiting
RETRY_INTERVAL=10

# Extra wait after network comes up
NETWORK_SETTLE_TIME=3

# Startup timer begins when the controller starts.
STARTUP_START_TIME=$(date +%s)

# Future NTFY Settings
ENABLE_NTFY=false

#NTFY_TOPIC="company-pi"

#NTFY_SERVER="https://ntfy.sh"

###############################################################################
# Logging
###############################################################################

log() {
    echo "[$(date '+%F %T')] $*"
}

###############################################################################
# Notifications
###############################################################################

notify() {

    local level="$1"
    shift
    local message="$*"

    # Always log locally
    log "[$level] $message"

    # Future:
    # Send ntfy notification here.
    #
    # Example:
    #
    # if [[ "$ENABLE_NTFY" == "true" ]]; then
    #     curl ...
    # fi

}

###############################################################################
# Startup Timeout
###############################################################################

check_startup_timeout() {

    local stage="$1"

    if (( $(date +%s) - STARTUP_START_TIME >= MAX_STARTUP_WAIT ))
    then
        notify ERROR "Startup timed out after ${MAX_STARTUP_WAIT} seconds while waiting for ${stage}."
    fi

}

###############################################################################
# Wait for NetworkManager
###############################################################################

wait_for_networkmanager() {

    log "Waiting for NetworkManager..."

    until nm-online --quiet --timeout=5
    do
        check_startup_timeout "NetworkManager"
        sleep "${RETRY_INTERVAL}"
    done

    log "NetworkManager reports network online."
}

###############################################################################
# Wait for DNS
###############################################################################

wait_for_dns() {

    log "Waiting for DNS..."

    until getent hosts "$(echo "$SHAREPOINT_URL" | awk -F/ '{print $3}')" >/dev/null
    do
        check_startup_timeout "DNS"
        sleep "${RETRY_INTERVAL}"
    done

    log "DNS resolution successful."
}

###############################################################################
# Wait for SharePoint
###############################################################################

wait_for_sharepoint() {

    local start_time
    start_time=$(date +%s)

    log "Waiting for SharePoint..."

    while true
    do

        http_code=$(curl \
            --silent \
            --output /dev/null \
            --write-out "%{http_code}" \
            --max-time 15 \
            "$SHAREPOINT_URL")
        
        if [[ "$http_code" != "000" ]]; then
            notify INFO "SharePoint responded with HTTP ${http_code}."
            return
        fi
        
        check_startup_timeout "SharePoint"
        sleep "${RETRY_INTERVAL}"

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

    wait_for_networkmanager

    sleep "${NETWORK_SETTLE_TIME}"

    wait_for_dns

    wait_for_sharepoint

    while true
    do
        if launch_firefox; then
            exit_code=0
        else
            exit_code=$?
        fi
    
        notify WARNING "Firefox exited (code ${exit_code})."
        log "Restarting Firefox in 10 seconds..."
        sleep 10
    done
    
}

main
