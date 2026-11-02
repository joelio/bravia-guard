# Locking down the ADB port

To let the guard keep running, network ADB stays on, which means `:5555` is listening on
the TV. It is not wide open: Android requires RSA key authorisation (`ro.adb.secure=1`), so
a host that hasn't been authorised on-screen gets `unauthorized` and no shell. Still, you may
want to narrow who can reach it. Two approaches. **You only need one, and #1 is enough for
most people.**

## 1. Rekey: trust exactly one client (no hardware)

This is the simplest real lock, and it enforces at the layer that actually matters.

1. On the TV: **Developer options → Revoke USB debugging authorisations.** This wipes the
   list of trusted keys.
2. From the one machine you want to allow (your admin box, or whatever runs
   `bravia-guard.sh`): `adb connect <tv-ip>:5555`, then accept the on-screen prompt with
   **"Always allow from this computer."**

Now one key, and only one, can open a shell. Anything else that touches `:5555` is refused
at the handshake. Re-run this any time you want to change which host is trusted.

## 2. Bridge firewall: restrict who can reach the port (defence in depth)

Worth knowing why the obvious thing doesn't work: on a flat subnet, devices talk to each
other directly through the switch, so a rule on your main router never sees traffic between
two LAN hosts and can't filter it. To firewall the port you have to put something in the
actual path.

If the TV is wired, an OpenWrt box makes a tidy inline **transparent bridge**: radios off
(so it isn't a second AP), both its LAN ports in `br-lan`, the TV on one and your switch on
the other. The TV keeps its existing IP and notices nothing, but every packet now crosses a
box where you are root. Filter the ADB port at L2:

```sh
# On the OpenWrt bridge. Replace TV_IP and GUARD_IP.
TV_IP=192.168.1.50
GUARD_IP=192.168.1.10          # the only host allowed to reach ADB

nft add table bridge adbguard
nft add chain bridge adbguard fwd '{ type filter hook forward priority -200 ; policy accept ; }'
nft add rule  bridge adbguard fwd meta protocol ip ip daddr $TV_IP tcp dport 5555 ip saddr != $GUARD_IP drop
```

Make it persist by putting those commands in `/etc/nftables.conf` (or a
`/etc/hotplug.d` / init script) so they survive a reboot.

Test it: from a host that is **not** `GUARD_IP`, `adb connect <tv-ip>:5555` should now time
out rather than prompt. From `GUARD_IP` it should connect as before.

The same bridge is also the ideal place to run `bravia-guard.sh` and to packet-capture the
TV (`tcpdump -i br-lan 'ether host <tv-mac>'`) if you ever want to watch its traffic
directly.

### VLAN alternative

If your switch or AP does VLANs, put the TV on its own VLAN and allow only the guard host to
route into it. Same idea, different gear.
