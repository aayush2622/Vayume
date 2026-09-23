[Index](CONFIGURATION.md)

---

Which terminal, file manager, editor and browser are "the" one - for keybinds and for what opens a link, a folder, or a code file.

## `desktop/DefaultApps.nix`

```nix
# _config.nix - every role is optional; null (the default) = automatic
vayume.defaultApps = {
  editor = "zeditor";      # code | zeditor | android-studio
  browser = null;          # zen
  fileManager = "thunar";  # thunar | nautilus
  terminal = null;         # kitty
};
```

Or **Vayume Settings → Default Apps**, which writes the same block
through `vayume config defaults set <role> <id|auto>`.

**One catalog, two consumers.** Each role's choices live in
`flake.vayumeLib.desktopActions` ([`modules/lib/VayumeLib.nix`](../modules/lib/VayumeLib.nix)):
an id, a label, the `vayume.apps` entry that installs it, its `.desktop`
file, and the command to run. Roles with a `label` are the choosable
ones; `browserReload`/`systemMonitor`/`colorPicker` only use the list
as launch fallbacks.

- **File associations.** The effective choice's `.desktop` becomes the
  Home Manager `xdg.mimeApps.defaultApplications` entry for every MIME
  type of its role: `inode/directory` for the file manager, http/https
  for the browser, the source-file list for the editor. These used to be
  hardcoded in `Thunar.nix` (folders *and* every code file →
  `code.desktop`, even with VS Code turned off) and `ZenBrowser.nix`.
  Kept in one module on purpose: `defaultApplications` values are
  *lists*, so two modules setting the same type don't conflict - they
  silently merge into a preference order.
- **Keybinds.** The launchers behind `Mod+Return`/`E`/`C`/`B` (see
  [Hyprland.nix](desktop-hyprland.md)) read `/etc/vayume/default-apps`
  (`role=id` lines, generated from this option) at key-press time and
  try that choice first, then the others in catalog order. It's a file
  rather than baked in because Niri's config is a `perSystem` package
  that never sees a host's settings.

**Automatic means the first enabled app, in catalog order** - VS Code,
then Zed, then Android Studio for the editor. Picking an app that isn't
enabled is refused twice over: `vayume config` only offers enabled
choices, and evaluation fails with an assertion naming the
`vayume.apps` entry to turn on. (A default pointing at a `.desktop` file
that isn't installed would make every link or folder open *nothing*.)
Firefox/Chromium stay as keybind fallbacks only - no Vayume app
installs them, so there's nothing to check a choice of them against.

**`xdg.mimeApps.enable` has to be set explicitly** - Home Manager
defaults it to `false`, and then the whole `defaultApplications` block
silently writes no `mimeapps.list` at all. This module sets it.

**The editor's MIME list is what this machine's shared-mime-info
actually reports** (`xdg-mime query filetype`), not what the names
suggest: `.ts` is `text/vnd.trolltech.linguist` and `.tsx` is
`application/x-tiled-tsx` - Qt/Tiled leftovers with nothing TypeScript
about them. Easy to "fix" by mistake when re-reading the list.

---

[← Hyprland.nix](desktop-hyprland.md) · [Index](CONFIGURATION.md) · [Fonts.nix / Portals.nix →](desktop-portals-fonts.md)
