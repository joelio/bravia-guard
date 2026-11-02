#!/bin/sh
# Shared config for the bravia-guard scripts. Sourced by the others.
# Edit the package lists here if your model differs (see packages.md).

ADB="${ADB_BIN:-adb}"

# REQUIRED: your TV's ADB address. Find the TV's IP in its network settings, then:
#   export BRAVIA_ADDR=192.168.x.x:5555
if [ -z "${BRAVIA_ADDR:-}" ]; then
  echo "BRAVIA_ADDR is not set." >&2
  echo "  export BRAVIA_ADDR=192.168.1.50:5555   # your TV's IP, port 5555" >&2
  exit 2
fi
TV="$BRAVIA_ADDR"

# Disabled with 'pm disable-user' (these stay down across reboots):
#   tv.samba.ssm                 Samba TV ACR engine
#   com.sonyericsson.idd.agent   Sony usage-telemetry agent
DISABLE_PKGS="${DISABLE_PKGS:-tv.samba.ssm com.sonyericsson.idd.agent}"

# Removed with 'pm uninstall --user 0'. These are PERSISTENT, PRIVILEGED system apps:
# while allowed to run they re-enable Samba on boot, so disabling is not enough,
# they have to be removed for the user. Reversible with 'cmd package install-existing'.
#   com.sony.dtv.interactivetvutil(.output)   Sony's "Samba Interactive TV" wrapper
REMOVE_PKGS="${REMOVE_PKGS:-com.sony.dtv.interactivetvutil com.sony.dtv.interactivetvutil.output}"

adb_tv() { $ADB -s "$TV" "$@"; }

ensure_connected() {
  $ADB connect "$TV" >/dev/null 2>&1
  adb_tv get-state 2>/dev/null | grep -q device
}
