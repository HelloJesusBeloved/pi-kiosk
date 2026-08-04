#!/usr/bin/env bash

###############################################################################
# Network Watchdog
#
# Version: 1.0.0
#
# Purpose:
#     Monitor and maintain network connectivity for the Pi kiosk.
#
###############################################################################



###############################################################################
# Configuration
###############################################################################

VERSION="1.0.0"

CHECK_INTERVAL=60

STATE_FILE="$HOME/.local/share/pi-kiosk/network-watchdog.state"

# The URL to ping to test a Microsoft site is reachable
SHAREPOINT_URL="https://fairmounthomesorg.sharepoint.com/sites/TVAnnouncementsHC"




###############################################################################
# Runtime State Variables
###############################################################################

CURRENT_TIME=""

SSID=""

SIGNAL=""

IP_ADDRESS=""

GATEWAY=""

LAST_NETWORK_STATE=""

CURRENT_NETWORK_STATE=""

GATEWAY_OK=false

INTERNET_OK=false

DNS_OK=false

SHAREPOINT_OK=false

NETWORK_HEALTH="UNKNOWN"

NETWORK_INCIDENT="NONE"

RECOVERY_ACTIVE=false

# Number of consecutive failed checks required before beginning recovery.
FAILURE_CONFIRMATIONS=3

# Seconds between confirmation attempts.
FAILURE_CONFIRM_DELAY=10


###############################################################################
# Logging
###############################################################################

log() {
    echo "[$(date '+%F %T')] $*"
}



###############################################################################
# State Management
###############################################################################


initialize_state() {
# Create the state file if it does not already exist.

    if [[ -f "$STATE_FILE" ]]
    then
        return
    fi

    cat > "$STATE_FILE" << EOF
VERSION=$VERSION

RECOVERY_ID=0

WIFI_RECONNECTS=0

NM_RESTARTS=0

REBOOTS=0

LAST_FAILURE=""

LAST_FAILURE_TIME=""

LAST_SUCCESS_TIME="$(date '+%F %T')"
EOF

}


load_state() {

    source "$STATE_FILE"

}


save_state() {
# Writes the current state to the save file

    cat > "$STATE_FILE" << EOF
VERSION=$VERSION

RECOVERY_ID=$RECOVERY_ID

WIFI_RECONNECTS=$WIFI_RECONNECTS

NM_RESTARTS=$NM_RESTARTS

REBOOTS=$REBOOTS

LAST_FAILURE="$LAST_FAILURE"

LAST_FAILURE_TIME="$LAST_FAILURE_TIME"

LAST_SUCCESS_TIME="$LAST_SUCCESS_TIME"
EOF

}



###############################################################################
# Startup Log
###############################################################################

# Log startup information and the currently loaded state.
log_startup() {

    log "============================================================"
    log "Network Watchdog Starting"
    log "Version ${VERSION}"
    log "============================================================"

    log "Recovery ID        : ${RECOVERY_ID}"
    log "Wi-Fi Reconnects   : ${WIFI_RECONNECTS}"
    log "NM Restarts        : ${NM_RESTARTS}"
    log "Reboots            : ${REBOOTS}"

    if [[ -n "$LAST_FAILURE" ]]
    then
        log "Last Failure       : ${LAST_FAILURE}"
        log "Failure Time       : ${LAST_FAILURE_TIME}"
    else
        log "Last Failure       : None"
    fi

    if [[ -n "$LAST_SUCCESS_TIME" ]]
    then
        log "Last Success       : ${LAST_SUCCESS_TIME}"
    else
        log "Last Success       : Never"
    fi

    log "============================================================"

}



###############################################################################
# Network Monitoring
###############################################################################

# Collect the current network state.
collect_network_state() {

    # Time

    CURRENT_TIME=$(date '+%F %T')


    # Wi-Fi Information

    SSID=$(iw dev wlan0 link 2>/dev/null | awk -F': ' '/SSID/ {print $2}')

    SIGNAL=$(iw dev wlan0 link 2>/dev/null | awk '/signal:/ {print $2 " " $3}')


    # IP Information

    IP_ADDRESS=$(ip -4 addr show wlan0 \
        | awk '/inet / {print $2}' \
        | cut -d/ -f1)

    GATEWAY=$(ip route \
        | awk '/default/ {print $3}')


    # Connectivity Tests

    if ping -c 1 -W 2 "$GATEWAY" >/dev/null 2>&1
    then
        GATEWAY_OK=true
    else
        GATEWAY_OK=false
    fi

    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1
    then
        INTERNET_OK=true
    else
        INTERNET_OK=false
    fi

    if getent hosts "$(echo "$SHAREPOINT_URL" | awk -F/ '{print $3}')" >/dev/null
    then
        DNS_OK=true
    else
        DNS_OK=false
    fi

    http_code=$(curl \
        --silent \
        --output /dev/null \
        --write-out "%{http_code}" \
        --max-time 10 \
        "$SHAREPOINT_URL")

    if [[ "$http_code" == "200" || "$http_code" == "302" || "$http_code" == "401" || "$http_code" == "403" ]]
    then
        SHAREPOINT_OK=true
    else
        SHAREPOINT_OK=false
    fi

}


# Build a string representing the current network state.
build_network_state() {

    CURRENT_NETWORK_STATE="${SSID}|${SIGNAL}|${IP_ADDRESS}|${GATEWAY}|${GATEWAY_OK}|${INTERNET_OK}|${DNS_OK}|${SHAREPOINT_OK}"

}


