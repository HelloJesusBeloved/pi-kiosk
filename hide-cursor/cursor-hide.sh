#!/bin/bash
# Make the mouse cursor invisible on labwc (Raspberry Pi OS Trixie / Wayland)
# Source: Claude
set -e

# 1. Build the Invisible theme if it doesn't already exist
if [ ! -f /usr/share/icons/Invisible/cursors/left_ptr ]; then
    echo "Building Invisible cursor theme..."
    sudo apt install -y imagemagick x11-apps

    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    convert -size 1x1 xc:none 1x1.png
    echo "1 0 0 1x1.png" > transparent.cfg
    xcursorgen transparent.cfg transparent

    sudo mkdir -p /usr/share/icons/Invisible/cursors
    for name in left_ptr default arrow hand hand1 hand2 pointer xterm text \
                watch wait crosshair help question_arrow top_left_arrow \
                sb_h_double_arrow sb_v_double_arrow fleur; do
        sudo cp transparent /usr/share/icons/Invisible/cursors/$name
    done

    sudo tee /usr/share/icons/Invisible/index.theme > /dev/null <<'EOF'
[Icon Theme]
Name=Invisible
Comment=Fully transparent cursors
Inherits=PiXflat
EOF

    cd ~ && rm -rf "$TMPDIR"
fi

# 2. Point labwc at the Invisible theme
mkdir -p ~/.config/labwc
touch ~/.config/labwc/environment

# Remove any existing XCURSOR_* lines, then add ours
sed -i '/^XCURSOR_THEME=/d; /^XCURSOR_SIZE=/d' ~/.config/labwc/environment
echo "XCURSOR_THEME=Invisible" >> ~/.config/labwc/environment
echo "XCURSOR_SIZE=1"          >> ~/.config/labwc/environment

echo "Cursor set to INVISIBLE."
echo "Restarting labwc to apply..."
labwc -r 2>/dev/null || pkill -HUP labwc || echo "Could not signal labwc — reboot manually."
