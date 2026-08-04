#!/bin/bash



# Give the user permission to restart Network Manager so that the Network Watchdog User Script can
user_NetworkManager_restart() {

# The user to grant permission to.
# By default, uses the user who invoked sudo.
# Override by setting WATCHDOG_USER before running the script.
WATCHDOG_USER="${WATCHDOG_USER:-${SUDO_USER:-$(whoami)}}"

SUDOERS_FILE="/etc/sudoers.d/pi-watchdog"
SYSTEMCTL="$(command -v systemctl)"

# Must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Ensure the target user exists.
if ! id "$WATCHDOG_USER" >/dev/null 2>&1; then
    echo "User '$WATCHDOG_USER' does not exist."
    exit 1
fi

# Ensure systemctl exists.
if [[ -z "$SYSTEMCTL" ]]; then
    echo "systemctl not found."
    exit 1
fi

echo "Configuring passwordless NetworkManager restart..."

cat > "$SUDOERS_FILE" <<EOF
$WATCHDOG_USER ALL=(root) NOPASSWD: $SYSTEMCTL restart NetworkManager
EOF

# sudo requires sudoers files to have these permissions.
chmod 0440 "$SUDOERS_FILE"

# Validate before keeping the file.
if ! visudo -cf "$SUDOERS_FILE" >/dev/null; then
    rm -f "$SUDOERS_FILE"
    echo "ERROR: sudoers file validation failed."
    exit 1
fi

}


user_NetworkManager_restart
