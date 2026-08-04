#!/bin/bash

# THE BASH SCRIPT V2 (Everything is re-runable, execpt the cron job, the aliases, and the main_firefox_profile will be untar-ed again)

#Remove Packages
sudo apt -y purge chromium firefox && sudo apt -y autoremove

#Upgrade Packages
sudo apt -y update && sudo apt -y full-upgrade

#Enable Desktop Auto Boot 
sudo raspi-config nonint do_boot_behaviour B4

#Install Packages
sudo apt -y install firefox-esr vim

#Turn Off Screen Blanking
sudo raspi-config nonint do_blanking 1

#Autohide the Taskbar
echo "autohide=true" > $HOME/.config/wf-panel-pi/wf-panel-pi.ini

#Add Cron Jobs
#1. Update and Reboot Nightly
#2. Keep Power Save Off
echo "0 2 * * * root apt update && apt full-upgrade -y && reboot
@reboot root /usr/sbin/iw dev wlan0 set power_save off" | sudo tee -a /etc/crontab > /dev/null

#Add Aliases
echo "
alias temp='vcgencmd measure_temp'

alias osversion='cat /etc/os-release'

alias mouse='$HOME/Setup/cursor-toggle.sh'
alias mousee='$HOME/Setup/cursor-toggle.sh && exit'" >> $HOME/.bashrc

#Make the Desktop Config File and Hide The Wastebin and Set Fairmount Wallpaper
mkdir -p ~/.config/pcmanfm/default
if [ ! -f ~/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf ]; then
    cp /etc/xdg/pcmanfm/default/desktop-items-0.conf ~/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf 2>/dev/null || true
fi
sed -i 's|show_trash=1|show_trash=0|' $HOME/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf
sed -i "s|wallpaper=/usr/share/rpd-wallpaper.*|wallpaper=$HOME/Setup/Fairmount_Logo.png|" $HOME/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf

#Untar The FireFox Profile
tar -xvf main_firefox_profile.tar.gz

#Move the Tar File Into the Setup Folder
mv $HOME/PiSlides_Setup.tar.gz $HOME/Setup

#Doesn't appear to make the prompt to set Firefox as the default go away
#Set FireFox ESR As The Default Browser
sudo update-alternatives --set x-www-browser /usr/bin/firefox-esr

#Make journalctl logs permanent
sudo mkdir -p /var/log/journal
sudo sed -i 's/#Storage=auto/Storage=persistent/' /etc/systemd/journald.conf
sudo sed -i 's/#SystemKeepFree=/#SystemKeepFree=4G/' /etc/systemd/journald.conf
#Disable the Raspberry Pi override
sudo mv /usr/lib/systemd/journald.conf.d/40-rpi-volatile-storage.conf /usr/lib/systemd/journald.conf.d/40-rpi-volatile-storage.conf.disabled
sudo chown root:systemd-journal /var/log/journal
sudo chmod 2755 /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
sudo journalctl --flush

#---------------------------------------------------------------

#Create Mouse Visibility Toggle Scripts

#1. cursor-hide.sh
cat << 'END' > $HOME/Setup/cursor-hide.sh
#!/bin/bash
# Make the mouse cursor invisible on labwc (Raspberry Pi OS Trixie / Wayland)
set -e

# 1. Build the Invisible theme if it doesn't already exist
if [ ! -f /usr/share/icons/Invisible/cursors/left_ptr ]; then
    echo "Building Invisible cursor theme..."
    sudo apt install -y imagemagick x11-apps

    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    convert -size 1x1 xc:none 1x1.png
    echo "1 0 0 1x1.png" > transparent.cfg
    xcursorgen transparent.cfg transparent

    sudo mkdir -p /usr/share/icons/Invisible/cursors
    for name in left_ptr default arrow hand hand1 hand2 pointer xterm text \
                watch wait crosshair help question_arrow top_left_arrow \
                sb_h_double_arrow sb_v_double_arrow fleur; do
        sudo cp transparent /usr/share/icons/Invisible/cursors/$name
    done

    sudo tee /usr/share/icons/Invisible/index.theme > /dev/null <<'EOF'
