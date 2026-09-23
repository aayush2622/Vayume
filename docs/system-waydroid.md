[Index](CONFIGURATION.md)

---

Android apps in a container - and an honest admission that not everything on a NixOS machine can be declarative.

## `modules/system/waydroid/Waydroid.nix`

- **The Android image is pinned to LineageOS 18.1 (Android 11).**
  `android11Images` unpacks the `20250628` system and vendor images (the
  last 18.1 builds Waydroid published) into the store and exposes them at
  `/etc/waydroid-extra/images`, which `waydroid init` prefers over its own
  download. That path also makes Waydroid skip the online update check, so
  the image never moves. The reason for going back to Android 11: **stock
  Waydroid 18.1 builds already implement signature spoofing** (`services.jar`
  handles `android.permission.FAKE_PACKAGE_SIGNATURE` and `framework-res`
  declares it), while the Android 13 (lineage-20) images do not - checked by
  reading both images' `services.jar`. microG needs that permission, so on
  Android 13 it can't work without patching the framework.
- **`waydroid-script` is pinned by commit, not tracked.**
  casualsnek/waydroid_script has no releases worth following, so it's
  fetched at a fixed rev with a hash and wrapped with its own Python
  (`tqdm`, `requests`, `inquirerpy`) plus the binaries it shells out to
  (`waydroid`, `e2fsprogs`, `util-linux`, `tar`, `lzip`, `gzip`). It
  also `cd`s into its own source directory on launch, because it reads
  files by relative path. Only its `install microg` job is used.
- **Its `hack nodataperm` job is deliberately not used, despite what this
  page used to claim.** It is not signature spoofing: it swaps in a prebuilt
  `services.jar` (last touched June 2023) that only relaxes `/Android/data`
  permissions. That jar calls `Process.setStartTimes(long, long)` and
  `Notification.setAllowlistToken(IBinder)`; Android 13 has neither, so
  `system_server` crashes on start (`NoSuchMethodError`) and Android hangs on
  the boot animation, and the 2025 Android 11 image lacks
  `setAllowlistToken`, so it would fail there too, on the first notification.
- **`vayume-waydroid-android11` is the whole setup**, split into a
  privileged half and a user half, same pattern as `vayume-tor` over in
  [Network.nix](system-network.md) and the rebuild/GC scripts in
  [Dms.nix](desktop-dms.md). It `sudo -n`s to a root-only script through a
  NOPASSWD rule keyed on that script's exact store path, so the rule stops
  applying by itself if the script's contents change. The privileged half
  stops Waydroid, deletes the overlays and the invoking user's
  `~/.local/share/waydroid` (Android data from another Android version
  can't be reused), runs `waydroid init -f` against the pinned images and
  installs microG.
- **The sudo rules are generated from `vayume.users`**, not hardcoded -
  every `wheel` user this host declares gets the rule, so adding a
  second admin in `_config.nix` doesn't mean remembering to edit this
  file too. Non-`wheel` users are left out on purpose, same as
  `vayume-rebuild`: both helpers wipe machine-wide state under
  `/var/lib/waydroid` as root, which isn't something a user without
  sudo should be able to do. It's
  guarded with a `config ? vayume` check so the module still evaluates
  if it's ever imported somewhere `vayume.users` doesn't exist.
- **`vayume-waydroid-unpatch` is the recovery path** if a bad `services.jar`
  is ever left in the overlay: it stops the container, deletes the overlaid
  `services.jar*` and `nodataperm` files and starts it again, with its own
  NOPASSWD rule.
- **`waydroid-helper` is included as a GTK front-end** for the same
  extension jobs, for when a menu is nicer than remembering a
  subcommand.

Usage, once (this wipes Android app data):

```bash
vayume-waydroid-android11
```

Then start Waydroid, give the first boot a few minutes, open microG Settings,
run the Self-Check and grant "Spoof package signature" to the apps that want
it.

---

[← Network.nix](system-network.md) · [Index](CONFIGURATION.md) · [AndroidStudio.nix →](apps-dev-androidstudio.md)
