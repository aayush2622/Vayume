# Desktop reference

[← Back to index](CONFIGURATION.md)

---

## `modules/desktop/Dms.nix`

**Applies to every user, not just one hardcoded account** - an earlier
version had this hardcoded, and the bug it caused was exactly what you'd
expect: a second account logged into a niri session with no shell
running in it at all.

**The user avatar never showed up anywhere in DMS - not a `.face` bug,
`accounts-daemon` was never running at all.** `Users.nix` already
correctly symlinks `avatar` to `~/.face`; the missing piece was
`services.accounts-daemon.enable`, never set anywhere in this repo. DMS
doesn't read `~/.face` directly - `UserInfoCard.qml` reads
`PortalService.profileImage`, which comes from a live D-Bus query to
`org.freedesktop.Accounts` (`PortalService.qml`'s
`freedesktop.accounts.getUserIconFile`). With the daemon not running,
every query just silently returns empty - no error, just a blank
circle, exactly what showed up in practice. Once it's running,
accountsservice's own `user_reset_icon_file()` (checked directly in its
C source, `src/user.c`) auto-defaults a fresh user's `IconFile` to
`<home>/.face` with no extra wiring needed - `users.mutableUsers =
false`'s `NIXOS_USERS_PURE` env var (set automatically alongside
`services.accounts-daemon.enable`) only blocks the *mutating* D-Bus
methods (`SetRealName`, `SetPassword`, etc., confirmed by reading the
actual nixpkgs patch line by line) - reading the icon file was never
among them.

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
  here - nothing ever needs to rewrite it at runtime.
