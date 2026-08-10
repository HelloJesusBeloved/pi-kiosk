This folder is mainly usefull to me, since It contains what I am using to remove the old setup I had for the Pi's, and replace it with the updated one. 
I used to use an autostart desktop entry script to setup a file, like this:

```shell
#Make the FireFox autostart path and config file
mkdir -p $HOME/.config/autostart
echo "[Desktop Entry]
Type=Application
Exec=firefox-esr
Hidden=false
X-GNOME-Autostart-enabled=true
Name=Firefox ESR" > $HOME/.config/autostart/firefox.desktop
```

that would auto launch Firefox for me on boot, and I used that to setup all 4 of my Pi's I had. However, that was not consistent, and would sometimes launch firefox before it had properly connected to the network, so it would just load a connection error page, so now I am making a simple script to move that desktop entry file out of the autostart folder, and install the new firefox-kiosk and network-watchdog(:
