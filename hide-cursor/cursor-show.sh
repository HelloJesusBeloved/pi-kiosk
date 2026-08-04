#!/bin/bash
# Restore the default visible mouse cursor on labwc
# Source: Claude
set -e

mkdir -p ~/.config/labwc
touch ~/.config/labwc/environment

# Remove the Invisible theme overrides; labwc falls back to the system default (PiXflat)
sed -i '/^XCURSOR_THEME=/d; /^XCURSOR_SIZE=/d' ~/.config/labwc/environment

echo "Cursor set to VISIBLE (system default theme)."
echo "Restarting labwc to apply..."
labwc -r 2>/dev/null || pkill -HUP labwc || echo "Could not signal labwc — reboot manually."
