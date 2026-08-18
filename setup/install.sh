#!/bin/bash


set -e


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


SCRIPTS_TO_RUN=(
    "$REPO_ROOT/setup/the-ultimate-raspberry-pi-announcement-tv-setup.sh"
    "$REPO_ROOT/setup/install-firefox-kiosk-and-network-watchdog.sh"
    "$REPO_ROOT/setup/install-network-watchdog-summary.sh"
)


#Make scripts executable and run them
for script in "${SCRIPTS_TO_RUN[@]}"
do
    chmod +x "$script"
    "$script"
done


