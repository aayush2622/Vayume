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
  `cursorSize` come from `vayume.theme` instead of being a second place
  you'd have to remember to update. Change
  `vayume.theme.cursorSize` in `_config.nix` ([Theme.nix](core-theme.md)) and the greeter's
  cursor changes with everything else's.
- **`font=Itim` deliberately does *not* come from `vayume.theme`.**
  This is one of the two documented gaps in
  [Fonts.nix / Portals.nix](desktop-portals-fonts.md): the theme's clock
  and labels were designed around its own bundled font, and pointing
  them at the monospace `vayume.theme.font` makes the layout look wrong rather
  than consistent. Left alone on purpose.
- **`themeMode=light` is the theme's own setting**, unrelated to the
  GTK/Qt light-dark story in [Theming.nix](desktop-theming.md).
  Matugen never touches the greeter at all - it can't, since the greeter
  runs before any user session exists and therefore before there's a
  wallpaper to derive colors from. The login screen is the one surface
  in this whole setup that stays a fixed design.
- **The layout follows Vayori** (see the [README](../README.md#vayori)) while
  keeping the ink wallpaper and its composition: the clock, date and a
  time-of-day greeting top left; the user chip, a rounded glass password
  field with a submit button, and pill buttons for session, suspend, reboot
  and power sitting on the character in the artwork (`bellyArea`, placed by
  screen fraction so it lands in the same spot at any resolution); and a
  small 夜 vayume mark bottom left. Icons are Material Symbols Rounded and
  the mark is Noto Serif CJK JP, both installed system-wide by
  [Fonts.nix](desktop-portals-fonts.md), so the greeter can use them before
  anyone logs in. Clicking the name cycles users, clicking the session pill
  cycles sessions, Enter or the arrow logs in. Checked with
  `sddm-greeter-qt6 --test-mode` in a headless sway session; that mode
  shows the layout but cannot log in, suspend or power off.
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

## Notes from the code

Explanations that used to be comments in the source files.

### `modules/desktop/sddm/Theme/Main.qml`

- Above `readonly property real cursorSizePx: (typeof config !== "undefined" && config.cursorSiz...`: Cursor size, from vayume.theme.cursorSize via theme.conf (see SddmTheme.nix) - falls back to a sane default if the config key isn't there for any reason.
- Above `HoverHandler {`: Cursor - drawn here in QML instead of relying on the greeter picking up XCURSOR_THEME over Wayland, which has been unreliable. HoverHandler only observes position, it never grabs clicks - safe to sit on root without breaking the password field or the buttons below it.

## The login screen uses the theme font

`theme.conf` gets `fontFamily=<vayume.theme.font>` and `Main.qml` uses it (`fontName`), looking the family up through the system fontconfig, which the greeter shares. The bundled Itim font is only the fallback if that key is missing. Change the font in `_config.nix` and the login screen follows after the next rebuild.

---

[← Matugen.nix](desktop-matugen.md) · [Index](CONFIGURATION.md) · [Misc.nix →](system-misc.md)
