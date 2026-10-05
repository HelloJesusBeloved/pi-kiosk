#!/bin/bash

# THE Pi KIOSK BASH SETUP SCRIPT
# Version 3.0
#
# Meant to be run on a freshly set up Raspberry Pi 5 running Raspberry Pi OS (64-bit)


#Set REPO_ROOT Variable

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


#Configuration Variables:

BIN_DIR="$HOME/.local/bin/pi-kiosk"

CRON_JOBS=(
    "0 2 * * * root apt update && apt full-upgrade -y && reboot"
    "@reboot root /usr/sbin/iw dev wlan0 set power_save off"
)

ALIASES=(
    "alias mouse='$BIN_DIR/cursor-toggle.sh'"
    "alias mousee='$BIN_DIR/cursor-toggle.sh && exit'"
)

#The image in the $WALLPAPER directory will be set as the Raspberry Pi's desktop wallpaper
WALLPAPER="$REPO_ROOT/assets/wallpaper"
SET_WALLPAPER="$(find "$WALLPAPER" -maxdepth 1 -type f -print -quit)"

HIDE_CURSOR_SCRIPTS=(
    "$REPO_ROOT/hide-cursor/cursor-hide.sh"
    "$REPO_ROOT/hide-cursor/cursor-show.sh"
    "$REPO_ROOT/hide-cursor/cursor-toggle.sh"
)


#Remove Chrome and FireFox
sudo apt -y purge chromium firefox 

#Upgrade Packages
sudo apt -y update && sudo apt -y full-upgrade

#Install Firefox ESR
sudo apt -y install firefox-esr && sudo apt -y autoremove

#Enable Desktop Auto Boot/Login (without a password) 
sudo raspi-config nonint do_boot_behaviour B4

#Turn Off Screen Auto Blanking
sudo raspi-config nonint do_blanking 1

#Autohide the Taskbar
#Note: wf-panel-pi.ini simply needs to be created and contain "autohide=true"
echo "autohide=true" > $HOME/.config/wf-panel-pi/wf-panel-pi.ini

#Add Cron Jobs
#1. Update and Reboot Nightly
#2. Keep Power Save Off (Helps Wi-Fi connection stability)

for job in "${CRON_JOBS[@]}"
do
    if ! grep -Fxq "$job" /etc/crontab
    then
        echo "$job" | sudo tee -a /etc/crontab > /dev/null
    fi
done

# Install hide-cursor scripts
mkdir -p "$BIN_DIR"

for script in "${HIDE_CURSOR_SCRIPTS[@]}"
do
    install -m 755 "$script" "$BIN_DIR"
done

# Replace any existing mouse/mousee aliases so old clone-path or Setup-dir
# aliases do not stack and conflict.
if [ -f "$HOME/.bashrc" ]
then
    sed -i '/^alias mouse=/d; /^alias mousee=/d' "$HOME/.bashrc"
fi

for alias in "${ALIASES[@]}"
do
    echo "$alias" >> "$HOME/.bashrc"
done

#Run the hide-cursor scripts once to install the neccessarry dependencies
"$BIN_DIR/cursor-show.sh"
"$BIN_DIR/cursor-hide.sh"

#Make the Desktop Config File and Hide The Wastebin and Set Fairmount Wallpaper
mkdir -p ~/.config/pcmanfm/default
if [ ! -f ~/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf ]; then
    cp /etc/xdg/pcmanfm/default/desktop-items-0.conf ~/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf 2>/dev/null || true
fi
sed -i 's|show_trash=1|show_trash=0|' $HOME/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf
sed -i "s|wallpaper=.*|wallpaper=$SET_WALLPAPER|" $HOME/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf


###############################################################################
# BEGIN TEMPORARY CLEANUP — REMOVE AFTER RUNNING ON ALL EXISTING PIS
###############################################################################

# Restore the manually changed Storage line in the main configuration.
# Keep a one-time backup and preserve all other settings and comments.
JOURNAL_MAIN="/etc/systemd/journald.conf"

if [[ -f "$JOURNAL_MAIN" ]]
then
    if [[ ! -e "${JOURNAL_MAIN}.before-pi-kiosk" ]]
    then
        sudo cp -a "$JOURNAL_MAIN" "${JOURNAL_MAIN}.before-pi-kiosk" || {
            echo "ERROR: Failed to back up $JOURNAL_MAIN to ${JOURNAL_MAIN}.before-pi-kiosk. Exiting." >&2
            exit 1
        }
    fi

    sudo sed -i -E \
        's/^[[:space:]]*Storage[[:space:]]*=[[:space:]]*persistent[[:space:]]*$/#Storage=auto/' \
        "$JOURNAL_MAIN" || {
            echo "ERROR: Failed to reset the Storage setting in $JOURNAL_MAIN. Exiting." >&2
            exit 1
        }
fi

# END TEMPORARY CLEANUP


###############################################################################
# KEEP THIS SECTION — Persistent Journal Configuration
###############################################################################

echo "Configuring persistent journal storage..."

sudo install -d -m 755 /etc/systemd/journald.conf.d || {
    echo "ERROR: Failed to create or set permissions on /etc/systemd/journald.conf.d. Exiting." >&2
    exit 1
}

if ! sudo tee /etc/systemd/journald.conf.d/90-local-journal.conf >/dev/null <<'JOURNAL_CONFIG'
[Journal]
Storage=persistent
MaxRetentionSec=30day
MaxFileSec=1day
SystemMaxUse=1G
JOURNAL_CONFIG
then
    echo "ERROR: Failed to write /etc/systemd/journald.conf.d/90-local-journal.conf. Exiting." >&2
    exit 1
fi

sudo chmod 644 /etc/systemd/journald.conf.d/90-local-journal.conf || {
    echo "ERROR: Failed to set permissions on /etc/systemd/journald.conf.d/90-local-journal.conf. Exiting." >&2
    exit 1
}

sudo systemctl restart systemd-journald.service || {
    echo "ERROR: Failed to restart systemd-journald.service. Exiting." >&2
    exit 1
}

sudo journalctl --flush || {
    echo "ERROR: Failed to flush the runtime journal to persistent storage. Exiting." >&2
    exit 1
}

sudo journalctl --sync || {
    echo "ERROR: Failed to synchronize pending journal writes to storage. Exiting." >&2
    exit 1
}

echo "Persistent journal configured: 30-day retention, with a 1 GiB size budget."


#Ask To Reboot
echo "
Kindly reboot my good sir(:"
