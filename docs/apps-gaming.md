# Gaming app reference

[← Back to index](CONFIGURATION.md)

---

## `modules/apps/gaming/Gaming.nix`

One `vayori.apps` toggle (`Gaming`), split across four files so it doesn't
turn into a wall of text - Lutris + Heroic as the launchers, Steam
alongside them, plus everything shared between them:

- **`Gaming.nix`** is the real `flake.homeModules.apps.Gaming` entry. It
  works out `gamesDir`/`shaderCacheDir` and imports the three fragments
  below, handing them those two paths via `_module.args` (a plain
  function argument can't reach an imported module, this is how the
  module system does it - `self` doesn't need this treatment, it's
  already available everywhere).
- **`_launchers.nix`**: Lutris/Heroic/AdwSteamGtk packages, the `~/Games`
  folder + GTK bookmark, and the Heroic/Steam themes.
- **`_proton.nix`**: the Proton/Wine stack (umu-launcher, wine,
  winetricks, protontricks, protonup-qt), `$WINEPREFIX`, the Wine theme,
  and Lutris's default runner.
- **`_performance.nix`**: gamescope + its two wrapper scripts, MangoHud,
  the NVIDIA shader-cache path.

  Those three all start with an underscore on purpose - same reason as
  [\_hardware.nix](core.md#moduleshostsname_hardwarenix): import-tree
  ignores anything with `/_` in the path, so these fragments (which
  aren't valid flake-parts modules on their own - they use `home.packages`,
  not flake-parts options) stay invisible to it. `Gaming.nix` is the only
  thing that actually imports them.

**Steam is enabled in `Host.nix`, not here.** `programs.steam.enable`
needs system-level stuff (32-bit libs, firewall rules, controller udev
rules) that a per-user module can't touch. `umu-launcher` stays in this
file regardless - it's Lutris's own Proton runner and doesn't care
whether Steam exists.

**One games folder, one shared Wine prefix.** `~/Games` gets created,
`WINEPREFIX` points inside it. This only covers *plain* `wine`/
`winetricks` calls - Lutris and Heroic manage their own per-game prefixes
and don't care what `$WINEPREFIX` says. Point a specific Lutris game at
the shared prefix through its own Configure → Wine prefix field if you
want that.

**`gamescope-fhd`/`gamescope-fsr`** are two tiny wrapper scripts.
`gamescope-fhd`: borderless 1080p, adaptive sync, no upscaling - for
games that fight niri over fullscreen. `gamescope-fsr`: renders at
1600×900 and FSR-upscales to 1080p, trading a bit of sharpness for real
headroom on the RTX 3050. Both go in as Lutris/Heroic launch options.

**MangoHud** got restyled from the defaults because the defaults are
ugly: one compact horizontal row, rounded corners, translucent
background, a color per stat instead of one blob of white text. Toggle
per-game with `MANGOHUD=1 %command%` or `Shift+F12` mid-game - it's not
session-wide, so it won't overlay everything with a GPU. One exception:
pair it with a `gamescope-*` wrapper using gamescope's own `--mangoapp`
flag instead of `MANGOHUD=1` - gamescope's own docs say not to mix them.

**NVIDIA's shader cache** points at `~/Games/.cache/nv-shaders` so it
doesn't scatter itself into `~/.cache` along with everything else.

**Lutris's default runner** is set to `ge-proton`, the magic string that
routes new games through umu-launcher's managed GE-Proton instead of
Lutris's own bundled Wine-GE. `dxvk`/`vkd3d`/`esync`/`fsync`/`battleye`/
`eac` aren't set explicitly - they already default to on. This file is
declared `force = true`, so a manual tweak through Lutris's own
Preferences UI gets reset on the next rebuild - same trade-off as DMS's
`settings.json`.

**`~/Games` shows up in the file picker sidebar** via a GTK bookmarks
file, appended to rather than replacing whatever else lives there
already - no reason to nuke someone's other bookmarks for one entry.

**`programs.gamemode.enable`** lives in `Host.nix`, not here - it's a
system daemon, not a per-user thing. Lutris picks it up automatically
through `gamemoderun`; use it as an explicit launch-option prefix
elsewhere, e.g. `gamemoderun gamescope-fsr --mangoapp -- %command%`.

**GPU offload, Optimus laptops only:** none of this makes a game actually
use the dGPU by default - it'll happily run on the weaker iGPU unless
told otherwise. `nvidia-offload` (from
[\_hardware.nix](core.md#moduleshostsname_hardwarenix)) is NixOS's
built-in wrapper for that, used the same way:
`nvidia-offload gamemoderun -- %command%`. The DankAsusControl "GPU Mode"
widget does the same thing but laptop-wide instead of per-game.

**Matugen themes, three of them.** Heroic and Steam both got their
recoloring ported from
[InioX/matugen-themes](https://github.com/InioX/matugen-themes); Wine's
came the same way. Heroic has no fixed theme location - it only reads a
user-picked "custom themes folder" and a user-picked selection from its
theme dropdown, both stored in its own settings file, not anywhere
matugen or this repo would otherwise touch. Used to mean pointing Heroic
at the folder and picking "Matugen" from the dropdown once, by hand.

Now declarative, but the real settings file didn't match what its own
upstream source says: Heroic's `src/backend/config.ts` describes
`config.json` with a `defaultSettings` key, but the actual file this
install writes and reads is `~/.config/heroic/store/config.json` (an
`electron-store` instance, different shape entirely) -
`customThemesPath` under a top-level `settings` key, `theme` at the top
level next to it, set to the theme's CSS filename. Confirmed by reading
the real file directly rather than trusting the docs, and confirmed the
exact value Heroic expects for `theme` by grepping the compiled
frontend's own `app.asar` for how its theme dropdown resolves a custom
entry (straight to `getThemeCSS()` with whatever `getCustomThemes()`
returned - the filename, unmodified). `home.activation.heroicMatugenTheme`
merges just these two keys into the real file via `jq`, leaving the
rest - wine prefixes, install paths, every other real setting - alone.
Steam gets patched by `adwsteamgtk` (still a one-time manual run) since
it has no CSS hook of its own. Wine's theme writes a `.reg` file and
imports it with `wine regedit` against the shared prefix only -
Lutris/Heroic's own prefixes are out of reach for the same reason
`$WINEPREFIX` doesn't reach them either.