# Determine whether the observed network state has changed.
network_state_changed() {

    build_network_state

    if [[ "$CURRENT_NETWORK_STATE" != "$LAST_NETWORK_STATE" ]]
    then
        LAST_NETWORK_STATE="$CURRENT_NETWORK_STATE"
        return 0
    fi

    return 1

}


# Network Health

# Classify the current network health.
evaluate_network_health() {

    if ! $GATEWAY_OK
    then
        NETWORK_HEALTH="CRITICAL"

    elif ! $INTERNET_OK
    then
        NETWORK_HEALTH="WARNING"

    elif ! $DNS_OK
    then
        NETWORK_HEALTH="WARNING"

    elif ! $SHAREPOINT_OK
    then
        NETWORK_HEALTH="WARNING"

    else
        NETWORK_HEALTH="HEALTHY"

    fi

}


# Incident Classification

classify_network_incident() {

    NETWORK_INCIDENT="NONE"

    if ! $GATEWAY_OK
    then
        NETWORK_INCIDENT="GATEWAY_UNREACHABLE"

    elif ! $INTERNET_OK
    then
        NETWORK_INCIDENT="INTERNET_UNREACHABLE"

    elif ! $DNS_OK
    then
        NETWORK_INCIDENT="DNS_FAILURE"

    elif ! $SHAREPOINT_OK
    then
        NETWORK_INCIDENT="SHAREPOINT_UNREACHABLE"

    fi

}


# Log the current network state.
log_network_state() {

    log "============================================================"
    log "Network State Changed"
    log "============================================================"

    log "Time      : ${CURRENT_TIME}"
    log "SSID      : ${SSID}"
    log "Signal    : ${SIGNAL}"
    log "IP        : ${IP_ADDRESS}"
    log "Gateway   : ${GATEWAY}"

    log "Gateway Reachable : ${GATEWAY_OK}"
    log "Internet          : ${INTERNET_OK}"
    log "DNS               : ${DNS_OK}"
    log "SharePoint        : ${SHAREPOINT_OK}"

    log "Health            : ${NETWORK_HEALTH}"
    log "Incident          : ${NETWORK_INCIDENT}"

    log "============================================================"

}



###############################################################################
# Network Recovery
###############################################################################


verify_failure() {

    log "Verifying network failure..."

    local attempt

    for (( attempt=1; attempt<=FAILURE_CONFIRMATIONS; attempt++ ))
    do

        log "Verification ${attempt}/${FAILURE_CONFIRMATIONS}..."

        sleep "${FAILURE_CONFIRM_DELAY}"

        collect_network_state
        evaluate_network_health
        classify_network_incident

        if [[ "$NETWORK_HEALTH" == "HEALTHY" ]]
        then
            log "Failure cleared during verification."

            return 1
        fi

    done

    log "Failure confirmed."

    return 0

}


attempt_wifi_reconnect() {

    log "Attempting Wi-Fi disconnect and reconnect."

    log "Disconnecting wlan0..."

    nmcli device disconnect wlan0

    sleep 10

    log "Reconnecting wlan0..."

    if nmcli device connect wlan0
    then
        log "Wi-Fi reconnect command succeeded."
    else
        log "[WARNING] Wi-Fi reconnect command failed."
        return 1
    fi


    log "Waiting 30 seconds for network to stabilize before checking state..."

    sleep 30


    collect_network_state


    if [[ "$GATEWAY_OK" == "true" && "$INTERNET_OK" == "true" ]]
    then
        log "Wi-Fi reconnect successful."
        return 0
    else
        log "[WARNING] Wi-Fi disconnect and reconnect did not restore connectivity."
        return 1
    fi

}


restart_networkmanager() {

    log "Restarting NetworkManager."

    sudo systemctl restart NetworkManager

    log "Waiting 30 seconds for network to stabilize."

    sleep 30

    collect_network_state

    if [[ "$GATEWAY_OK" == "true" && "$INTERNET_OK" == "true" ]]
    then
        log "NetworkManager restart successful."
        return 0
    fi

    log "[WARNING] NetworkManager restart failed."

    return 1

}


request_reboot() {

    log "[TEST] Would request reboot."

}


recover_network() {

    if [[ "$NETWORK_HEALTH" == "HEALTHY" ]]
    then
        return
    fi

    if [[ "$RECOVERY_ACTIVE" == "true" ]]
    then
        return
    fi

    RECOVERY_ACTIVE=true

    log "Starting recovery sequence."

    if ! verify_failure
    then
    	log "Recovery cancelled."

    	RECOVERY_ACTIVE=false
    	return
    fi

    if attempt_wifi_reconnect
    then
        log "Recovery successful."

        RECOVERY_ACTIVE=false
        return
    fi

    if restart_networkmanager
    then
        log "Recovery successful."

        RECOVERY_ACTIVE=false
        return
    fi

    request_reboot

    RECOVERY_ACTIVE=false

}



###############################################################################
# Main Loop
###############################################################################

# Main watchdog loop.
main_loop() {

    while true
    do

        collect_network_state
   
	build_network_state

        evaluate_network_health

	classify_network_incident

        if network_state_changed
        then
            log_network_state
        fi

	recover_network 

        sleep "${CHECK_INTERVAL}"
    

    done

}




###############################################################################
# Program Entry Point
###############################################################################

initialize_state

load_state

log_startup

# Build the initial network baseline.
collect_network_state

build_network_state

LAST_NETWORK_STATE="$CURRENT_NETWORK_STATE"

log_network_state

main_loop
