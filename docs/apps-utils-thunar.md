[Index](CONFIGURATION.md)

---

The second file manager - and the one that quietly proves how much of this repo's theming is a GTK story rather than a per-app one.

## `modules/apps/utils/thunar/Thunar.nix`

- **It reads xfconf, not dconf - and that's the whole trap.** Thunar is
  an XFCE app: it links `libxfconf` and ships *zero* gsettings schemas.
  A `dconf.settings."org/xfce/thunar/preferences"` block looks exactly
  like the Nautilus one two pages back, evaluates fine, builds fine, and
  is silently ignored at runtime. The settings here are written as a
  real xfconf channel XML instead, and every property name in it was
  read back out of the Thunar binary rather than copied off a wiki -
  three plausible-looking ones (`misc-date-style`, `misc-thumbnail-mode`,
  `misc-file-size-binary`) don't exist in 4.20.9 at all and were dropped
  once that check was actually run.
- **The config file is seeded once, not symlinked.** Thunar rewrites
  `thunar.xml` itself every time you resize a window or switch a view,
  so a read-only symlink into the Nix store turns every one of those
  writes into an error. `home.activation.seedThunarConfig` copies it in
  only if nothing is there yet and then gets out of the way - same
  pattern as `seedDmsSession` in [Dms.nix](desktop-dms.md).
- **Plugins have to be baked in with an override, not listed
  alongside.** Thunar only looks for plugins inside its own prefix, so
  `thunar.override { thunarPlugins = [ ... ]; }` is the only thing that
  works - archive (create/extract from the context menu), media-tags,
  and volman (the removable-media handler). Adding them to
  `home.packages` as siblings installs them where Thunar will never
  look. nixpkgs' own `programs.thunar` module does exactly the same
  override for the same reason.
- **Matugen reaches it for free, because it's a GTK3 app.** There's no
  Thunar-specific template anywhere in this repo and there shouldn't be:
  it links `libgtk-3.so.0`, so it picks up the rotating
  `vayori-dank-*` named theme out of
  [Baseline.nix](desktop-baseline.md) like every other GTK3 app,
  live-reload included. The one setting that matters for this is
  `misc-use-csd = true` - with client-side decorations on, the window's
  titlebar is drawn by GTK and follows the wallpaper's colors; with it
  off, XFCE draws its own titlebar that matugen never touches and the
  window ends up half-themed.
- **Thumbnails need backends, not just tumbler.** `services.tumbler` is
  enabled system-wide in [Host.nix](core-host.md) because it's a daemon,
  but tumbler only shells out to other tools - without
  `ffmpegthumbnailer`, `poppler-utils`, `libgsf`, and
  `webp-pixbuf-loader` on `$PATH`, everything that isn't a plain PNG or
  JPEG silently falls back to a generic icon. That silence is the
  problem: nothing logs, thumbnails just never appear.
- **The GTK file-chooser block is genuinely separate config.** The two
  `org/gtk/settings/file-chooser` blocks here really are dconf, and
  really are unrelated to Thunar's own preferences - they're what every
  GTK open/save *dialog* reads, in any app, whether Thunar is installed
  or not. Same two-blocks-that-look-identical situation as
  [Nautilus.nix](apps-utils-nautilus.md), for the same reason.
- **Both file managers can be on at once.** They don't collide;
  `xdg.mimeApps` decides which one actually opens a folder, and this
  module claims `inode/directory` for Thunar. Flip
  `Nautilus.enable`/`Thunar.enable` independently and the last one to
  claim the mimetype wins.

---

[← Nautilus.nix](apps-utils-nautilus.md) · [Index](CONFIGURATION.md) · [Bitwarden.nix →](apps-utils-bitwarden.md)
