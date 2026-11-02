#!/bin/sh
# Disable Samba TV ACR + Sony telemetry on a Sony Bravia. Reversible (see restore.sh).
# Usage: BRAVIA_ADDR=192.168.x.x:5555 ./disable.sh [--dry-run]
set -e
DIR=$(cd "$(dirname "$0")" && pwd); . "$DIR/config.sh"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

run() {
  if [ "$DRY" = 1 ]; then echo "+ adb -s $TV shell $*"
  else adb_tv shell "$@" 2>&1 | tr -d '\r'; fi
}

ensure_connected || { echo "Cannot reach $TV. TV on? Network ADB enabled and this host authorised?" >&2; exit 1; }

echo "Disabling ACR + telemetry on $TV"
for p in $DISABLE_PKGS; do
  echo "  disable-user $p"; run "pm disable-user --user 0 $p"; run "am force-stop $p"
done
echo "Removing persistent wrapper for user 0 (this is what makes the kill stick)"
for p in $REMOVE_PKGS; do
  echo "  uninstall --user 0 $p"; run "pm uninstall --user 0 $p"
done
echo "Done. Check it with ./verify.sh, undo it with ./restore.sh."
