# Desktop reference

[← Back to index](CONFIGURATION.md)

---

## `modules/desktop/Dms.nix`

**Applies to every user, not just one hardcoded account** - an earlier
version had this hardcoded, and the bug it caused was exactly what you'd
expect: a second account logged into a niri session with no shell
running in it at all.

**`settings = { ... }` is the only key that actually does anything.** An
older `default.settings = { ... }` shape looks plausible and just quietly
does nothing if you type it by accident.

**Wallpaper default**: seeded once into
`~/.local/state/DankMaterialShell/session.json`, only if that file
doesn't already exist - not force-declared the way `settings.json` is.
That distinction actually matters: `session.json` is DMS's own live
state, rewritten every time you pick a wallpaper or the carousel
advances, not a fixed preference like theme/layout settings. An earlier
version of this file force-declared it the same way as `settings.json`,
which worked right up until "pick a wallpaper, then rebuild for any
unrelated reason" quietly reset it back to the seed - a force-declared
state file gets symlinked back into the read-only store on *every*
activation. Seeding once and then leaving it alone lets DMS actually own
the file going forward, same as it would with none of this repo's config
involved at all.

**`DMS_ENABLE_GTK4_REFRESH` was tried and reverted.** DMS's own Go source
(`matugen.go`) has this opt-in, off by default: on every theme change it
deliberately flips `org.gnome.desktop.interface color-scheme` to the
opposite value and back 400ms later, because a plain GTK theme change
doesn't make already-running GTK4/libadwaita apps (Nautilus included)
reload their CSS, but this toggle-and-restore round trip does. It got
turned on here for exactly that Nautilus benefit - but DMS's own comment
on the function names the actual cost: apps that follow the portal's
color-scheme signal instead of GTK's theme-name signal (Chromium named
specifically, but any Firefox-family browser reads the same
`org.freedesktop.appearance` portal key) "can drop the restore signal
mid-repaint and latch the wrong mode." That's exactly what started
happening to Zen Browser here - live matugen colors stopped applying and
needed a full restart to pick back up, immediately after this got
turned on. Confirmed by re-reading the same source comment against the
symptom rather than guessing: this repo doesn't ship anything
zenbrowser-specific in the refresh path (DMS's `zenbrowser.toml`
matugen target just rewrites `~/.config/DankMaterialShell/zen.css`
unconditionally on every run, symlinked to Zen's `userChrome.css` -
that part was never broken), so the color-scheme round trip was the
only thing in the chain new enough to be the cause. Left off; Nautilus
goes back to needing a manual GTK theme reselect (or reopen) to pick up
a new wallpaper's colors immediately, which is the trade DMS's own
maintainers made by defaulting this off in the first place.

**The settings block only lists what actually differs from DMS's own
defaults** - it used to declare all ~530 keys DMS's `settings.json`
schema has, mirroring upstream's own section order (theme, compositor,
weather, animation, blur, wallpaper, bar widgets, control center,
workspaces, media, greeter, launcher, dashboard, fonts, notepad, sounds,
power, matugen, dock, notifications, lock screen, OSD, power menu,
updater, displays, desktop clock, system monitor, desktop widgets,
frame), but 494 of those were just typing DMS's own upstream default
back at it. Confirmed via DMS's own `SettingsStore.js`: any key missing
from `settings.json` gets filled in with `SettingsSpec.js`'s `def` value
at load time (`if (!(k in jsonObj)) root[k] = SPEC[k].def;`), so leaving
a key out is provably identical to declaring it as its own default, not
a guess. The trim was scripted, not hand-edited - extracted DMS's real
default for all ~530 keys straight out of the actual installed
`SettingsSpec.js`, diffed against this repo's own built `settings.json`,
and only removed keys that matched byte-for-byte; the ~35 that remain
are every actual customization (theme mode, blur, dock, fonts, matugen
scheme, per-app theming toggles, widget layout, and similar). Verified
by re-simulating DMS's own fill-in-the-defaults logic against the
trimmed file and diffing the result against the original 530-key
version - identical on every key, then confirmed against a real
`nixosConfigurations.Diablo.config.system.build.toplevel` build. If
you're hunting for a specific upstream default this repo isn't
overriding, `SettingsSpec.js` in the fetched `dms` flake input is the
source of truth, not this file.

