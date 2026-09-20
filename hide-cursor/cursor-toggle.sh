#!/bin/bash


# Find the directory containing this script so hide/show work both from the
# repository and from ~/.local/bin/pi-kiosk after install.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"


if grep -q "^XCURSOR_THEME=Invisible" ~/.config/labwc/environment 2>/dev/null; then
    "$SCRIPT_DIR/cursor-show.sh"
else
    "$SCRIPT_DIR/cursor-hide.sh"
fi
