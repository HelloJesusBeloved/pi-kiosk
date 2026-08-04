#!/bin/bash

if grep -q "^XCURSOR_THEME=Invisible" ~/.config/labwc/environment 2>/dev/null; then
    $HOME/Setup/cursor-show.sh
else
    $HOME/Setup/cursor-hide.sh
fi
