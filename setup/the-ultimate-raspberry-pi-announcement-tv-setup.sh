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

CRON_JOBS=(
    "0 2 * * * root apt update && apt full-upgrade -y && reboot"
    "@reboot root /usr/sbin/iw dev wlan0 set power_save off"
)

ALIASES=(
    "alias mouse='$REPO_ROOT/hide-cursor/cursor-toggle.sh'"
    "alias mousee='$REPO_ROOT/hide-cursor/cursor-toggle.sh && exit'"
)

ALIASES_TO_REMOVE=(
    "alias mouse='$HOME/Setup/cursor-toggle.sh'"
    "alias mousee='$HOME/Setup/cursor-toggle.sh && exit'"
)

#The image in the $WALLPAPER directory will be set as the Raspberry Pi's desktop wallpaper
WALLPAPER="$REPO_ROOT/assets/wallpaper"
SET_WALLPAPER="$(find "$WALLPAPER" -maxdepth 1 -type f -print -quit)"

SCRIPTS_TO_MAKE_EXECUTABLE=(
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

#Add Aliases
for alias in "${ALIASES[@]}"
do
    if ! grep -Fxq "$alias" "$HOME/.bashrc"
    then
        echo "$alias" >> "$HOME/.bashrc"
    fi
done

#Remove my old alias's (does nothing if you don't have them)
for alias in "${ALIASES_TO_REMOVE[@]}"
do
    sed -i "\|^${alias}$|d" "$HOME/.bashrc"
done

#Make necessary scripts executable
for script in "${SCRIPTS_TO_MAKE_EXECUTABLE[@]}"
do
    chmod +x "$script"
done

#Run the hide-cursor scripts once to install the neccessarry dependencies
$REPO_ROOT/hide-cursor/cursor-show.sh
$REPO_ROOT/hide-cursor/cursor-hide.sh

#Make the Desktop Config File and Hide The Wastebin and Set Fairmount Wallpaper
mkdir -p ~/.config/pcmanfm/default
if [ ! -f ~/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf ]; then
    cp /etc/xdg/pcmanfm/default/desktop-items-0.conf ~/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf 2>/dev/null || true
fi
sed -i 's|show_trash=1|show_trash=0|' $HOME/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf
sed -i "s|wallpaper=.*|wallpaper=$SET_WALLPAPER|" $HOME/.config/pcmanfm/default/desktop-items-HDMI-A-1.conf

#Ask To Reboot
echo "
Kindly reboot my good sir(:"