[Icon Theme]
Name=Invisible
Comment=Fully transparent cursors
Inherits=PiXflat
EOF

    cd ~ && rm -rf "$TMPDIR"
fi

# 2. Point labwc at the Invisible theme
mkdir -p ~/.config/labwc
touch ~/.config/labwc/environment

# Remove any existing XCURSOR_* lines, then add ours
sed -i '/^XCURSOR_THEME=/d; /^XCURSOR_SIZE=/d' ~/.config/labwc/environment
echo "XCURSOR_THEME=Invisible" >> ~/.config/labwc/environment
echo "XCURSOR_SIZE=1"          >> ~/.config/labwc/environment

echo "Cursor set to INVISIBLE."
echo "Restarting labwc to apply..."
labwc -r 2>/dev/null || pkill -HUP labwc || echo "Could not signal labwc — reboot manually."
END

chmod +x $HOME/Setup/cursor-hide.sh
$HOME/Setup/cursor-hide.sh


#2. cursor-show.sh
cat << 'END' > $HOME/Setup/cursor-show.sh
#!/bin/bash
# Restore the default visible mouse cursor on labwc
set -e

mkdir -p ~/.config/labwc
touch ~/.config/labwc/environment

# Remove the Invisible theme overrides; labwc falls back to the system default (PiXflat)
sed -i '/^XCURSOR_THEME=/d; /^XCURSOR_SIZE=/d' ~/.config/labwc/environment

echo "Cursor set to VISIBLE (system default theme)."
echo "Restarting labwc to apply..."
labwc -r 2>/dev/null || pkill -HUP labwc || echo "Could not signal labwc — reboot manually."
END

chmod +x $HOME/Setup/cursor-show.sh
$HOME/Setup/cursor-show.sh


#3. cursor-toggle.sh
cat << 'END' > $HOME/Setup/cursor-toggle.sh
#!/bin/bash
# cursor-toggle.sh
if grep -q "^XCURSOR_THEME=Invisible" ~/.config/labwc/environment 2>/dev/null; then
    $HOME/Setup/cursor-show.sh
else
    $HOME/Setup/cursor-hide.sh
fi
END

chmod +x $HOME/Setup/cursor-toggle.sh


#----------------------------------------------------------------


#Auto Start FireFox
#The Systemd Service
cat << 'END' > $HOME/.config/systemd/user/firefox-kiosk.service
"[Unit]
Description=Firefox Kiosk Controller
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple

# 🔥 FIX: ensure Wayland/X11 session variables are passed in
Environment=DISPLAY=:0
Environment=WAYLAND_DISPLAY=wayland-0
Environment=XDG_RUNTIME_DIR=/run/user/1000

# The kiosk controller script
ExecStart=%h/.local/bin/firefox-kiosk.sh

# If the controller exits unexpectedly,
# restart it after a short delay.
Restart=on-failure
RestartSec=10

# Write stdout/stderr to the journal
StandardOutput=journal
StandardError=journal

# Don't allow accidental multiple instances
# (systemd already handles this, but this documents intent)
SyslogIdentifier=firefox-kiosk

[Install]
WantedBy=graphical-session.target"
END


#The Auto Start Script the Service Uses
cat << 'END' > $HOME/.local/bin/firefox-kiosk.sh
"#!/usr/bin/env bash

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

# Website to display
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
        notify ERROR "Startup timed out after ${MAX_STARTUP_WAIT} seconds while waiting for ${stage}. Rebooting."

        log "Rebooting..."

        systemctl reboot
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

main"
END

chmod +x  $HOME/.local/bin/firefox-kiosk.sh

systemctl --user daemon-reload
systemctl --user enable firefox-kiosk.service
systemctl --user start firefox-kiosk.service

#Ask To Reboot
echo "
Kindly reboot my good sir(:"
