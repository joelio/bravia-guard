<p align="center">
  <img src="logo.svg" alt="bravia-guard" width="128" height="128">
</p>

<h1 align="center">bravia-guard</h1>

<p align="center">Turn off the ACR and telemetry on a Sony Bravia, prove it's off, and keep it off.</p>

<p align="center">
  <a href="https://github.com/joelio/bravia-guard/actions/workflows/ci.yml"><img src="https://github.com/joelio/bravia-guard/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
</p>

---

Modern Sony Bravias run Android TV with **Samba TV's ACR** (automatic content recognition)
and a **Sony usage-telemetry agent** installed and running by default. ACR fingerprints
whatever is on the screen, including HDMI inputs, works out what you're watching, and sends
that off. In December 2025 the Texas attorney general sued Sony and four other makers over
exactly this.

These are ordinary Android packages. You don't need root to switch them off, you need ADB.
This repo does three things:

- **`disable.sh`** turns the stack off (reversibly).
- **`verify.sh`** reads the TV's own socket tables over ADB and shows you who it's still
  talking to, so you can confirm it went quiet. No packet capture, no tap, no root.
- **`bravia-guard.sh`** re-applies the change if a firmware update ever turns it back on.
  Run it from cron or a launchd timer.

There's a longer write-up of how and why here:
**[the blog post](https://www.joelmerrick.co.uk/blog/sony-bravia-acr/)**.

## This has only been verified on one TV

A **Sony BRAVIA 4K UR3** (`BRAVIA_UR3_EU`, Android 10, UK). The package names it targets are
almost certainly **not** identical across other models, firmware versions and regions. Check
yours before you run anything, and please open a PR adding your model to
[`packages.md`](packages.md). See [that file](packages.md) for how to find your own package
names.

## What it does and doesn't claim

- It disables **software**, not hardware. It targets named packages, confirms they were
  running, and confirms they stop.
- `verify.sh` shows **destinations**, not payloads. Traffic is TLS and these apps pin
  certificates, so the contents were never readable anyway. Knowing who the TV connects to
  is enough to tell whether ACR is active.
- It does not touch **Google's own** viewing diagnostics, which is a separate on-screen
  setting. Turn that off too if you want (Settings, then the privacy/ads sections).
- Nothing here is permanent against a **firmware update**. See below.

## Requirements

- A Sony Bravia (Android TV / Google TV) whose packages you've checked against your model.
- `adb` on your machine. `verify.sh` also needs `python3`.
- Network ADB enabled on the TV (one-off, on screen):
  Settings, System, About, click **Build** about seven times to unlock Developer options,
  then enable **USB debugging** (this also makes the set listen for ADB over the network).

## Quick start

```sh
export BRAVIA_ADDR=192.168.x.x:5555      # your TV's IP, port 5555
adb connect "$BRAVIA_ADDR"               # accept the prompt ON THE TV (tick "always allow")

./disable.sh --dry-run                   # see exactly what it will run, change nothing
./disable.sh                             # do it
./disable.sh --ads                       # also disable ad / promo / profiling packages
./verify.sh                              # watch /proc for 20s; should report CLEAN
```

Undo everything:

```sh
./restore.sh                             # re-enables and reinstalls; reboot the TV after
```

## Keeping it off (the guard)

The disable survives reboots. It does **not** survive a firmware update that rewrites the
system partition and reinstates the packages; without root you can't delete them or pin them
off. Two options: freeze updates (and lose security fixes, which I don't recommend), or let
updates happen and re-apply afterwards. `bravia-guard.sh` is the second. It checks the state
and only acts if something changed, so it's safe to run on a schedule.

cron (e.g. on a Raspberry Pi, a NAS, or an always-on router), hourly:

```cron
0 * * * * BRAVIA_ADDR=192.168.x.x:5555 /path/to/bravia-guard/bravia-guard.sh
```

launchd on macOS: a `StartInterval` or `StartCalendarInterval` agent calling the same script.
Set `NOTIFY_URL` inside the script (e.g. an [ntfy](https://ntfy.sh) topic) to get pinged if
it ever has to re-apply, which tells you an update tried to switch ACR back on.

The guard needs network ADB to stay enabled, which means an open, key-authorised ADB port on
your LAN. That's a trade-off: fine on a trusted home network, not something to expose.

## Locking down the ADB port

ADB is already gated by RSA key auth, so an unauthorised host gets nowhere. To tighten it
further, the simplest and most effective step is to **rekey** so exactly one client is
trusted (Developer options, then Revoke authorisations, then re-authorise one host). If you
want a network-layer firewall on top, note that a flat-subnet router can't filter traffic
between LAN peers, so it needs an inline bridge or a VLAN. Both are written up in
[`openwrt/`](openwrt/README.md).

## Safety

- Run with `--dry-run` first. Everything is reversible with `restore.sh`.
- Only disable packages you've identified. Leave launchers, settings, tuner/input,
  device-control and system UI alone. Uninstalling an unknown system package is how these
  sets get bricked.
- `pm disable-user` is the safe verb. The one `pm uninstall --user 0` here (the persistent
  wrapper) is still reversible, because the APK stays in the read-only system image.

## Prior art

General Android-TV debloat projects already do the `pm disable-user` dance with restore
scripts and safety lists, and they're worth a look: for example
[dumbtv](https://github.com/humblemuzzu/dumbtv). bravia-guard is narrower and Sony-specific:
it targets the Samba ACR stack by name, verifies the result from the device's own `/proc`,
and keeps it applied across updates.

## Disclaimer

Not affiliated with, endorsed by, or connected to Sony or Samba TV. "Sony", "Bravia" and
"Samba TV" are trademarks of their respective owners, used here only to describe what the
tool operates on. Use on your own equipment. No warranty; see [LICENSE](LICENSE).

## Licence

[Apache-2.0](LICENSE).
