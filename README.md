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

- **Status:** Not Ready
- **Disclaimer:** the-ultimate-raspberry-pi-announcement-tv-setup.sh has not been modified to work with this repositories directory structure, so it is not ready to use out of the box YET. Additionally, it is not yet fully idempotent.

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

Ending File Structure:

`$HOME/.config/systemd/user/`
`firefox-kiosk.service`
`network-watchdog.service`

`$HOME/.local/bin/`
`firefox-kiosk.sh`
`network-watchdog.sh`

`#HOME/.local/share/pi-kiosk/`
`network-watchdog.state`
