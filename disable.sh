#!/bin/sh
# Disable Samba TV ACR + Sony telemetry on a Sony Bravia. Reversible (see restore.sh).
# Usage: BRAVIA_ADDR=192.168.x.x:5555 ./disable.sh [--dry-run] [--ads]
#   --dry-run  print the commands, change nothing
#   --ads      also disable the optional ad/promo/profiling packages (ADS_PKGS)
set -e
DIR=$(cd "$(dirname "$0")" && pwd); . "$DIR/config.sh"

DRY=0; ADS=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --ads)     ADS=1 ;;
    *) echo "unknown argument: $a" >&2; exit 2 ;;
  esac
done

run() {
  if [ "$DRY" = 1 ]; then echo "+ adb -s $TV shell $*"
  else adb_tv shell "$@" 2>&1 | tr -d '\r'; fi
}

[ "$DRY" = 1 ] || ensure_connected || { echo "Cannot reach $TV. TV on? Network ADB enabled and this host authorised?" >&2; exit 1; }

echo "Disabling ACR + telemetry on $TV"
for p in $DISABLE_PKGS; do
  echo "  disable-user $p"; run "pm disable-user --user 0 $p"; run "am force-stop $p"
done

echo "Removing persistent wrapper for user 0 (this is what makes the kill stick)"
for p in $REMOVE_PKGS; do
  echo "  uninstall --user 0 $p"; run "pm uninstall --user 0 $p"
done

if [ "$ADS" = 1 ]; then
  echo "Disabling ad / promo / profiling packages (--ads)"
  for p in $ADS_PKGS; do
    echo "  disable-user $p"; run "pm disable-user --user 0 $p"; run "am force-stop $p"
  done
fi

echo "Done. Check it with ./verify.sh, undo it with ./restore.sh."
