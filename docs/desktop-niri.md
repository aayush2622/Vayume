[Index](CONFIGURATION.md)

---

The first compositor - a scrollable-column window manager, and the keybinds that make it feel like home.

## `modules/desktop/Niri.nix`

**`extraSettings` has to sit next to `settings`, not inside it.** Nest it
and it silently serializes into an invalid config node instead of using
the wrapper's actual mechanism for raw config.

**The `include` gotcha that took a while to track down**: DMS renders a
colors file on every theme change and includes it optionally, so niri
still boots even before DMS has run once. Problem: niri rejects two
separate top-level `layout` blocks in general, but an *included* one
quietly *merges* into the one already parsed - so DMS's include was
silently overwriting this repo's translucent border colors with
matugen's opaque ones. Fix: a second include, placed after DMS's, that
just re-asserts the one field that needs to stay put. Includes merge, so
the second one wins for that field while everything else stays live and
dynamically themed.

**Blur runs at 2 passes instead of niri's default 3** - each additional
pass roughly doubles the render cost, and this runs on the Intel iGPU,
not a dGPU. Looks basically identical, costs noticeably less.

**Two ways to spawn a command**: one execs directly, the other forks a
shell first. Most binds use the direct one; the brightness binds need the
shell version since they pipe one command's output through `awk`.

**The startup hotkey overlay used to just say "dms" for every DMS bind** -
spotlight, clipboard, settings, lock, wallpaper carousel, screenshot, all
indistinguishable, since niri's overlay falls back to the bare program
name for any `spawn` it doesn't recognize as one of its own built-in
actions. Real fix, not a workaround: niri supports a `hotkey-overlay-title`
property per bind (confirmed in its own docs and by running the built
config through `niri validate`), but it's a KDL node *property*, not a
child - `wlib.toKdl` (this repo's Nix→KDL layer, from
`nix-wrapper-modules`) only emits properties for binds written in its
"special function" shape (`_: { props; content; }`), not the plain
`"Key".action = value;` sugar used everywhere else in this file. Every
`spawn`/`spawn-sh` bind now goes through a small `titled` helper that
builds that shape, so each one carries a real, distinct label
(`"Open App Launcher"`, `"Lock Screen"`, ...) instead of the generic
executable name.

The keybind list lives as its own named binding instead of buried three
levels deep in the config attrset - purely for readability, doesn't
change the built output at all.

**`environment { QT_QPA_PLATFORMTHEME "qt6ct"; QT_QPA_PLATFORMTHEME_QT6
"qt6ct"; }`** - straight from DMS's own docs, which specifically call
out niri as needing this set at the compositor level, not left to
generic session-variable propagation. Worth explaining why that's true
rather than redundant: home-manager's own `qt.platformTheme.name =
"qtct"` ([Baseline.nix](desktop-baseline.md)) only ever sets
`QT_QPA_PLATFORMTHEME` - checked the actual module source, there's no
`QT_QPA_PLATFORMTHEME_QT6` handling in it at all, for any platform theme
choice. Without it, Qt6 apps have nothing telling them to load the qt6ct
platform plugin specifically, so qt6ct.conf's matugen color scheme was
never actually reaching them - Qt5 apps were fine, Qt6 ones weren't,
silently. This overrides the value for anything niri itself spawns
(which is effectively every graphical app in this session), taking
priority over home-manager's own `qt5ct` value for that specific case -
kept both rather than reconciling them, since `qt.platformTheme` still
does real, separate work (installs the actual qt5ct/qt6ct packages,
sets `QT_STYLE_OVERRIDE`, `QT_PLUGIN_PATH`, `QML2_IMPORT_PATH`).
Verified against the real built `niri-config.kdl`, not assumed - it
renders as a genuine `environment { ... }` block, matching niri's own
documented config syntax exactly.

---

[← Dms.nix](desktop-dms.md) · [Index](CONFIGURATION.md) · [Hyprland.nix →](desktop-hyprland.md)
