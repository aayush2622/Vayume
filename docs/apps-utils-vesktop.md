[Index](CONFIGURATION.md)

---

Discord, with a real theme instead of a generic one - the Oxocarbon rewrite that made this happen is its own small story.

## `modules/apps/utils/vesktop/Vesktop.nix`

Two real config files, pinned straight off the reference machine, plus a
matugen theme - same "capture what's actually there" approach as the
editors. Declared as plain Nix data and serialized out, not copied in as
opaque `.json` files, so it reads like everything else in this repo.

- **Vencord's settings and plugin list** are just every plugin actually
  enabled on the real machine, with any non-default tuning (blur amount,
  ignore lists, that kind of thing). Unlike JetBrains plugins, nothing
  here needed fetching - every Vencord plugin ships built into the app,
  so "installing" one is just flipping a boolean.
- **Vesktop's own settings** (tray behavior, update branch, spellcheck
  languages, splash colors) live in a separate, smaller file at a
  different path, captured the same way.
- **Plugins that are just plain "off" got left out entirely** rather than
  spelled out one by one - of about 172 real plugins, 68 made the cut
  (everything on, plus anything with non-default settings even while
  off, plus the framework "*API" plugins kept explicit either way, since
  other plugins hook into them and it costs nothing to be safe). Checked
  Vencord's own source for this rather than assuming: leaving a plugin
  out resolves to exactly the same default it'd get if it were "off" and
  unmentioned, for every single one of them.
- **Runs through home-manager's native Vesktop module** now, not
  hand-written files - it grew one after this was first set up, and it
  writes to the exact same two paths this repo always used, so nothing
  needed restructuring. One real difference: the native module doesn't
  force-overwrite, so a leftover file from an earlier manual Vesktop
  launch can collide with it on the very first switch - a one-time
  delete of those two files clears that up.
- **QuickCSS imports DMS's own theme rather than shipping a custom
  one.** This repo used to carry its own hand-recolored DiscordRecolor
  theme via a dedicated matugen template; DMS ships its own
  matugen-themed Vesktop CSS too (the well-known
  [midnight-discord](https://github.com/refact0r/midnight-discord)
  theme, recolored), at `~/.config/vesktop/themes/dank-discord.css` -
  running both was pure duplicated work for the same result, so the
  custom template was dropped and DMS's own is used directly.
  Vesktop only auto-loads QuickCSS, not the `themes/` folder DMS writes
  to (same "needs a manual toggle" gap as GTK's own Apply button, just
  for Vesktop's Settings > Themes tab), so
  `home.activation.applyDmsVesktopTheme` writes
  `~/.config/vesktop/settings/quickCss.css` as a plain `@import
  url("../themes/dank-discord.css");` on every rebuild - a real file via
  `install`, not a `home.file` symlink, so the relative import resolves
  against Vesktop's own real config directory rather than wherever a
  Nix store symlink's target happens to sit (same reasoning as the GTK4
  `@import` fix in [desktop.md](desktop-dms.md)).
- **The shared font still reaches Discord's own chrome, not just
  colors** - Discord/Vencord's UI reads its font off a `--font` custom
  property, appended after the `@import` in the same generated
  `quickCss.css` so it layers on top of DMS's own theme rather than
  needing DMS to know about this repo's font choice at all.

---

[← Terminal.nix](apps-utils-terminal.md) · [Index](CONFIGURATION.md) · [Distrobox.nix →](apps-utils-distrobox.md)
