#!/bin/bash



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



if grep -q "^XCURSOR_THEME=Invisible" ~/.config/labwc/environment 2>/dev/null; then
    $REPO_ROOT/hide-cursor/cursor-show.sh
else
    $REPO_ROOT/hide-cursor/cursor-hide.sh
fi
