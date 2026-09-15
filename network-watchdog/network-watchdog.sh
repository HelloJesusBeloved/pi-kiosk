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

#Seconds between network checks
CHECK_INTERVAL=60

STATE_FILE="$HOME/.local/share/pi-kiosk/network-watchdog.state"

# The URL to ping to test a Microsoft site is reachable
SHAREPOINT_URL="https://fairmounthomesorg.sharepoint.com/sites/TVAnnouncementsHC"

# Seconds to wait after the watchdog starts before beginning network monitoring.
STARTUP_DELAY=120


# For verify_failure()
# Number of consecutive failed checks required before beginning recovery.
FAILURE_CONFIRMATIONS=3

# Seconds between confirmation attempts.
FAILURE_CONFIRM_DELAY=60


# For request_reboot()
# Seconds after boot before watchdog is allowed to request another reboot.
REBOOT_COOLDOWN=300

# Maximum watchdog-initiated reboots before requiring manual intervention.
MAX_CONSECUTIVE_REBOOTS=3


#For load_config_overrides()
#Local Config File Overrides
#Example: Add "STARTUP_DELAY=240" to $CONFIG_OVERRIDE_FILE to change it from the default
CONFIG_OVERRIDE_FILE="$HOME/.config/pi-kiosk/network-watchdog.conf"



###############################################################################
# Local Configuration Override
###############################################################################

load_config_overrides() {
#Load Local Config File Overrides if they exist

    if [[ -f "$CONFIG_OVERRIDE_FILE" ]]

    then
        log "Loading local configuration: $CONFIG_OVERRIDE_FILE"
        source "$CONFIG_OVERRIDE_FILE"
    else
        log "No local configuration override found. Using defaults."
    fi
}



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

    mkdir -p $HOME/.local/share/pi-kiosk

    cat > "$STATE_FILE" << EOF
VERSION=$VERSION

RECOVERY_COUNT=0

WIFI_RECONNECTS=0

NM_RESTARTS=0

REBOOTS=0

CONSECUTIVE_REBOOTS=0

WATCHDOG_REBOOT=false

WATCHDOG_REBOOT_TIME=""

LAST_FAILURE=""

LAST_FAILURE_TIME=""

LAST_SUCCESS_TIME=""
EOF

}


load_state() {
# Retrieve and make active the variables from the state file

    source "$STATE_FILE"

}


save_state() {
# Writes the current state to the save file

tmp="${STATE_FILE}.tmp"

    cat > "$tmp" << EOF
VERSION=$VERSION

RECOVERY_COUNT=$RECOVERY_COUNT

WIFI_RECONNECTS=$WIFI_RECONNECTS

NM_RESTARTS=$NM_RESTARTS

REBOOTS=$REBOOTS

CONSECUTIVE_REBOOTS=$CONSECUTIVE_REBOOTS

WATCHDOG_REBOOT=$WATCHDOG_REBOOT

WATCHDOG_REBOOT_TIME="$WATCHDOG_REBOOT_TIME"

LAST_FAILURE="$LAST_FAILURE"

LAST_FAILURE_TIME="$LAST_FAILURE_TIME"

LAST_SUCCESS_TIME="$LAST_SUCCESS_TIME"
EOF

mv "$tmp" "$STATE_FILE"

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

    log "Recovery Count     : ${RECOVERY_COUNT}"
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
# Peripherals Recovery
###############################################################################


restart_firefox() {

    log "Restarting Firefox controller..."

    sleep 5

    if systemctl --user restart firefox-kiosk.service
    then
        log "Firefox controller restarted successfully."
        return 0
    fi

    log "[WARNING] Failed to restart Firefox controller."

    return 1

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


record_recovery_success() {

    local recovery_type="$1"


    LAST_SUCCESS_TIME="$(date '+%F %T')"

    RECOVERY_ACTIVE=false

    WATCHDOG_REBOOT=false

    CONSECUTIVE_REBOOTS=0


    case "$recovery_type" in

        wifi)
            WIFI_RECONNECTS=$((WIFI_RECONNECTS + 1))
            ;;

        networkmanager)
            NM_RESTARTS=$((NM_RESTARTS + 1))
            ;;

        *)
            log "Unknown recovery type: $recovery_type"
            ;;

    esac


    save_state

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


###############################################################################
# Reboot Management
###############################################################################

# Request a system reboot.
request_reboot() {

    ###########################################################################
    # Check Reboot Limit
    ###########################################################################

    if (( CONSECUTIVE_REBOOTS >= MAX_CONSECUTIVE_REBOOTS ))
    then
        log "Maximum consecutive reboot limit reached."
        log "Manual intervention required."

        return 1
    fi


    ###########################################################################
    # Check Reboot Cooldown
    ###########################################################################

    if [[ "$WATCHDOG_REBOOT" == "true" ]]
    then

        local now
        local last
        local elapsed

        now=$(date +%s)

        if [[ -n "$WATCHDOG_REBOOT_TIME" ]]
        then
            last=$(date -d "$WATCHDOG_REBOOT_TIME" +%s 2>/dev/null)
        else
            last=0
        fi


        if [[ -z "$last" ]]
        then
            last=0
        fi


        elapsed=$(( now - last ))

        if (( elapsed < REBOOT_COOLDOWN ))
        then
            log "Reboot cooldown active."
            log "Elapsed  : ${elapsed}s"
            log "Required : ${REBOOT_COOLDOWN}s"

            return 1
        fi

    fi


    ###########################################################################
    # Record Reboot
    ###########################################################################

    REBOOTS=$((REBOOTS + 1))

    CONSECUTIVE_REBOOTS=$((CONSECUTIVE_REBOOTS + 1))

    WATCHDOG_REBOOT=true

    WATCHDOG_REBOOT_TIME="$(date '+%F %T')"

    RECOVERY_ACTIVE=false

    save_state


    ###########################################################################
    # Log Reboot
    ###########################################################################

    log "============================================================"
    log "Requesting system reboot."
    log "Reboot Count       : ${REBOOTS}"
    log "Consecutive Reboots: ${CONSECUTIVE_REBOOTS}"
    log "============================================================"

    sleep 5


    ###########################################################################
    # Reboot
    ###########################################################################

    systemctl reboot

    return 0

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

    RECOVERY_COUNT=$((RECOVERY_COUNT + 1))
    LAST_FAILURE="$NETWORK_INCIDENT"
    LAST_FAILURE_TIME="$(date '+%F %T')"

    save_state

    log "Recovery #${RECOVERY_COUNT}, Incident: $NETWORK_INCIDENT"

    if attempt_wifi_reconnect
    then
        log "Recovery successful."

	    record_recovery_success wifi

        save_state

        restart_firefox

        return
    fi

    if restart_networkmanager
    then
        log "Recovery successful."

        record_recovery_success networkmanager

        save_state

        restart_firefox

        return
    fi

    if ! request_reboot
    then
        log "Reboot request denied. Continuing network monitoring."

        RECOVERY_ACTIVE=false

        return
    fi

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

load_config_overrides

log_startup

log "Waiting ${STARTUP_DELAY} seconds before beginning network monitoring..."
sleep "$STARTUP_DELAY"

# Build the initial network baseline.
collect_network_state

build_network_state

LAST_NETWORK_STATE="$CURRENT_NETWORK_STATE"

log_network_state

main_loop
