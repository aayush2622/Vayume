[Index](CONFIGURATION.md)

---

The login screen - the one piece of this desktop that has to look right before any of the rest of it exists yet.

## `modules/desktop/sddm/SddmTheme.nix`

- **The theme is vendored, not fetched.** `./Theme` is a real directory
  in this repo, built into a tiny derivation that drops it at
  `share/sddm/themes/women-umbrella`. SDDM wants a filesystem path, and
  it's pointed at the store path directly rather than at
  `/run/current-system`, so switching generations can never leave the
  greeter pointing at a theme that no longer exists.
- **`theme.conf` is generated, not shipped.** It's the one file in the
  theme that isn't copied verbatim - it's written with
  `pkgs.writeText` and installed over the top, so `cursorTheme` and
  `cursorSize` come from `vayori.theme` instead of being a second place
  you'd have to remember to update. Change
  `vayori.theme.cursorSize` in [Host.nix](core-host.md) and the greeter's
  cursor changes with everything else's.
- **`font=Itim` deliberately does *not* come from `vayori.theme`.**
  This is one of the two documented gaps in
  [Fonts.nix / Portals.nix](desktop-portals-fonts.md): the theme's clock
  and labels were designed around its own bundled font, and pointing
  them at JetBrainsMono Nerd Font makes the layout look wrong rather
  than consistent. Left alone on purpose.
- **`themeMode=light` is the theme's own setting**, unrelated to the
  GTK/Qt light-dark story in [Baseline.nix](desktop-baseline.md).
  Matugen never touches the greeter at all - it can't, since the greeter
  runs before any user session exists and therefore before there's a
  wallpaper to derive colors from. The login screen is the one surface
  in this whole setup that stays a fixed design.
- **The greeter runs on Wayland**
  (`services.displayManager.sddm.wayland.enable`), matching the two
  compositors it launches into. The X11 greeter works too, but mixing
  display servers across the login boundary is exactly where cursor
  themes and scaling stop agreeing with each other.
- **Cursor wiring lives in [Host.nix](core-host.md), not here** - the
  `GreeterEnvironment` line that exports `XCURSOR_THEME`/`XCURSOR_SIZE`/
  `XCURSOR_PATH` into the greeter's own process, plus
  `systemd.services.display-manager.environment`. `theme.conf` covers
  what the *theme* draws; those cover what SDDM itself and any Qt
  dialogs around it draw. Both are needed, which is why the cursor
  values get built once in one `let` binding up there and reused.

---

[← Matugen.nix](desktop-matugen.md) · [Index](CONFIGURATION.md) · [DevTooling.nix →](system-devtooling.md)
