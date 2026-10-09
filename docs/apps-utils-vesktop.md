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
- **The theme is written into QuickCSS itself.** The matugen template
  (a recolored [midnight-discord](https://github.com/refact0r/midnight-discord))
  renders straight to `~/.config/vesktop/settings/quickCss.css`, which
  Vesktop always loads, instead of to a file in `themes/` that
  QuickCSS had to `@import` and Settings > Themes had to switch on.
  `enabledThemes` is empty, and no relative import depends on where a
  symlink points. Older `themes/*.css` files are left alone and unused.
- **The shared font still reaches Discord's own chrome, not just
  colors** - Discord/Vencord's UI reads its font off a `--font` custom
  property, appended after the `@import` in the same generated
  `quickCss.css` so it layers on top of DMS's own theme rather than
  needing DMS to know about this repo's font choice at all.

---

[← Terminal.nix](apps-utils-terminal.md) · [Index](CONFIGURATION.md) · [Distrobox.nix →](apps-utils-distrobox.md)
