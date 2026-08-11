#!/bin/bash

# THE Pi KIOSK BASH SETUP SCRIPT
# Version 3.0
#
# Meant to be run on a freshly set up Raspberry Pi 5 running Raspberry Pi OS (64-bit)

#Remove Chrome and FireFox
sudo apt -y purge chromium firefox && sudo apt -y autoremove

#Upgrade Packages
sudo apt -y update && sudo apt -y full-upgrade

#Install Packages
sudo apt -y install firefox-esr

#Enable Desktop Auto Boot/Login (without a password) 
sudo raspi-config nonint do_boot_behaviour B4

#Turn Off Screen Auto Blanking
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

#Ask To Reboot
echo "
Kindly reboot my good sir(:"
