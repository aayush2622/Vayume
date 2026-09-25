[Index](CONFIGURATION.md)

---

The unglamorous plumbing that makes screen sharing, file pickers, and one shared font actually work the same way no matter which compositor is running.

## `modules/desktop/Fonts.nix` / `Portals.nix`

- One font package for terminal/bar glyphs, one for DMS's icon font.
- **Noto Sans CJK and Noto Serif CJK are installed explicitly** because Vayume
  Settings draws its small Japanese labels in them (`Vayori.jp` and
  `Vayori.jpSerif`, see [DMS](desktop-dms.md#vayori-the-settings-design-language)).
  They used to arrive only as a side effect of other packages; without them
  those labels render as empty boxes. They are fallbacks only, never a default
  family, so the theme font still wins for everything else.
- **`ui-monospace`, `SFMono-Regular` and `Consolas` are mapped straight to the
  theme font in `localConf`.** Fontconfig sorts Noto Color Emoji first for any
  family name that isn't installed, and WebKitGTK accepts that match for names
  fontconfig treats as monospace aliases. CSS stacks that lead with those names
  (CC Switch's JSON editor, most Tailwind `font-mono` stacks) then drew digits
  and adjacent `.`/`-` from the emoji font, which looks like spaced, dimmed
  numbers. Reproduced with WebKitGTK's MiniBrowser on a page listing each
  family separately; only those three names were affected, and prepending the
  theme font for them fixed all three. The blanket emoji append is unchanged.
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

**Emoji rendered broken and inconsistent system-wide (Zen most
visibly) - some codepoints fine, others wrong or monochrome, no
apparent pattern.** `fonts.fontconfig.defaultFonts.emoji = "Noto Color
Emoji"` looked like it should already cover this, and Firefox/Zen's own
built-in default (`font.name-list.emoji`) already prioritizes Noto
Color Emoji too - neither was the actual problem, confirmed directly
with `fc-match`, not guessed: `fc-match -s "JetBrainsMono Nerd
Font:charset=1F600"` (simulating exactly what happens when the
system's UI font, set as the fallback for every generic CSS family,
lacks a glyph and needs a substitute) put **DejaVu Sans first**, ahead
of Noto Color Emoji - DejaVu ships crude/incomplete glyphs for a
surprising number of emoji-range codepoints, and plain, unqualified
fontconfig charset-fallback ranks it ahead of the real emoji font
whenever a *specific* (non-generic) family is requested and falls
through, which is exactly the code path apps hit when the app's own UI
font is explicitly set (as it is nearly everywhere in this repo). The
`emoji` alias and Firefox's own pref only govern the small subset of
lookups that explicitly ask for the generic `emoji` family or an
emoji-presentation-flagged character - most real-world fallback
doesn't go through either. Fixed with an unconditional
`fonts.fontconfig.localConf` rule that appends `Noto Color Emoji` to
*every* font pattern's candidate list (`mode="append" binding="strong"`,
no family test) - safe for ordinary text since fontconfig only actually
selects a candidate that truly covers the requested codepoint, and Noto
Color Emoji has none of DejaVu's Latin/CJK glyphs to wrongly win with.
Verified directly before deploying: `fc-match` for a plain Latin
character was unaffected, while both U+1F600 (grinning face) and
U+2764 (heart, commonly used with an emoji-presentation selector)
correctly resolved to Noto Color Emoji with the rule in place, DejaVu
Sans/Sans Mono without it.

**cc-switch's whole UI rendered as a badly-spaced monospace mess.**
cc-switch (Tauri) renders its UI as CSS `sans-serif` inside a separate
`WebKitWebProcess` subprocess, which resolves fonts under its own
`prgname` - not `cc-switch`, the name of the process that spawns it.
A fontconfig rule scoped to `<test name="prgname"><string>cc-switch</string></test>`
therefore never matched, confirmed directly with `FC_DEBUG=4`: every
font-resolution trace in that subprocess showed `prgname:
"WebKitWebProcess"`. Nothing else on this system embeds webkitgtk, so
scoping the rule to `WebKitWebProcess` unconditionally is safe -
`fonts.fontconfig.localConf` reassigns that process's `sans-serif` to
`theme.font` instead of whatever its own bare fallback chain picked,
without touching the system-wide `sansSerif` default any other app
still uses.

**One font setting drives everything declarative**: system font, GTK app
text, terminal, and DMS's own UI all read the same shared font option.
Two things it doesn't reach: the SDDM login screen's clock/labels use a
font bundled inside the login theme itself, so changing it means
shipping a different font file, not flipping a setting. Qt apps also read
their font from Qt's own config instead, which matugen already manages
separately.

## One font everywhere

`vayume.theme.font` (in `_config.nix` or the Appearance page) is the only place a font is chosen; these are the consumers:

- **fontconfig defaults:** `sans-serif`, `serif` and `monospace` all resolve to it (`serif` was missing, so apps asking for a serif got Noto Serif or DejaVu Serif).
- **Named fonts:** an app that asks for a specific family gets your font first, with the original still there as a fallback for glyphs yours lacks. This covers the generic and system names (`system-ui`, `ui-sans-serif`, `ui-monospace`, `-apple-system`, `BlinkMacSystemFont`), the common web and office names (`Arial`, `Helvetica`, `Helvetica Neue`, `Segoe UI`, `Roboto`, `Cantarell`, `Ubuntu`, `Open Sans`, `Inter`, `Noto Sans`, `DejaVu Sans`, `Liberation Sans`, `Adwaita Sans`, `Times New Roman`, `Times`, `Georgia`, `Cambria`, `Noto Serif`, `DejaVu Serif`, `Liberation Serif`), and the code fonts (`Menlo`, `Monaco`, `Consolas`, `Courier New`, `Liberation Mono`, `DejaVu Sans Mono`, `Noto Sans Mono`, `Source Code Pro`, `Fira Code`, `Cascadia Code`, `Roboto Mono`). This is how Electron apps, Steam, Wine and web pages pick it up. Icon fonts (Material Symbols) are deliberately not aliased. Web pages that ask for a serif will now show in a monospace font if that is your font; remove the serif names from `aliasedFamilies` in `Fonts.nix` if that is not what you want.
- **Icons in every app:** the Nerd Font symbols-only font is installed system-wide, so the glyphs in fastfetch and Starship render outside kitty too (kitty also has its own built-in copy).
- **GNOME settings (dconf):** `font-name`, `monospace-font-name` and `document-font-name` in `org.gnome.desktop.interface` are all your font and size. libadwaita and GNOME apps (Nautilus, Text Editor, the portals) read those keys, not `settings.ini`; `monospace-font-name` and `document-font-name` were still GNOME's defaults (`Hack` and `Noto Sans`).
- **Hyprland's own text** (its error and notification banners) uses it through `misc.font_family`.
- **Qt apps:** `qt5ct.conf` and `qt6ct.conf` have a `[Fonts]` section with your font and size, so Qt apps no longer depend on a fontconfig guess.
- **Already followed it:** GTK, DMS, kitty, Zed, VS Code (editor, plus now the terminal, debug console, markdown preview, commit box, CodeLens and inlay hints), Zed (interface, editor and now the terminal), Android Studio's editor, Zen Browser, Vesktop, Spicetify and Heroic.
- **The login screen** follows it too, see [SddmTheme.nix](desktop-sddm.md).

Not covered: GRUB (its font is a converted bitmap in the theme), the text console, and Android Studio's menus and tool windows, which use a separate UI font setting I could not verify a config file for.

---

[← DefaultApps.nix](desktop-default-apps.md) · [Index](CONFIGURATION.md) · [Theming.nix →](desktop-theming.md)
