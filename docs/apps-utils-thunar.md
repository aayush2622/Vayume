[Index](CONFIGURATION.md)

---

The default file manager on this host - and the one that quietly proves how much of this repo's theming is a GTK story rather than a per-app one.

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
  `vayume-dank-*` named theme out of
  [Theming.nix](desktop-theming.md) like every other GTK3 app,
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
- **`xdg.mimeApps.enable` isn't implied by setting
  `defaultApplications`.** It defaults to `false` in home-manager, and
  without setting it explicitly the whole `defaultApplications` block
  silently does nothing - no `mimeapps.list` gets written at all, so
  neither file manager actually claims `inode/directory` and whichever
  one opens a folder comes down to desktop-file discovery order instead
  of this repo's own config. Caught by building the real activation
  package and grepping the output for `thunar.desktop` rather than
  trusting that `nix flake check` would catch it - it doesn't, since the
  option evaluates and builds fine either way. This is the one module
  on this host where `Thunar.enable`/`Nautilus.enable` actually matter:
  Thunar is on, Nautilus is off, on purpose - one file manager, not two
  competing for the same mimetype.
- **The right-click menu's permanent "Delete" is one xfconf property.**
  By default it only shows up in the context menu while Shift is held;
  `misc-show-delete-action = true` in `thunar.xml` pins it there
  alongside "Move to Trash" all the time, so you don't need to remember
  a modifier key just to skip the trash.
- **Downloads/Documents/etc. show up in the sidebar two different ways,
  and this module relies on both.** Thunar auto-lists the XDG special
  directories under "Places" once they exist on disk - which they do,
  since [Theming.nix](desktop-theming.md) turns on
  `xdg.userDirs.createDirectories` for every user - but it separately
  reads GTK3's own bookmark file, `~/.config/gtk-3.0/bookmarks` (not the
  legacy `~/.gtk-bookmarks` - still readable by some apps, but Thunar and
  GTK3 don't write or read it anymore), for its own pinnable "Bookmarks"
  section, which starts out empty. `standardBookmarkDirs` seeds that file
  with five folders (pulled from `config.xdg.userDirs.*`, not hardcoded
  paths - Desktop is deliberately left out since GTK's places sidebar
  already pins it on its own and listing it here would just duplicate the
  row) so they show up immediately rather than depending on
  activation-order timing between folder creation and Thunar's own
  directory scan - same seed-once pattern as `thunar.xml`, since Thunar
  rewrites this file too whenever a bookmark is added or removed by
  hand. The activation script also does a one-time cleanup pass: an
  earlier version of this seed added a bare, unlabelled Desktop bookmark,
  and a `sed` removes exactly that one line (never a user's own labelled
  bookmark) now that Desktop is excluded going forward.
- **"Copy Path" is a custom action, not xfconf.** Thunar's custom actions
  (right-click menu items beyond the built-ins) live in their own plain
  `uca.xml`, which Thunar just re-reads with no `xfconfd` restart needed -
  unlike everything else in this file. The action shells out to a
  dedicated `copyPathScript` (`wl-copy -- "$1"`) rather than an inline
  `bash -c '...' -- %f`, because Thunar substitutes `%f` with a single
  shell-quoted argument and parses the whole command line itself before
  spawning it - handing it a plain executable plus one argument avoids
  stacking this module's own quoting on top of Thunar's.
- **The `.ts`/`.tsx` defaults look wrong until you check what they
  actually resolve to.** The mimetypes in `defaultApplications` are what
  extensions on this machine's shared-mime-info database actually resolve
  to right now, checked with `xdg-mime query filetype` rather than
  guessed - notably `.ts` is `text/vnd.trolltech.linguist` and `.tsx` is
  `application/x-tiled-tsx` here, both Qt/Tiled leftovers with nothing
  TypeScript about the name. Doesn't affect double-click behaviour
  either way - Thunar dispatches on the resolved mimetype, so `.ts`/
  `.tsx` still open in VS Code - it's just easy to get confused re-reading
  this list later and think it's misconfigured.

---

[← Nautilus.nix](apps-utils-nautilus.md) · [Index](CONFIGURATION.md) · [Bitwarden.nix →](apps-utils-bitwarden.md)
