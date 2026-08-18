## DISCLAIMER:
Code written mostly by ChatGPT, while I decided the final logic of the code, and put together and tested every line. Currently in development. 

## Introduction
Hello my good Jesus beloved human bean who so happens to be reading this(: This is a collection of bash scripts and systemd user services that manage those scripts, that when put together and setup create what I like to call, The Ultimate Raspberry Pi Kiosk Setup 😎.

This is not here because I necessarily want to share it, YET (not because I don't want to share it, I most certainly do, but because it is not finished yet), it is mainly here to have a cloud backup that I can also easily pull to my other Pi's.

If you have any questions, suggestions, comments, literally just want to say hi(: please feel free to create an "Issue" and let me know! ☺️ Idk why git doesn't have just a comment option or a discussion option by default lol, if you know how to add that to a Forgejo repo then create an "Issue" and let me know about that too!

Made for the Raspberry Pi 5, running Raspberry Pi OS (64-bit) and Wayland. May work on other Pi's running Wayland, but not tested.


## About

### 1. the-ultimate-raspberry-pi-announcement-tv-setup.sh

- **Location:** pi-kiosk/setup
- **Purpose:** Setup the Raspberry Pi 5 with all the correct settings to make it into a kiosk. (Install the correct browser, turn off screen blanking, make the taskbar auto-hide, make it update and reboot nightly, that sort of thing)
- <details>
    <summary><b>Full Explanation</b></summary>
    This script is basically the paper trail of the commands I used to change the settings on the Raspberry Pi 5 running default Raspberry Pi OS 64-bit to the correct ones that I needed for it to function the way I wanted it to to make it into a kiosk that displays a website. As I figured out what settings I needed to change to make that work, I used ChatGPT to discover what commands changed those settings, and added them to the list of this script so that I could run it on the rest of the Pi's I was going to setup, instead of running the commands and changing the settings individually on each. I made the-ultimate-raspberry-pi-announcement-tv-setup.sh (aka turpats) before I ever planned to make this repo (or knew how to use git for that matter lol), so currently it is not clone and play, but I plan to make it so.
</details>

- **Status:** Ready

### 2. firefox-kiosk.service

- **Purpose:** Controls and Auto-Starts Firefox (via running/managing firefox-kisok.sh), including logging, restarting it if closed or crashed, and making sure the display website is reachable before it launches.
- **Logs:** 
(add -f for live)
```shell
journalctl -t firefox-kiosk
```
- **Control:** 
`systemctl --user start/stop/restart firefox-kiosk.service`
- **Status:** Ready


### 3. network-watchdog.service

- **Purpose:** Keep networking alive. Periodically checks connection, if disconnected verifys disconnection, if verified goes through 3 automatic troubleshooting steps: WiFi disconnect/reconnect, Network Manger restart, and finally full system reboot.
<details>
<summary><b>Flow Diagram</b></summary>

<pre>
                         ┌─────────────────────────┐
                         │     Program Starts      │
                         └────────────┬────────────┘
                                      │
                                      ▼
                            initialize_state()
                                      │
                                      ▼
                               load_state()
                                      │
                                      ▼
                              log_startup()
                                      │
                                      ▼
                         collect_network_state()
                                      │
                                      ▼
                         build_network_state()
                                      │
                                      ▼
                            log_network_state                               
                                      │
                                      ▼
                              main_loop()
                                      │
          ┌───────────────────────────┴───────────────────────────────┐
          │                                                           │
          │                    EVERY 60 SECONDS                       │
          │                                                           │
          ▼                                                           │
    collect_network_state()                                           │
          │                                                           │
          ▼                                                           │
    build_network_state()                                             │
          │                                                           │
          ▼                                                           │
    evaluate_network_health()                                         │
          │                                                           │
          ▼                                                           │
    classify_network_incident()                                       │
          │                                                           │
          ▼                                                           │
    network_state_changed()?                                          │
          │             │                                             │
         YES            NO                                            │
          │             │                                             │
          ▼             │                                             │
    log_network_state() │                                             │
       │                │                                             │
       └──────┬─────────┘                                             │
              │                                                       │
              ▼                                                       │
       recover_network()                                              │
              │                                                       │
              ▼                                                       │
       Network HEALTHY?                                               │
          │          │                                                │
         YES         NO                                               │
          │          │                                                │
          │          ▼                                                │
          │   Recovery already active?                                │
          │          │          │                                     │
          │         YES         NO                                    │
          │          │          │                                     │
          │          │          ▼                                     │
          │          │   RECOVERY_ACTIVE=true                         │
          │          │          │                                     │
          │          │          ▼                                     │
          │          │     verify_failure()                           │
          │          │          │                                     │
          │          │          ▼                                     │
          │          │   ┌────────────────────┐                       │
          │          │   │ Recheck network    │                       │
          │          │   │ up to N times      │                       │
          │          │   │ with delay between │                       │
          │          │   │ each confirmation  │                       │
          │          │   └──────────┬─────────┘                       │
          │          │              │                                 │
          │          │       ┌──────┴──────┐                          │
          │          │       │             │                          │
          │          │    HEALTHY      STILL BAD                      │
          │          │       │             │                          │
          │          │       ▼             ▼                          │
          │          │    Cancel       Confirm                        │
          │          │    recovery      failure                       │
          │          │       │             │                          │
          │          │       │             ▼                          │
          │          │       │      Increment recovery                │
          │          │       │         counters                       │
          │          │       │             │                          │
          │          │       │             ▼                          │
          │          │       │    attempt_wifi_reconnect()            │
          │          │       │             │                          │
          │          │       │        ┌────┴────┐                     │
          │          │       │       YES       NO                     │
          │          │       │        │         │                     │
          │          │       │        ▼         ▼                     │
          │          │       │     SUCCESS  restart_networkmanager()  │
          │          │       │        │         │                     │
          │          │       │        │    ┌────┴────┐                │
          │          │       │        │   YES       NO                │
          │          │       │        │    │         │                │
          │          │       │        │    ▼         ▼                │
          │          │       │        │ SUCCESS  request_reboot()     │
          │          │       │        │    │         │                │
          │          │       │        │    │         ▼                │
          │          │       │        │    │  Consecutive reboots     │
          │          │       │        │    │       >= 3?              │
          │          │       │        │    │     │       │            │
          │          │       │        │    │    YES      NO           │
          │          │       │        │    │     │       │            │
          │          │       │        │    │     ▼       ▼            │
          │          │       │        │    │   DENY    Watchdog       │
          │          │       │        │    │   reboot  reboot flag    │
          │          │       │        │    │   Manual    == true?     │
          │          │       │        │    │   fix      │       │     │
          │          │       │        │    │           YES      NO    │
          │          │       │        │    │            │       │     │
          │          │       │        │    │            ▼       │     │
          │          │       │        │    │       Calculate    │     │
          │          │       │        │    │       elapsed time │     │
          │          │       │        │    │       since last   │     │
          │          │       │        │    │       watchdog     │     │
          │          │       │        │    │       reboot       │     │
          │          │       │        │    │            │       │     │
          │          │       │        │    │       < 5 minutes? │     │
          │          │       │        │    │          │     │   │     │
          │          │       │        │    │         YES    NO  │     │
          │          │       │        │    │          │     │   │     │
          │          │       │        │    │          ▼     │   │     │
          │          │       │        │    │        DENY    │   │     │
          │          │       │        │    │        reboot  │   │     │
          │          │       │        │    │                │   │     │
          │          │       │        │    │                └───┘     │
          │          │       │        │    │                  │       │
          │          │       │        │    └──────────────────┤       │
          │          │       │        │                       │       │
          │          │       │        │                       ▼       │
          │          │       │        │                Record reboot  │
          │          │       │        │                       │       │
          │          │       │        │                       ▼       │
          │          │       │        │                Save state     │
          │          │       │        │                  to disk      │
          │          │       │        │                       │       │
          │          │       │        │                       ▼       │
          │          │       │        │               systemctl reboot│
          │          │       │        │                               │
          │          │       │        │                               │
          │          │       │        └───────────────────────────────┘
          │          │       │
          │          │       └──────────────────────────────┐
          │          │                                      │
          │          └──────────────────────────────────────┤
          │                                                 │
          │                                                 ▼
          │                                      restart_firefox()
          │                                                 │
          │                                                 ▼
          │                                          Recovery ends
          │
          ▼
        sleep
          │
          ▼
      60 seconds
          │
          └──────────────────────────────────────────► main loop
</pre>

</details>

- **Logs:** 
(add -f for live)
```shell
journalctl -t network-watchdog
```
- **Control:** 
`systemctl --user start/stop/restart network-watchdog.service`
- **Status:** Ready

### 4. network-watchdog-summary.service

- **Purpose:** Send you a daily notification via ntfy containing a report of the state file stats. (if you don't care about logs you can ignore this)
<details>
<summary><b>Flow Diagram</b></summary>

<pre>
network-watchdog-summary.timer
 (timer set to run daily)
            │
            ▼
network-watchdog-summary.service
   (runs once, executing)
            │
            ▼
network-watchdog-summary.sh
         (which)
            │
            ▼
reads state file
            │
            ▼
send daily summary to central ntfy topic
</pre>

</details>

Basically the .timer runs the .service at the correct time, which runs the .sh which runs the ntfy commands to send the summary
- **Control:**  
To receive a summary manually:  
```bash
systemctl --user start network-watchdog-summary.service
```

To check timer status: 
```bash
systemctl --user list-timers network-watchdog-summary.timer
```


## Setup

1. **Hardware:** https://a.co/0gI0D6Un

2. **Download Raspberry Pi Imager:** https://www.raspberrypi.com/software/

## Install

(The terminal on a RaspberryPi 5 running Raspberry Pi OS (64-bit) can be opned by pressing super + enter (on Linux, the super button is the Windows key:)

1. **Download and Install The Ultimate Raspberry Pi Kiosk Setup 😎**
```bash
#Download and enter this repository
git clone https://git.nerdvpn.de/HelloJesusBeloved/pi-kiosk && cd pi-kiosk

#Make the install scripts executable
chmod +x ./setup/install-firefox-kiosk-and-network-watchdog.sh ./setup/the-ultimate-raspberry-pi-announcement-tv-setup.sh ./network-watchdog/summary/setup/install-network-watchdog-summary.sh

#Run the setup scripts
./setup/install-firefox-kiosk-and-network-watchdog.sh && ./setup/the-ultimate-raspberry-pi-announcement-tv-setup.sh && ./network-watchdog/summary/setup/install-network-watchdog-summary.sh
```

2. **Configure Firefox Settings and Extensions**  
    A. In Settings > Home set "Homepage and new windows" to the URL of the website you want the kiosk to display  
        Note: I don't enable "Open previous windows and tabs," so that it opens the website fresh each time.  

    B. Install these extensions:  
        - https://addons.mozilla.org/en-US/firefox/addon/autofullscreen/ (To automatically maxamize the website displayed)  
        - https://addons.mozilla.org/en-US/firefox/addon/tab-auto-refresh/ (To periodically refresh the website to pull new content if needed. I have mine set to refresh every hour (3600 seconds))  
        - https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/ (To hide browser elements with the element picker tool to make it look cleaner if needed)  
        Note: I have tried a fair few extensions, and these are the exact ones that have worked the best for me so far.  

    C. Turn Off Session Restore  
        - Type and enter about:config in the browser search bar, accept the risk (just means if you change the wrong settings you could mess things up), and search for the preference: browser.sessionstore.max_resumed_crashes, change from a 1 to a 0  
        Note: The reason to do this is because when the Pi restarts nightly, firefox obviously thinks that it crashed, and gives you a page with a button to click to restore your previous pages. Obviously we don't want that, we want it to simply start back up and go to the website.

    D. Adjust the zoom (with ctrl + or -), and use UBlock's element picker (I usually bind it to ctrl + alt + a - on the Extensions page, to the right of where it says "Manage Your Extensions," click the gear/settings icon > Manage Extension Shortcuts) to make the website how you would like it to look!

3. **Make Mouse Invisible**  
- To toggle the mouse's visibility, type and enter "mouse" in the terminal. To toggle the mouse and exit the terminal, type and enter "mousee"

### Ending File Structure:

<pre>
$HOME/.config/
└── systemd
    └── user
        ├── firefox-kiosk.service
        ├── network-watchdog.service
        ├── network-watchdog-summary.service
        └── network-watchdog-summary.timer
</pre>

<pre>
$HOME/.local
├── bin
│   ├── firefox-kiosk.sh
│   ├── network-watchdog.sh
│   └── network-watchdog-summary.sh
└── share
    └── pi-kiosk
        └── network-watchdog.state
</pre>

### Ending User Systemd Structure:

<pre>
                    systemd user instances
                              │
             ┌────────────────┼───────────────────────┐
             │                │                       │
             ▼                ▼                       ▼
      firefox-kiosk   network-watchdog   network-watchdog-summary.timer
          .service          .service                  │
             │                │                       │
             ▼                ▼                       ▼
      firefox-kiosk.sh  network-watchdog.sh  network-watchdog-summary.service
                                                      │
                                                      ▼
                                      network-watchdog-summary.sh
</pre>

