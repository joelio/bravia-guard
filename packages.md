# Package map by model

bravia-guard is currently verified on **one** set. The package names below are what the
tool acts on. They are not guaranteed to be the same on other models, firmware versions or
regions, so **confirm your own before running anything** (see "Find yours" below).

If you confirm the names on a different model, please open a PR adding a row. That is the
single most useful contribution you can make.

| Model | Internal name | Android | Region | ACR engine | Telemetry | Wrapper (persistent) | Verified by |
|---|---|---|---|---|---|---|---|
| BRAVIA 4K UR3 | `BRAVIA_UR3_EU` | 10 (SDK 29) | EU / en-GB | `tv.samba.ssm` | `com.sonyericsson.idd.agent` | `com.sony.dtv.interactivetvutil`, `com.sony.dtv.interactivetvutil.output` | @joelio |

## Find yours

With network ADB enabled and connected (`adb connect <tv-ip>:5555`):

```sh
adb shell getprop ro.product.model          # human model, e.g. "BRAVIA 4K UR3"
adb shell getprop ro.product.name           # internal name, e.g. "BRAVIA_UR3_EU"
adb shell pm list packages | grep -iE 'samba|idd|interactiv|acr'
```

Then check whether a candidate is actually running (so you are not chasing a dormant
package):

```sh
adb shell ps -A | grep -iE 'samba|idd|interactiv'
```

Override the defaults for your set without editing the scripts:

```sh
export BRAVIA_ADDR=192.168.x.x:5555
export DISABLE_PKGS="tv.samba.ssm com.sonyericsson.idd.agent"
export REMOVE_PKGS="com.sony.dtv.interactivetvutil com.sony.dtv.interactivetvutil.output"
./verify.sh
```

## Do not disable blindly

Only touch packages you have identified. Leave launchers, settings, TV input/tuner,
device-control and system UI alone. Uninstalling the wrong system package is how these
sets get bricked. When in doubt, prefer `pm disable-user` (fully reversible) over
`pm uninstall`, and run everything with `--dry-run` first.
