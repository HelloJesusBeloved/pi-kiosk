This script is basically the paper trail of the commands I used to change the settings on the Raspberry Pi 5 running default Raspberry Pi OS 64-bit to the correct ones that I needed for it to function the way I wanted it to to make it into a kiosk that displays a website. As I figured out what settings I needed to change to make that work, I used ChatGPT to discover what commands changed those settings, and added them to the list of this script so that I could run it on the rest of the Pi's I was going to setup, instead of running the commands and changing the settings individually on each. I made the-ultimate-raspberry-pi-announcement-tv-setup.sh before I ever planned to make this repo(or knew how to use git for that matter lol), so currently it is not clone and play, but I plan to make it so.


Disclaimer: the-ultimate-raspberry-pi-announcement-tv-setup.sh was originally made for a different directory structure, and does not have all the updated scripts in it yet, so it is not ready to use out of the box. Additionally, it is not yet fully idempotent.


◽THE OLD STEPS 

(I mainly have these here because I want to save them somewhere)
(This was for before I was using git lol)

1. Install magic-wormhole

2. Transfer the Setup tar from work computer to the Pi

3. Make the setup.sh script executable run it and reboot

4.  Move/merge everything inside into the .mozilla/firefox/"generated-string-of-letters-and-numbers".default-esr

REMAKE MAIN and FIREFOX TAR

https://addons.mozilla.org/en-US/firefox/addon/tab-auto-refresh/
