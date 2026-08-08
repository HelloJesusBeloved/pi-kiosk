## DISCLAIMER:
Code written mostly by ChatGPT, while I decided the final logic of the code, and put together and tested every line. Currently in development. 

Hello my good Jesus beloved human bean who so happens to be reading this(: This is a collection of bash scripts and systemd user services that manage those scripts, that when put together and setup create what I like to call, The Ultimate Raspberry Pi Kiosk Setup 😎.

This is not here because I necessarily want to share it, YET (not because I don't want to share it, I most certainly do, but because it is not finished yet), it is mainly here to have a cloud backup that I can also easily pull to my other Pi's.

If you have any questions, suggestions, comments, literally just want to say hi(: please feel free to create an "Issue" and let me know! ☺️ Idk why git doesn't have just a comment option or a discussion option by default lol, if you know how to add that to a Forgejo repo then create an "Issue" and let me know about that too!

Made for the Raspberry Pi 5, running Raspberry Pi OS (64-bit) and Wayland. May work on other Pi's running Wayland, but not tested.

Below is written almost entirely by ChatGPT, tho I plan to make it better.

◽Services:

firefox-kiosk.service

Purpose:
    Controls and Auto-Starts Firefox(via running/managing firefox-kisok.sh), including restarting it if closed or crashed.

network-watchdog.service

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
