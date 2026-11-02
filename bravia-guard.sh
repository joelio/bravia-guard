#!/bin/sh
# bravia-guard.sh
# Keeps the ACR + telemetry stack disabled. Re-applies if anything (e.g. a firmware
# update, or the privileged wrapper restarting) brings it back. Safe to run repeatedly;
# it only acts when something has actually changed. Designed for cron / launchd / a timer.
#
# Usage: BRAVIA_ADDR=192.168.x.x:5555 ./bravia-guard.sh [--dry-run]
DIR=$(cd "$(dirname "$0")" && pwd); . "$DIR/config.sh"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
LOG="${BRAVIA_LOG:-$HOME/.bravia-guard.log}"
# NOTIFY_URL="https://ntfy.sh/pick-a-secret-topic"   # optional: ping on a re-apply

log()    { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$1" >> "$LOG"; }
notify() { [ -n "${NOTIFY_URL:-}" ] && command -v curl >/dev/null 2>&1 && curl -fsS -d "$1" "$NOTIFY_URL" >/dev/null 2>&1; }
act()    { if [ "$DRY" = 1 ]; then echo "+ adb -s $TV shell $*"; else adb_tv shell "$@" >/dev/null 2>&1; fi; }

ensure_connected || { log "UNREACHABLE $TV (TV off, or ADB disabled/unauthorised)"; exit 1; }

changed=0
for p in $DISABLE_PKGS; do
  state=$(adb_tv shell "dumpsys package $p | grep -m1 'enabled='" 2>/dev/null | tr -d '\r' | grep -oE 'enabled=[0-9]')
  case "$state" in
    enabled=2|enabled=3) : ;;                       # disabled by user, good
    "")                  log "ABSENT $p" ;;          # not on this set
    *)                   act "pm disable-user --user 0 $p"; act "am force-stop $p"
                         log "RE-DISABLED $p (was $state)"; changed=1 ;;
  esac
done
for p in $REMOVE_PKGS; do
  if adb_tv shell "pm list packages --user 0 $p" 2>/dev/null | tr -d '\r' | grep -qx "package:$p"; then
    act "pm uninstall --user 0 $p"; log "RE-REMOVED $p (reappeared for user 0)"; changed=1
  fi
done

if [ "$changed" = 1 ]; then
  log "ACTION taken - something re-enabled the ACR/telemetry stack (firmware update?)"
  notify "bravia-guard: re-disabled Samba/telemetry on $TV"
else
  log "OK - still disabled, nothing to do"
fi
adb_tv disconnect "$TV" >/dev/null 2>&1 || true
exit 0
