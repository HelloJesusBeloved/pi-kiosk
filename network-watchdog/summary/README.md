📊 Daily Network Watchdog Summary

<pre>
network-watchdog-summary.timer
            │
            ▼
network-watchdog-summary.service
            │
            ▼
read state file
            │
            ▼
send daily summary
            │
            ▼
central ntfy topic
</pre>

## About

### 1. ~/.local/bin/network-watchdog-summary.sh

- **Purpose:** 
read configuration
        ↓
check SUMMARY_ENABLED
        ↓
read state file
        ↓
get hostname
        ↓
build summary
        ↓
POST to central ntfy topic
        ↓
exit


### 2. ~/.config/systemd/user/network-watchdog-summary.service

To run a manual summary: systemctl --user start network-watchdog-summary.service

### 3. ~/.config/systemd/user/network-watchdog-summary.timer

The .timer runs the .service at the correct time, which runs the .sh which runs the ntfy commands to send the summary

Check timer status: systemctl --user list-timers network-watchdog-summary.timer


.timer
   │
   │ "WHEN should this happen?"
   ▼
.service
   │
   │ "WHAT should happen?"
   ▼
network-watchdog-summary.sh



## Current Architecture

                    systemd user instance
                           │
             ┌─────────────┼─────────────┐
             │             │             │
             ▼             ▼             ▼
      firefox-kiosk   network-watchdog   summary.timer
          .service          .service          │
             │                │               │
             ▼                ▼               ▼
      firefox-kiosk.sh  network-watchdog.sh  summary.service
                                              │
                                              ▼
                                      summary.sh
