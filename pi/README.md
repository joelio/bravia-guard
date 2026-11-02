# A Raspberry Pi as the keep-it-off box

A spare Pi makes a tidy home for the guard: it runs `bravia-guard.sh` on a schedule, and it
becomes the one machine you trust over ADB. Powered from the TV's own USB port it is only
alive when the TV is, which is exactly when the guard needs to run. The Pi talks to the TV
over the network, not over USB; the USB port is just power.

## Hardware notes

- A **Pi Zero 2 W** is the right size and draws little enough to sit on a TV USB port.
- A **Pi 3/4/5** wants its own power supply. Don't run one off a TV USB port; use a wall PSU
  and ignore the "powered from the TV" part.
- TV USB power usually cuts when the set is off, so the Pi loses power ungracefully. That is
  fine for a guard that only needs to run while the TV is on, but ungraceful shutdowns can
  wear an SD card over time. If that bothers you, enable a read-only/overlay filesystem
  (`raspi-config` → Performance → Overlay File System) or give the Pi its own PSU.

## Setup

1. Flash **Raspberry Pi OS Lite** with Raspberry Pi Imager. In the imager's settings, set the
   hostname, enable SSH, and enter your Wi-Fi details so it comes up headless.
2. SSH in and install ADB and git:
   ```sh
   sudo apt update && sudo apt install -y android-tools-adb git
   ```
3. Authorise the Pi to the TV, once. On the TV this is the key you trust:
   ```sh
   adb connect <tv-ip>:5555        # accept the prompt ON THE TV, tick "always allow"
   ```
   If you want the Pi to be the *only* trusted client, first do
   Developer options → **Revoke USB debugging authorisations** on the TV, then run the
   `adb connect` above so the Pi is the single approved key.
4. Get the scripts:
   ```sh
   git clone https://github.com/joelio/bravia-guard.git
   ```
5. Add a cron entry (`crontab -e`), hourly:
   ```cron
   0 * * * * BRAVIA_ADDR=<tv-ip>:5555 /home/pi/bravia-guard/bravia-guard.sh
   ```

That's it. The guard logs to `~/.bravia-guard.log` and only acts when something has changed.
Set `NOTIFY_URL` in `bravia-guard.sh` (e.g. an [ntfy](https://ntfy.sh) topic) if you want a
ping when it has to re-apply, which would mean a firmware update turned the stack back on.

## Why not just leave it on a laptop?

No reason not to, if the laptop is always on. The Pi is just a cheap, low-power box that is
always available and isn't your main machine, so the one trusted ADB key lives somewhere
boring and dedicated rather than on the computer you carry around.