**Vesktop and Zed use DMS's own built-in themes, not a custom one.**
This repo used to ship its own matugen templates for both (a
DiscordRecolor-based Vesktop theme, a hand-written Zed theme), completely
redundant with DMS's own `vesktop`/`zed` matugen targets - both were
running on every theme change, writing to different, unused output paths
(confirmed by reading DMS's own Go template registry:
`~/.config/vesktop/themes/dank-discord.css`,
`~/.config/zed/themes/dank-zed-theme.json`). Rather than keep two
theming paths per app, this repo's own templates were dropped and DMS's
own are used directly:
- **Zed**: `theme = "DankShell Dark"` in
  [Zed.nix](apps-development.md#modulesappsdevelopmenteditorszedzednix)
  references the theme name straight out of DMS's own
  `dank-zed-theme.json` (four variants ship in that file - `DankShell
  Dark`/`Light`, plus `Transparent` variants - `Dark` is what's picked
  here). Zed just scans `~/.config/zed/themes/*.json` for a matching
  `name`, so this needs nothing beyond the string matching what DMS
  writes.
- **Vesktop**: `matugenTemplateVesktop` isn't declared at all any more
  (it matches DMS's own default of `true`, so it was trimmed along with
  every other default-matching setting - see the settings-block note
  above) - DMS keeps writing `dank-discord.css` (the well-known
  [midnight-discord](https://github.com/refact0r/midnight-discord)
  community theme, matugen-recolored), but Vesktop only *auto-loads*
  a theme through QuickCSS, not the `themes/` folder DMS writes to -
  same class of "needs a manual toggle" gap as GTK's own button, just
  for Vesktop's Settings > Themes tab instead. [Vesktop.nix](apps-utils.md#modulesappsutilsvesktopvesktopnix)'s
  `home.activation.applyDmsVesktopTheme` writes
  `~/.config/vesktop/settings/quickCss.css` as `@import
  url("../themes/dank-discord.css");` plus a small `--font` override
  (kept, so Vesktop still follows this repo's font choice like every
  other app does) - a real plain file via `install`, deliberately not a
  `home.file` symlink into the Nix store, same reasoning as the GTK4
  `@import` fix: a relative CSS import needs to resolve against the
  app's own real config directory, not wherever a symlink's target
  happens to sit.

**Third-party plugins** come from a community registry that auto-generates
an option per plugin, off by default, opt-in one at a time. A widget-type
plugin still needs manually adding to a bar section to actually show up -
enabling it alone isn't enough.

- **`dankAsusControlCenter`** is a bar popout for asusctl (power
  profiles, battery charge limits) and supergfxctl (GPU mode). Everything
  it needs is already installed elsewhere in this repo. Switching GPU
  mode needs a session logout, which the widget handles itself. Honest
  caveat: this has never actually touched real ASUS hardware, since
  there's none available to test against here - if the popout can't
  reach the daemons, check `supergfxctl -g`/`asusctl -v` work from a
  plain terminal first.
- **System monitor plugins**: several are enabled but deliberately not
  placed on the bar. CPU/RAM ones are skipped because DMS's own built-in
  widgets already show the exact same numbers - no point doubling up.
  Disk/IO monitors are enabled-but-unplaced for a more honest reason:
  seven new bar icons at once risked real clutter, and there was no
  screen available in this environment to actually eyeball how it'd
  look. They're one drag-and-drop away in DMS's own settings once you
  can see the bar for yourself.
- **`dankQuickSearch`** is enabled but not placed anywhere either - its
  own description suggests it hooks into the existing launcher directly
  rather than needing its own bar icon, unlike the monitor plugins whose
  descriptions explicitly say "in your bar." Give it a widget slot too if
  it turns out to want one.
- **`dankBitwarden`** talks to `rbw` (a separate CLI vault), not the
  desktop app - it searches whatever's in `rbw`, full stop. Its default
  actions got changed from autotype to clipboard-copy, since autotyping
  a password into whatever window happens to have focus is a riskier
  default than copy-to-clipboard, which is what Bitwarden's own UI
  defaults to anyway.
- **`spotifyMatugen`** has no settings beyond "on" - the whole feature is
  locking DMS's dynamic color to whatever's on the album art currently
  playing, and that's the entirety of what enabling it does.
- **Three community plugins needed icon patches to actually match the
  rest of the bar.** They hand-roll their own layout instead of using
  DMS's shared bar-pill component, so nothing forces them to agree on
  icon size, spacing, or color with everything else - traced this
  directly against their QML source and DMS's own plugin docs, not
  guessed. The patches (applied via a small `runCommand` + `sed`, in
  place, so plugin updates still flow through normally):
  - The disk-usage widget used a font-size constant for its icon instead
    of the bar-aware size everything else uses, plus different spacing,
    plus an accent color at rest where every other bar icon uses a
    neutral one, plus hardcoded hex colors for its warning thresholds
    that bypassed the theme entirely. Fixed the sizing/spacing/color to
    match; kept the actual "turns red past a threshold" behavior intact,
    just pointed at the right theme colors instead of literal hex.
  - The Nix monitor's spacing and icon size were already fine - just the
    same baseline-color fix as above.
  - The ASUS control center's color already resolved correctly; only its
    fixed pixel size and one hardcoded spacing value needed the same
    treatment.
- Disk usage and Nix monitor both hide their Nix-store-size figure by
  default, since they'd otherwise both show it - no reason to report the
  same number twice. Disk usage also skips ZFS entirely, since this
  machine runs btrfs and has none to show.
- The ASUS widget hides its own battery icon, since a separate battery
  widget already covers that.
- **Nix monitor's rebuild/GC buttons read their commands from their own
  separate config file**, not the plugin-settings mechanism everything
  else uses - traced directly through the plugin's QML, confirmed against
  its own upstream docs. It streams `sudo`'s real stdout/stderr straight
  into its own live console panel, no terminal wrapper needed - which
  only works headlessly if `sudo` doesn't need a TTY to prompt in (see
  the sudo rule below). Since Nix can't know at eval time where the
  actual flake clone lives on whatever machine this runs on, the rebuild
  command searches a short list of likely spots at runtime instead of
  guessing once, and fails loudly if none of them match rather than
  silently doing nothing.
- **The rebuild button was actually broken - a real, confirmed bug, not
  a hypothesis.** Reproduced end-to-end in a real VM boot: `sudo`
  resets `$HOME` to `/root` for the process it runs (standard sudo
  behavior, `env_reset` on by default), so the script's old `"$HOME/vayori"`
  search always looked in `/root/vayori` - which never exists - and
  failed with "vayori flake not found" every single time the button was
  clicked, regardless of where the flake actually lived. This is also
  why the generation count looked stuck: the plugin only calls
  `refreshData()` after a rebuild exits 0, so a rebuild that never gets
  past this check never refreshes anything, which just looks like "the
  number doesn't update." Fixed by resolving the *invoking* user's home
  directory instead of trusting `$HOME` - `vayoriHomeByUser` builds a
  `case` statement mapping every `config.vayori.users` name to its real
  `config.users.users.<name>.home` at eval time (correct even if a
  user's home is ever customized off the `/home/<name>` default), keyed
  off `$SUDO_USER` (sudo's own record of who invoked it, unaffected by
  the `$HOME` reset). A second, related failure was waiting right behind
  the first one: once the flake dir resolves correctly, `nixos-rebuild`
  running *as root* against a git repo it doesn't own trips libgit2's
  safe-directory check ("repository path ... is not owned by current
  user") - also reproduced for real in the same VM boot. Fixed with a
  single scoped `git config --global --add safe.directory "$flakeDir"`
  right before the rebuild, trusting only the one path this script
  itself found rather than a blanket `safe.directory = *`. A third fix
  landed here later, for a different reason: the final
  `nixos-rebuild switch --flake` call uses a `path:$flakeDir` ref, not a
  bare one, so `_hardware.nix`/`_user.nix` (gitignored, see
  [core.md](core.md#moduleshostsname_hardwarenix)) actually resolve
  instead of looking "missing" through git's tracked-files-only view of
  the repo.
- **Nix monitor logs a harmless "manifest load failed" warning for
  `.../plugins/NixMonitor/config.json`** on every login - that capital-N
  `NixMonitor` directory only exists because the plugin's own bundled
  QML hardcodes that exact (capital-N) path to read its config from,
  which happens to match this repo's own `xdg.configFile` declaration
  above (also capital-N, intentionally). DMS's plugin loader scans every
  subdirectory under `~/.config/DankMaterialShell/plugins/` looking for
  a `plugin.json` in each; the *real* plugin installs lowercase at
  `plugins/nixMonitor/` (from the Nix attribute name), so the capital-N
  directory only ever has a bare `config.json` and no manifest - hence
  the warning. Harmless (the actual widget reads its config fine, from
  the same capital-N path its own QML expects), just noisy; not
  something this repo can clean up without patching the plugin's own
  hardcoded path.
- **`desktopWidgetInstances` widgets size themselves via a separate
  `positions` field, not `config`** - confirmed by reading DMS's
  `DesktopPluginWrapper.qml`: `config` only reaches the plugin's own
  `pluginData`, while position/size for an instance-based widget (any
  entry with a unique `id` here, like Pure Lyrics) lives in
  `positions.<screenKey>.{x,y,width,height}` on that same instance,
  `_synced` being the key when `syncPositionAcrossScreens` is on. `x`/`y`
  are fractions of screen size when synced; `width`/`height` are always
  raw pixels and get clamped to the real screen size regardless
  (`Math.min(effectiveW, screenWidth)`), so an oversized `width` (`9999`
  here) is a resolution-independent way to say "full screen width"
  without hardcoding an actual monitor size. One real trade-off found
  the hard way: the wrapper only auto-computes a first-run default
  size when `positions.width` is entirely absent - setting `width`
  explicitly without also setting `height` would've made the *height*
  fall back to a hardcoded `180` instead of the plugin's own computed
  `fontSize * lineCount * 1.4 + 8`, so `height` is pinned here too
  (`253`, matching the configured `fontSize`/`lineCount` at the time -
  needs updating by hand if either changes, since it's no longer
  auto-computed once pinned).
- **A scoped sudo rule** lets every user run `nixos-rebuild`/
  `nix-collect-garbage` without a password - and *only* those two
  commands, with any arguments. Not blanket passwordless sudo, just
  enough for the Nix monitor's two buttons to actually work without a
  TTY to type a password into.
- **The app-launcher icon theme** is a separate icon pack fetched
  straight from its own repo (not in nixpkgs), scoped to DMS's launcher
  only via an env var DMS specifically documents for this - it doesn't
  touch Nautilus or anything else system-wide. Static install is fine
  here; unlike Papirus below, nothing ever needs to rewrite it at
  runtime.

---

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
"qtct"` ([Baseline.nix](#modulesdesktopbaselinenix)) only ever sets
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

**One font setting drives everything declarative**: system font, GTK app
text, terminal, and DMS's own UI all read the same shared font option.
Two things it doesn't reach: the SDDM login screen's clock/labels use a
font bundled inside the login theme itself, so changing it means
shipping a different font file, not flipping a setting. Qt apps also read
their font from Qt's own config instead, which matugen already manages
separately.

---

## `modules/desktop/Baseline.nix`

Applied to every user regardless of which apps they've opted into - GTK/Qt
theming is the one part of this whole rice nobody gets to skip. Lives
under `desktop/`, not `apps/`, for exactly that reason: it isn't an
opt-in pick, it's just part of what this desktop *is*.

- **This is where DMS's custom-template system actually gets assembled.**
  Every themed app in this repo contributes one small config block to a
  shared option; this file merges all of them into one file at the exact
  path DMS's own docs say to use. Needed its own real, separate option
  declaration to work properly - mixing it into the implicit config below
  it just makes it plain data at a literal path instead of an actual
  option, which was a real, if brief, mistake while building this. The
  actual template *content* each app points at lives in a separate
  shared file - see [Matugen.nix](#modulesdesktopmatugennix).
- **No extra trigger needed here, and it's worth explaining why not**: an
  earlier version of this file wrote the merged config to a *guessed*
  path, tested it, found DMS wasn't picking up custom templates live, and
  concluded a whole extra activation trigger was needed to force it.
  Wrong conclusion, right symptom. Re-tested against the actual
  documented path DMS really reads and everything just worked - every
  custom template regenerated automatically on a live wallpaper/theme
  change, no extra machinery required. "DMS doesn't apply custom
  templates live" turned out to really mean "DMS doesn't read a file it
  was never looking at in the first place" - obvious in hindsight, only
  actually caught by testing the *right* path more carefully, not the
  wrong one harder.
- **A whole GTK3 base theme was just missing.** Icon/cursor/font were all
  set, but no actual theme name or package - so GTK3 apps fell back to
  whatever's compiled in by default. This turned out to be the real
  reason matugen's live recoloring didn't visibly do anything on GTK
  apps: DMS always writes its color overrides file regardless of what
  theme is active, but those overrides are meant to be *consumed* by a
  libadwaita-aware stylesheet - with no such theme installed, they had
  nothing to attach to. Adding the standard GTK3-compatibility companion
  theme (adw-gtk3) fixed it.
- **A second, more specific gap on top of that**: the theme's checkbox/
  radio/slider icon assets only get found by DMS's helper script at a
  handful of hardcoded paths, and the normal "make the theme reachable"
  approach isn't one of them - without a symlink at the exact path this
  script actually checks, those controls render as solid blocks even
  with the theme name correctly set. One extra `home.file` entry closes
  that gap.
- One deprecation warning got silenced by explicitly adopting the newer
  default behavior directly, which also happens to be the semantically
  correct choice here - the GTK3 theme in use doesn't mean anything as a
  "GTK4 theme," GTK4/libadwaita apps get their look elsewhere.
- **XDG user dirs** get created and populated so the standard folders
  (Desktop, Documents, Downloads, etc.) actually show up as sidebar
  bookmarks in Nautilus and any other GTK file picker - without this
  they just don't exist anywhere for a fresh account. Session variables
  for the same paths get exported too, for the handful of apps that read
  those directly instead of parsing the file themselves.
- **GTK theming is wired up by literally running DMS's own `gtk.sh`**,
  not by hand-declaring the CSS files - `home.activation.applyDmsGtkColors`
  calls `${config.programs.dank-material-shell.package}/share/quickshell/dms/scripts/gtk.sh`
  directly, the exact script DMS's own Settings -> Theme -> "Apply GTK
  Colors" button runs (`Theme.qml`'s `applyGtkColors()`, read straight
  from DMS's source), on every `home-manager switch`. Getting here took
  two real bugs, both found by reading DMS's Go/QML source rather than
  guessing:
  1. DMS gates *all* live theme refresh (GTK3 reload, GTK4 CSS reload,
     accent-color sync) behind one check: is `~/.config/gtk-3.0/gtk.css`
     a symlink whose *target path* contains the literal string
     `"dank-colors.css"`? A plain `gtk3.extraCss`/`gtk4.extraCss`
     symlinks to home-manager's own generic `hm_gtk3.0gtk.css`, which
     never matches - confirmed against the real built symlink. That
     silently gated off live refresh entirely, regardless of anything
     else configured.
  2. Fixing #1 by hand-declaring `gtk.css` as a `home.file` symlink to a
     `pkgs.writeText "dank-colors.css" ...` store path made the *name*
     match, so refresh signals started firing - but Nautilus still
     needed a manual "Apply GTK Colors" click to actually pick up new
     colors. The reason: DMS's own matugen pipeline writes live colors
     to a plain, DMS-owned `~/.config/gtk-{3,4}.0/dank-colors.css`
     *sibling* file on every theme change (`RunUnconditionally: true`
     in `matugen.go`'s template registry) - `gtk.css` is only ever
     supposed to *reference* that sibling, not contain baked colors
     itself. A `home.file` symlink into the read-only Nix store can
     never be that reference, no matter what content or name it's
     given - confirmed by reading `gtk.sh` itself, which does exactly
     two things: symlinks `gtk-3.0/gtk.css -> dank-colors.css` (a bare
     relative name, resolved against the sibling file) and prepends an
     `@import url("dank-colors.css");` line to a real, non-symlinked
     `gtk-4.0/gtk.css`. It also fixes up a `gtk-3.0/assets` symlink to
     `adw-gtk3`'s check/radio/slider glyphs, without which GTK3
     checkboxes render as solid blocks - a second thing this repo's own
     static approach never handled at all.

  Running the real script instead of reimplementing its logic means
  this stays correct across DMS updates for free, and running it on
  every activation (guarded on `dank-colors.css` already existing, so a
  brand new account with no theme applied yet doesn't fail the whole
  rebuild) means the fix is what used to be a manual button click now
  happens automatically every time. Verified end-to-end against the
  real installed script with a scratch `$HOME` and a fake
  `dank-colors.css`: produces the identical `gtk.css -> dank-colors.css`
  symlink, `assets` symlink, and `@import` line the real button
  produces.
- **Qt theming deliberately has no separate style override set.** An
  earlier version forced every Qt app onto a totally different theming
  engine regardless of the palette settings below, and matugen has no
  template for that engine at all - leaving it unset lets the actual
  matugen-driven palette apply the way it's supposed to.
- **The Qt palette files point at where matugen writes its output**,
  since matugen writes the palette itself but never points the Qt config
  *at* it - same "updates an existing setup, doesn't install one" pattern
  as everywhere else DMS integrates with something. This pointer is the
  one-time setup matugen assumes is already in place.
- **Papirus lives as a real, writable per-user copy, not the read-only
  Nix package directly.** The tool that recolors Papirus's folder icons
  to match the current accent needs to actually rewrite files in place,
  which it can't do against a read-only store path - confirmed by
  reading its actual script. Conveniently, that same script checks the
  user's own icon directory before any system one, so this writable copy
  just wins automatically with zero conflict. Copied with `rsync
  --delete`, not a full recursive delete-and-recopy, so a version bump
  only transfers what actually changed instead of recopying roughly
  300,000 files from scratch every time - checked this for real against
  the actual rendered command, not just eyeballed the intent.
- **Folder color-matching** uses matugen's own real, documented support
  for driving that recoloring tool - checked against the installed
  matugen binary directly, these aren't repo-specific hacks. It picks
  whichever preset color is closest to the current accent and runs the
  recoloring tool with it, no `sudo` needed since it's editing the
  writable copy directly as the regular user.
- **The recoloring tool's own `-u` (update icon caches) flag was
  silently doing nothing.** Checked its actual script: `-u` shells out to
  `gtk-update-icon-cache`, a `gtk3` binary this repo never installed
  anywhere - `papirus-folders` itself doesn't depend on it (confirmed via
  `nix why-depends`), so it was missing from `$PATH` entirely. The
  recoloring itself was working the whole time - the underlying icon
  files really were getting rewritten - but with nothing ever
  invalidating the cached icon index, every app (Nautilus very much
  included) just kept reading the stale one forever. `pkgs.gtk3` added
  alongside `papirus-folders`, scoped to the same Papirus-only block.
- **Nautilus's own window chrome not updating live is a separate,
  GTK4-specific gap, not this same bug.** The CSS-import mechanism above
  is real and does work, but modern libadwaita (GTK4) deliberately
  doesn't hot-reload from a plain CSS re-import the way GTK3 apps do -
  DMS's own upstream source confirms this in a comment, and ships a
  specific fix for it (a deliberate color-scheme toggle-and-restore
  round trip) that's opt-in behind an environment variable, off by
  default. See [Dms.nix](#modulesdesktopdmsnix) for where that gets
  turned on.

---

## `modules/desktop/Matugen.nix`

One shared attrset, one entry per themed app, each holding the raw
template content (a theme file, a CSS stylesheet, a Windows registry
file, an IDE color scheme) that would otherwise get duplicated inline in
every app's own module. Needed its own explicit option declaration to
actually merge correctly - it's not one of flake-parts' built-in outputs,
so nothing combines it automatically without that (shows up as a
harmless "unknown flake output" notice from `nix flake check` - purely
informational, not a failure).

Every app module reads its own entry straight off the shared flake
output - no extra plumbing needed, same pattern already used for other
shared inputs. Each app module still owns two things itself: writing that
content out to its own file under the matugen templates folder (matugen
doesn't care where this lives, it's this repo's own choice), and
registering the actual output path and any post-processing hook - those
depend on the real user's home directory at runtime, so they can't be
plain shared strings the way the template bodies themselves can.

**The Android Studio template is a function, not a plain string** -
because the color scheme file needs its own name baked into itself in a
couple of places, a value Android Studio's own module already computes
locally for other reasons anyway. Called with that name as an argument
rather than hardcoding the same string twice in two different files.

Every template here except Vesktop's was ported byte-for-byte from
[InioX/matugen-themes](https://github.com/InioX/matugen-themes) - only
the wiring (where it gets written, what it's called) is specific to this
repo. Vesktop's is different: there's no InioX template for it, so it's
the real machine's own hand-curated QuickCSS theme with matugen values
spliced in instead - see its own section for the full story on that one.
