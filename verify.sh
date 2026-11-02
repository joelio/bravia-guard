#!/bin/sh
# verify.sh - watch who the TV talks to, without root and without a tap.
# Reads the TV's own /proc/net socket tables over ADB (no packet capture needed, and
# none is possible without root), decodes them, and maps each connection to the app
# that owns it. You see destinations, not payloads (those are TLS anyway).
#
# Usage: BRAVIA_ADDR=192.168.x.x:5555 ./verify.sh [seconds]   (default 20)
set -e
DIR=$(cd "$(dirname "$0")" && pwd); . "$DIR/config.sh"
SECS="${1:-20}"
ensure_connected || { echo "Cannot reach $TV." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 required for decoding." >&2; exit 1; }

echo "Mapping packages and polling /proc for ${SECS}s on $TV ..."
MAP=$(mktemp); SOCK=$(mktemp); trap 'rm -f "$MAP" "$SOCK"' EXIT
adb_tv shell "pm list packages -U" 2>/dev/null | tr -d '\r' > "$MAP"
i=0; while [ "$i" -lt "$SECS" ]; do
  adb_tv shell "cat /proc/net/tcp /proc/net/tcp6 2>/dev/null" 2>/dev/null | tr -d '\r' >> "$SOCK"
  i=$((i+1)); sleep 1
done

MAP="$MAP" SOCK="$SOCK" python3 -I - <<'PY'
import os,re,ipaddress,socket
uid2pkg={}
for ln in open(os.environ['MAP']):
    m=re.search(r'package:(\S+)\s+uid:(\d+)',ln)
    if m: uid2pkg[int(m.group(2))]=m.group(1)
def ip(hx):
    b=bytes.fromhex(hx)
    if len(b)==4: return str(ipaddress.IPv4Address(bytes(reversed(b))))
    w=[b[i:i+4] for i in range(0,16,4)]
    return str(ipaddress.IPv6Address(b''.join(bytes(reversed(x)) for x in w)))
seen=set()
for ln in open(os.environ['SOCK']):
    f=ln.split()
    if len(f)<10 or f[0]=='sl': continue
    try: rem,st,uid=f[2],f[3],int(f[7])
    except: continue
    if st!='01': continue                     # ESTABLISHED only
    h,p=rem.split(':'); rip=ip(h); rport=int(p,16)
    try:
        ia=ipaddress.ip_address(rip)
        if ia.is_private or ia.is_loopback or ia.is_link_local or ia.is_unspecified: continue
    except: continue
    seen.add((uid2pkg.get(uid,'uid%d'%uid),rip,rport))
def ptr(a):
    try: return socket.gethostbyaddr(a)[0]
    except: return ''
print("\n%-40s %-42s %s" % ("package","endpoint","reverse-dns"))
for pkg,rip,rport in sorted(seen):
    flag=' <== ACR/telemetry' if re.search(r'samba|idd|interactivetv',pkg,re.I) else ''
    print("%-40s %-42s %s%s" % (pkg, rip+':'+str(rport), ptr(rip), flag))
hits=[x for x in seen if re.search(r'samba|idd|interactivetv',x[0],re.I)]
print("\n%d external endpoints; %d owned by the ACR/telemetry stack." % (len(seen), len(hits)))
print("CLEAN: nothing ACR-shaped is talking out." if not hits else "WARNING: ACR/telemetry is reaching out. Run ./disable.sh")
PY
