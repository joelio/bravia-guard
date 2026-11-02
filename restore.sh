#!/bin/sh
# Put everything back exactly as it shipped. Reverses disable.sh (including --ads).
# Usage: BRAVIA_ADDR=192.168.x.x:5555 ./restore.sh
set -e
DIR=$(cd "$(dirname "$0")" && pwd); . "$DIR/config.sh"
ensure_connected || { echo "Cannot reach $TV." >&2; exit 1; }

echo "Restoring on $TV"
for p in $REMOVE_PKGS; do adb_tv shell "cmd package install-existing $p" 2>&1 | tr -d '\r'; done
for p in $DISABLE_PKGS $REMOVE_PKGS $ADS_PKGS; do adb_tv shell "pm enable $p" 2>&1 | tr -d '\r'; done
echo "Restored. Reboot the TV to return fully to stock behaviour."
