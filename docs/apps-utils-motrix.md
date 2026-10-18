[Index](CONFIGURATION.md)

---

A native download manager, enabled as a normal utility app.

## `modules/apps/utils/motrix/Motrix.nix`

[Motrix](https://motrix.app) is a full-featured download manager with HTTP,
FTP, BitTorrent and Metalink support. The module uses the `motrix` package
already provided by nixpkgs, so there is no separate source fetch or hash to
maintain.

The app is x86_64-linux-only in the current nixpkgs package. Enable it with
`vayume.apps.Motrix.enable = true;`; it then appears in Vayume Settings and is
installed through the user's Home Manager profile.

**The login service starts Motrix hidden.** Motrix only hides its window at start when it believes it was opened at login, which it detects from the `--opened-at-login=1` argument (its own auto-launch passes it, but `open-at-login` is off here because the systemd user service does the launching). The service passes the argument itself; opening Motrix from the launcher or a magnet link reaches the running instance and shows the window.

**Duplicates are tidied by a timer.** With the Zen add-on, one download can end up as two files: Zen cancels its copy after pausing it, which in Firefox leaves the `*.XXXXXXXX.ext.part` partial behind, and a small file that finishes before the pause is saved twice (`name.ext` from Zen, `name.1.ext` from Motrix). `motrix-tidy.timer` runs `motrix-tidy.service` every two minutes and only removes (a) a `.part` that has not been touched for two minutes while the finished file it belongs to exists, and (b) a `name.N.ext` that is byte-for-byte identical to `name.ext`, written within two minutes of it, with no `.aria2` file beside it. Anything else, including a `.part` of a download Zen is really doing, is left alone. Its output is in `journalctl --user -u motrix-tidy`.

---

[← Sonora.nix](apps-utils-sonora.md) · [Index](CONFIGURATION.md) · [Nautilus.nix →](apps-utils-nautilus.md)
