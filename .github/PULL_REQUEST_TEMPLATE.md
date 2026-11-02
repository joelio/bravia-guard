<!-- Thanks for contributing. Most PRs will be adding a model to packages.md. -->

## What does this add?

- [ ] A new model row in `packages.md`
- [ ] A fix to the scripts
- [ ] Docs

## If you are adding a model

Please paste the output (redact your IP/MAC):

```
adb shell getprop ro.product.model
adb shell getprop ro.product.name
adb shell getprop ro.build.version.release
adb shell pm list packages | grep -iE 'samba|idd|interactiv|acr'
```

- How did you confirm the packages were actually active (e.g. `ps -A`, or `./verify.sh`)?
- Did `./disable.sh` then `./verify.sh` come back CLEAN, and did it survive a reboot?

## Confirmations

- [ ] This is my own device.
- [ ] I used `--dry-run` first and understand the changes are reversible with `restore.sh`.
