## DISCLAIMER:
Code written mostly by ChatGPT, while I decided the final logic of the code, and put together and tested every line. Currently in development. 

## About
Hello my good Jesus beloved human bean who so happens to be reading this(: This is a collection of bash scripts and systemd user services that manage those scripts, that when put together and setup create what I like to call, The Ultimate Raspberry Pi Kiosk Setup 😎.

This is not here because I necessarily want to share it, YET (not because I don't want to share it, I most certainly do, but because it is not finished yet), it is mainly here to have a cloud backup that I can also easily pull to my other Pi's.

If you have any questions, suggestions, comments, literally just want to say hi(: please feel free to create an "Issue" and let me know! ☺️ Idk why git doesn't have just a comment option or a discussion option by default lol, if you know how to add that to a Forgejo repo then create an "Issue" and let me know about that too!

Made for the Raspberry Pi 5, running Raspberry Pi OS (64-bit) and Wayland. May work on other Pi's running Wayland, but not tested.



### 1. the-ultimate-raspberry-pi-announcement-tv-setup.sh

- **Location:** pi-kiosk/setup
- **Purpose:** Setup the Raspberry Pi 5 with all the correct settings to make it into a kiosk. (Install the correct browser, turn off screen blanking, make the taskbar auto-hide, make it update and reboot nightly, that sort of thing)
- **Status:** Not ready
- <details>
    <summary><b>Full Explanation</b></summary>
    This script is basically the paper trail of the commands I used to change the settings on the Raspberry Pi 5 running default Raspberry Pi OS 64-bit to the correct ones that I needed for it to function the way I wanted it to to make it into a kiosk that displays a website. As I figured out what settings I needed to change to make that work, I used ChatGPT to discover what commands changed those settings, and added them to the list of this script so that I could run it on the rest of the Pi's I was going to setup, instead of running the commands and changing the settings individually on each. I made the-ultimate-raspberry-pi-announcement-tv-setup.sh (aka turpats) before I ever planned to make this repo (or knew how to use git for that matter lol), so currently it is not clone and play, but I plan to make it so.

    Disclaimer: the-ultimate-raspberry-pi-announcement-tv-setup.sh was originally made for a different directory structure, and does not have all the updated scripts in it yet, so it is not ready to use out of the box. Additionally, it is not yet fully idempotent.
</details>


<br>
### 2. firefox-kiosk.service

Purpose:
    Controls and Auto-Starts Firefox(via running/managing firefox-kisok.sh), including restarting it if closed or crashed.


<br>
### 3. network-watchdog.service

Purpose:
    Keeps networking alive. Checks, and Repairs if Needed


◽Useful Commands

Start Firefox Autostart Service

systemctl --user start firefox-kiosk.service

Stop Firefox Autostart Service

systemctl --user stop firefox-kiosk.service

Restart Firefox Autostart Service

systemctl --user restart firefox-kiosk.service


◽View Logs:

Firefox

journalctl -t firefox-kiosk

Firefox live

journalctl -t firefox-kiosk -f

Watchdog

journalctl -t network-watchdog


◽Files:

~/.config/systemd/user/

firefox-kiosk.service
network-watchdog.service

~/.local/bin/

firefox-kiosk.sh
network-watchdog.sh

~/.local/share/pi-kiosk/

network-watchdog.state


◽Troubleshooting:

If Firefox says

Error:
no DISPLAY environment variable specified

Check:

DISPLAY
WAYLAND_DISPLAY

The service should include

Environment=DISPLAY=:0
Environment=WAYLAND_DISPLAY=wayland-0
Environment=XDG_RUNTIME_DIR=/run/user/1000
