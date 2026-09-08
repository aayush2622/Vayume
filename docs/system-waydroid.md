[Index](CONFIGURATION.md)

---

Android apps in a container - and an honest admission that not everything on a NixOS machine can be declarative.

## `modules/system/waydroid/Waydroid.nix`

- **The Android image is deliberately not Nix-managed.** Waydroid keeps
  a mutable system image under `/var/lib/waydroid/images`, downloaded by
  `waydroid init` and patched in place afterwards. Nothing in the Nix
  store owns it, and pretending otherwise would mean re-downloading and
  re-patching a multi-gigabyte image on every rebuild. So this module
  ships the *tooling* and stops there: `virtualisation.waydroid.enable`,
  the patch script, and a wrapper. The patch itself is a one-time manual
  step you run after `waydroid init`, which is the honest shape for
  something that lives outside the store.
- **`waydroid-script` is pinned by commit, not tracked.**
  casualsnek/waydroid_script has no releases worth following, so it's
  fetched at a fixed rev with a hash and wrapped with its own Python
  (`tqdm`, `requests`, `inquirerpy`) plus the binaries it shells out to
  (`waydroid`, `e2fsprogs`, `util-linux`, `tar`, `lzip`, `gzip`). It
  also `cd`s into its own source directory on launch, because it reads
  files by relative path.
- **Three jobs it actually does:** `hack nodataperm` swaps in a
  `services.jar` carrying the signature-spoofing patch
  (`android.permission.FAKE_PACKAGE_SIGNATURE`) plus blanket
  Android/data permissions; `install microg` adds the microG
  GmsCore/GsfProxy/FakeStore stack; `certified` prints the device ID you
  need to register with the Play Store. Signature spoofing is the one
  that matters - microG is useless without it, since it has to convince
  apps it's Google Play Services.
- **Split into a privileged half and a user half**, same pattern as
  `vayume-tor` over in [Network.nix](system-network.md). `vayume-waydroid-sigspoof`
  is what you run; it `sudo -n`s to a root-only script through a NOPASSWD
  rule. The rule keys on that script's exact store path, which means it
  has to be invoked *by path* - and it means the rule stops applying by
  itself the moment the script's contents change, rather than silently
  granting root to whatever replaced it.
- **`SETENV` is in the sudo rule on purpose.** The image channel is
  picked with `WAYDROID_ANDROID_VERSION` - it defaults to 13, matching
  the current LineageOS (lineage-20) images, and `=11` selects the older
  one. `sudo` strips environment variables by default, so without
  `SETENV` that variable would silently never reach the privileged half
  and you'd always get the default.
- **The sudo rules are generated from `vayume.users`**, not hardcoded -
  every user this host declares gets the rule, so adding a second user
  in `_user.nix` doesn't mean remembering to edit this file too. It's
  guarded with a `config ? vayume` check so the module still evaluates
  if it's ever imported somewhere `vayume.users` doesn't exist.
- **`waydroid-helper` is included as a GTK front-end** for the same
  extension jobs, for when a menu is nicer than remembering a
  subcommand.

Usage, once, after `sudo waydroid init`:

```bash
vayume-waydroid-sigspoof            # signature spoofing only
vayume-waydroid-sigspoof microg     # + microG
```

Then open Waydroid's Settings, find microG's Self-Check, grant "Spoof
package signature" to the app that wants it, and stop/start the session
once so the new `services.jar` is actually picked up.

---

[← Network.nix](system-network.md) · [Index](CONFIGURATION.md) · [AndroidStudio.nix →](apps-dev-androidstudio.md)
