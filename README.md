DISCLAIMER:
Code written mostly by ChatGPT, while I put together the code and decided the final logic. Currently in development. Made for the Raspberry Pi 5, Debian 13 (Trixie), Wayland. May work on other Pi's running Wayland, but not tested.

Also, this is not here because I neccessarily want to share it YET, it is mainly here to have a cloud backup that I can also easily pull to my other Pi's.

Below is written entirely by ChatGPT, tho I plan to make it better.
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
