[Index](CONFIGURATION.md)

---

The file manager - small file, and a lesson in exactly how two settings blocks that look identical can still need to stay two blocks.

## `modules/apps/utils/nautilus/Nautilus.nix`

- Thumbnails kick in for bigger files instead of falling back to a
  generic icon.
- Mouse back/forward buttons navigate history.
- Drag a file over a folder and it opens automatically instead of making
  you wait.
- Opens maximized - the cramped default window size helps nobody.
- Drives/USB/SD cards auto-mount and pop a window open, but nothing ever
  auto-runs. Nobody needs that surprise.
- The open-terminal extension defaults to gnome-terminal, which isn't
  installed here, so it's pointed at kitty instead.
- gvfs and tumbler run system-wide via `Host.nix` - they're daemons, not
  a per-user concern.

---

[← Spicetify.nix](apps-utils-spicetify.md) · [Index](CONFIGURATION.md) · [Bitwarden.nix →](apps-utils-bitwarden.md)