- **`lockBeforeSuspend = true;` and an idle-timeout lock service - the
  system had neither.** Checked DMS's own settings spec directly for
  what's actually available before building anything: `lockBeforeSuspend`
  exists (defaults `false`, never overridden here before), but there's no
  idle-timeout lock setting at all - only lock-*before-suspend*. Worth
  noticing DMS's own bar ships an "Idle Inhibitor" widget
  (`id = "idleInhibitor"`) that only means anything if something actually
  locks on idle for it to inhibit - the widget existed, the mechanism it
  was built to counteract didn't.

  `systemd.user.services.vayori-idle-lock` runs `swayidle -w timeout 600
  '... dms ipc call lock lock'`, bound to `graphical-session.target` the
  same way DMS's own service is, so it starts under either compositor
  automatically - no niri- or Hyprland-specific wiring needed. swayidle
  isn't sway-specific despite the name; it drives the generic Wayland
  idle-notify protocol both compositors implement, and already respects
  systemd-logind idle-inhibit locks on its own, which is what makes the
  existing widget work against it for free. Verified against the real
  built unit: `ExecStart` resolves to the actual `dms`/`swayidle` store
  paths (not bare `$PATH` lookups, matching this repo's own convention),
  and it's correctly linked into
  `graphical-session.target.wants/vayori-idle-lock.service`. Not verified
  live - whether it actually fires after ten real minutes of idle needs a
  real session to watch.

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

## `modules/desktop/Hyprland.nix`

A second compositor, deliberately mirroring niri's own shape rather than
reinventing one - same gaps/borders/opacity/blur values, same keybind
set (terminal/files/code/browser/`dms ipc call` spawns, focus/move,
workspaces 1-10 with `0` mapped to workspace 10), so switching sessions
at the SDDM greeter changes the compositor, not the muscle memory. Both
`nixosModules.Hyprland` and `homeModules.Hyprland` exist, imported next
to their niri counterparts in `Host.nix`/`Users.nix` - both compositors
are always available, picked per-login, not toggled by a single option.

**DMS needed nothing new to run under it.** It starts as a systemd user
service bound to `graphical-session.target`
([Dms.nix](#modulesdesktopdmsnix)'s `systemd.enable = true;`), which
either compositor's session provides - no `exec-once`/spawn-at-startup
line required, confirmed by checking there's no niri-specific assumption
in how DMS's own `programs.dank-material-shell` module starts it.

**Four places genuinely have no niri equivalent, not just an oversight**
- Hyprland is a dwindle tiler, niri is a scrollable-column WM, and some
concepts don't translate:
- No built-in overview (niri has one; Hyprland needs the `hyprexpo`
  plugin, not pulled in here) - `Mod+Tab` maps to `cyclenext` instead, a
  stand-in, not an equivalent.
- No column operations (`consume-window-into-column`,
  `expel-window-from-column`, preset column widths) - `Mod+J`/`Mod+R` map
  to `togglegroup`/`pseudo`, the nearest dwindle concepts, not real
  matches.
- No built-in screenshotting - niri has `.screenshot`/`.screenshot-screen`
  actions; Hyprland gets `grim`/`slurp` instead (already in
  `environment.systemPackages` via [Host.nix](core.md#moduleshostsnamehostnix)),
  with `Mod+Shift+S` doing the region-select variant.
- Resize is `resizeactive` in pixels rather than niri's
  `set-column-width` proportions - dwindle has no column-proportion
  concept to resize against.

**The brightness binds needed the same device-resolution logic niri's
own already has, not a bare `dms ipc call brightness increment 5`.**
Checked DMS's own default keybind list
(`Common/KeybindActions.js`) rather than assume the device argument was
optional - its own defaults always pass a third argument, even if empty
(`brightness increment 5 ""`). Matched niri's existing, more robust
approach instead of DMS's bare default: resolve the actual backlight
device name via `dms ipc call brightness list | awk '$1 ~
/^backlight:/ {print $1; exit}'`, same shell substitution as
[Niri.nix](#modulesdesktopnirinix)'s own binds, verified against the
real rendered `hyprland.conf` line for line.

Verified against a real build, not just eval: the generated
`hyprland.conf` has 70 `bind*` lines including all 20 workspace binds
(`0` correctly mapping to workspace `10`), and both `niri-26.04` and
`hyprland-0.56.1` show up in `services.displayManager.sessionPackages` -
SDDM will actually offer both.

**`windowrulev2` doesn't work on this pinned Hyprland version - real,
live feedback, not caught by any of the build-time verification above.**
`nixpkgs.hyprland` here is `0.56.1`, and this build/eval-only session has
no way to launch a real compositor session - only Hyprland's own
`--verify-config` (which parses the config for real, but was only run
once, before this bug, not re-run against every later change) would ever
have caught this. `class:REGEX`-style selectors were replaced with a
`match:` prefix - confirmed straight from Hyprland's own source
(`src/config/legacy/ConfigManager.cpp`: a selector token has to
`start_with("match:")`, colon immediately joined to the field name with
no space, then a space before the value - `class:.*` is genuinely
invalid now, not just deprecated-but-working). Fixed to `match:class
.*`, then actually re-verified against the real
`Hyprland --config ... --verify-config` binary this time (not just
`nix build`) - `config ok`, zero parse errors, on the exact config this
repo generates.

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
- **"GTK theme doesn't live-reload" - four attempts, the last one
  correct only after checking a claim the first three all missed.**
  `dank-colors.css` genuinely does get rewritten with fresh colors on
  every wallpaper/theme change (matugen's own `RunUnconditionally: true`
  for these templates, same as everywhere else). What doesn't happen on
  its own is an *already-running* GTK app noticing that file changed
  underneath it and repainting.
  - **First attempt (wrong): toggle the same `gtk-theme` gsettings value
    off and back on.** Matugen's own documented GTK recipe
    ([InioX/matugen-themes](https://github.com/InioX/matugen-themes)).
    Wrong because `gtk_css_provider_get_named()` (the code path this
    actually exercises) caches by theme *name* - a toggle back to the
    *same* name is a cache hit, confirmed directly in
    `gtkcssprovider.c`: `provider = g_hash_table_lookup(themes, key); if
    (!provider) { ... }`. Nothing re-parses when the lookup already
    succeeds.
  - **Second attempt (a real bug, but not this one): `gsettings` was
    silently failing outright.** This machine had zero
    `gschemas.compiled` anywhere (`programs.dconf.enable` only installs
    the `dconf` binary, never `gsettings-desktop-schemas`), so every
    `gsettings` call in the post_hook failed before doing anything,
    behind its own `2>/dev/null`. Genuinely fixed -
    `GSETTINGS_SCHEMA_DIR` in [Host.nix](core.md#moduleshostsnamehostnix)
    - but fixing a broken call doesn't help when the call it enables was
    never going to work anyway.
  - **Third attempt: a genuinely new theme name every run.** Confirmed
    against an independent, far more thorough project solving the same
    problem ([arqueon/dms-theme-sync](https://github.com/arqueon/dms-theme-sync)):
    a real *value change* to `gtk-theme` - not a same-name toggle - is
    the one channel GTK3 has always watched live, the same mechanism
    manual GNOME theme switching has used since before Wayland existed.
    `gtkLiveReloadScript` in `Baseline.nix` builds a fresh, timestamped
    theme directory every matugen run - a name
    `gtk_css_provider_get_named()` has never seen, guaranteeing a cache
    miss - whose `gtk.css`/`gtk-dark.css` `@import` real `adw-gtk3`
    styling first, then `dank-colors.css` last so its accent overrides
    win. This part is correct and still stands.
  - **What the third attempt missed: `@define-color` resolution is
    cascade-wide, not scoped to whichever provider defines it.**
    Confirmed directly in GTK3's own `gtkstylecascade.c`
    (`gtk_style_cascade_get_color`): a symbolic color lookup walks
    *every* provider in the cascade, highest-priority first, and returns
    the first match - a genuine global symbol table, not a per-provider
    one. `~/.config/gtk-3.0/gtk.css` loads once at each process's own
    startup at `PRIORITY_USER` - and at the time, this repo had it
    `@import`ing `dank-colors.css` directly, the same convention
    `gtk-4.0/gtk.css` already used. That put a frozen, once-loaded copy
    of every accent color name at the *highest* priority in the cascade
    - outranking the rotating theme's own `PRIORITY_SETTINGS` provider
    for every name they both define. The rotating-theme mechanism was
    doing everything right - correct file, correct precedence, correct
    cache-miss, confirmed portal backend - and still couldn't win,
    because a higher-priority provider had already claimed those color
    names and would keep winning the lookup for the rest of that
    process's life, no matter how many times the theme name changed.
    This is exactly why GTK4 (fixed first) and GTK3/Lutris (still frozen)
    read as two different problems when they were actually the same
    mechanism failing for two different reasons.
  - **The actual fix: `~/.config/gtk-3.0/gtk.css` now defines zero
    colors.** No `dank-colors.css` import, nothing - an empty file,
    declared explicitly (not left undeclared) so home-manager keeps it
    in a known, controlled state on every rebuild, since a stale
    hand-made symlink at this exact path is what caused this in the
    first place. With no higher-priority provider claiming those color
    names, the rotating theme's own colors are free to win the cascade
    lookup on their own merits. `gtk-4.0/gtk.css` is unaffected by any
    of this - libadwaita doesn't use the same named-theme cache GTK3
    does, so there was never a competing PRIORITY_USER color to conflict
    with, and it still imports `dank-colors.css` so a freshly-launched
    GTK4 app has something to read.
  - **Checked this empirically, not just from source.** A small
    PyGObject script adding two real `Gtk.CssProvider`s to a real
    `Gtk.StyleContext`, one at each priority, both defining
    `accent_bg_color` differently, then asking GTK itself to resolve it
    via `lookup_color()`. With the old behavior reproduced (PRIORITY_USER
    defines the color), GTK resolved it to the PRIORITY_USER value every
    time regardless of what PRIORITY_SETTINGS said - confirming the
    poisoning was real, not a misreading of `gtkstylecascade.c`. With
    `gtk.css` empty, GTK resolved it to the PRIORITY_SETTINGS value
    instead - confirming the fix.
  - **Settled empirically what the documented matugen recipe can and
    can't do.** [matugen-themes#161](https://github.com/InioX/matugen-themes/pull/161)
    ships a far more complete GTK theme (a 50-var gtk3 color template and
    a 121-var gtk4 one, plus full 6251/9973-line stylesheets, versus the
    20 `@define-color`s this repo generated before). Both of its documented
    layouts put the colors in `~/.config/gtk-{3,4}.0/gtk.css` via
    `@import 'colors.css'`. Tested that layout directly with PyGObject
    against real GTK3, resolving a probe color at each step: after init
    `#111111`; after **rewriting the file on disk**, still `#111111`;
    after the recipe's own `gtk-theme ""` → `adw-gtk3-{{mode}}` toggle,
    still `#111111`; after switching to a **brand-new, never-seen theme
    name**, still `#111111`. So `~/.config/gtk-3.0/gtk.css` is read once
    at process start and never again - not by a file rewrite, not by the
    documented toggle, not even by a cache-missing theme change. That
    upstream layout is about theming *completeness*, not liveness: new
    apps get new colors, already-open ones never do.
  - **So the two are complementary, and this repo takes both halves.**
    The vendored theme (`modules/desktop/vendor/matugen-gtk/`, MIT, see
    its README) supplies completeness; the rotating theme supplies
    liveness. GTK4 follows upstream's layout exactly - the full
    `gtk4.css` as `~/.config/gtk-4.0/gtk.css`, its 121-var `colors.css`
    beside it, and the proven `{{mode}}` color-scheme post_hook, since
    libadwaita's re-render is a different code path that does work. GTK3
    deliberately does *not*: the full `gtk3.css` is copied into each
    rotating theme directory instead, with the freshly rendered colors
    written next to it as `colors.css` - which works untouched because
    the stylesheet's own first line is a **relative**
    `@import url("colors.css")`, so it resolves inside the theme dir with
    no path rewriting. The gtk3 color template renders to
    `~/.cache/vayori/gtk3-colors.css`, deliberately *not* into
    `~/.config/gtk-3.0/`, so nothing is ever tempted to `@import` it from
    the PRIORITY_USER file and re-introduce the shadowing bug.
  - **Verified the whole GTK3 chain end-to-end against real GTK**, not
    just that it builds: ran the generated reload script against a
    scratch `$HOME` with known probe colors, then asked GTK itself to
    resolve them after switching to the theme the script had just
    created. `primary` resolved to `rgb(255,0,255)` and `surface` to
    `rgb(18,52,86)` - exactly the values written into that run's
    `colors.css` - where both had been unset beforehand. Theme creation,
    the named-theme lookup, the relative import, and color resolution all
    confirmed working together, with no CSS parse warnings from the
    171KB stylesheet.
  - **Still not verified against an actual live GTK window.** Every
    piece up to this point - script executes, correct file precedence,
    correct pruning across repeated runs, valid shell syntax, and now
    the cascade-priority conflict itself - was checked directly against
    real source and real builds. Whether the portal genuinely forwards
    the theme-name-change notification on this exact setup, and whether
    an already-open Lutris window actually repaints, can only be
    confirmed by watching it happen in a real session.
  - **GTK4 does not get the theme-name trick.** libadwaita ignores the
    legacy `gtk-theme` key entirely for styling - confirmed independently
    by dms-theme-sync's own "Limits" section. It gets the portal
    color-scheme toggle instead (default off then back to whatever it
    was), a different, genuinely-watched code path - real, and does
    force a re-render, confirmed against dms-theme-sync's own stated
    limits for what that channel can and can't do.
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
- **Papirus and its accent-matched folder recoloring were removed.**
  The recoloring tool (`papirus-folders`) needed a writable per-user copy
  of the whole icon set (rsync'd out of the read-only store, ~300,000
  files) rebuilt on every activation - that copy was the direct cause of
  the 1-2 minute boot stall traced down earlier (see
  [Users.nix](core.md#modulescoreusersnix)): the rsync routinely
  exceeded `TimeoutStartSec`, which killed the whole activation partway
  through and skipped everything after it, including the step that
  seeds DMS's wallpaper state. `iconTheme` is `Adwaita` now
  (`pkgs.adwaita-icon-theme`, already a system package) - no writable
  copy, no per-boot rsync, no accent-matched folder colors. If that
  trade is ever worth revisiting, the old mechanism is intact in git
  history on the commit before this removal.

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
