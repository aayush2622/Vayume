[Index](CONFIGURATION.md)

---

The unglamorous plumbing that makes screen sharing, file pickers, and one shared font actually work the same way no matter which compositor is running.

## `modules/desktop/Fonts.nix` / `Portals.nix`

- One font package for terminal/bar glyphs, one for DMS's icon font.
- Two portal backends registered: `xdg-desktop-portal-gnome` (needed for
  screencast/screenshot - niri itself doesn't implement those, and the
  plain GTK portal can't either) and `xdg-desktop-portal-gtk` (the
  generic file-chooser/settings backend most non-GNOME compositors use).
- **Explicit per-interface routing via `xdg.portal.config.niri`** -
  `default = [ "gtk" ]`, with `ScreenCast`/`Screenshot` specifically
  routed to `gnome`. This used to rely on `configPackages = [ pkgs.niri
  ];`, on the assumption niri's own package ships a portal config file
  the way some other compositor packages do. **That assumption was
  wrong, checked for real**: the actual built `pkgs.niri` output has no
  `share/xdg-desktop-portal/` directory at all, no `.conf` file, nothing
  - so that line was silently a no-op the whole time, and portal backend
  resolution was left to whatever xdg-desktop-portal's own default
  arbitration happened to pick between two registered, un-prioritized
  backends. That's a genuinely well-documented performance problem, not
  just a correctness nitpick: `xdg-desktop-portal-gnome` expects a real
  GNOME Shell underneath it, and GTK4/libadwaita apps (Nautilus very
  much included) query the portal's `Settings` interface on every
  single launch for color-scheme/accent-color - if that call lands on
  the GNOME backend instead of GTK under a non-GNOME compositor, it can
  stall for a real, user-visible amount of time before falling through.
  Widely reported for exactly this reason on sway/hyprland/niri setups,
  and niri's own wiki independently documents the exact fix now in
  place here: default to `gtk`, carve out just `ScreenCast`/`Screenshot`
  for `gnome`. Verified the corrected config actually resolves
  (`nix eval`'d against the real option schema, not guessed) - not
  verified against a live screen-share/screenshot session, which isn't
  possible in this environment.
- **`xdg.portal.config.hyprland` does *not* reuse `gnome` for
  `ScreenCast`/`Screenshot` the way niri's block does - checked before
  copying, not assumed.** Unlike niri, `programs.hyprland.enable` auto-adds
  a portal package of its own (`portalPackage`, defaulting to
  `xdg-desktop-portal-hyprland`) to `extraPortals` - confirmed directly
  in nixpkgs' `hyprland.nix` module, whose own comment states outright
  "Hyprland has its own portal, wlr is not needed". Routed both
  interfaces to `"hyprland"` instead - `gnome`'s portal implementation is
  built for Mutter's screencapture protocol, not Hyprland's own, so
  reusing niri's exact block here would have installed the right package
  and then never actually routed to it.

**One font setting drives everything declarative**: system font, GTK app
text, terminal, and DMS's own UI all read the same shared font option.
Two things it doesn't reach: the SDDM login screen's clock/labels use a
font bundled inside the login theme itself, so changing it means
shipping a different font file, not flipping a setting. Qt apps also read
their font from Qt's own config instead, which matugen already manages
separately.

---

[← Hyprland.nix](desktop-hyprland.md) · [Index](CONFIGURATION.md) · [Baseline.nix →](desktop-baseline.md)
