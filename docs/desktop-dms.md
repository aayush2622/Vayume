[Index](CONFIGURATION.md)

---

The bar, the launcher, the lock screen, the notification center - one shell, DankMaterialShell, doing the job four separate GNOME/KDE daemons usually split between them.

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
  [Zed.nix](apps-dev-zed.md)
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
  for Vesktop's Settings > Themes tab instead. [Vesktop.nix](apps-utils-vesktop.md)'s
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
  behavior, `env_reset` on by default), so the script's old `"$HOME/vayume"`
  search always looked in `/root/vayume` - which never exists - and
  failed with "vayume flake not found" every single time the button was
  clicked, regardless of where the flake actually lived. This is also
  why the generation count looked stuck: the plugin only calls
  `refreshData()` after a rebuild exits 0, so a rebuild that never gets
  past this check never refreshes anything, which just looks like "the
  number doesn't update." Fixed by resolving the *invoking* user's home
  directory instead of trusting `$HOME` - `vayumeHomeByUser` builds a
  `case` statement mapping every `config.vayume.users` name to its real
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
  [core.md](core-hardware.md)) actually resolve
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

  `systemd.user.services.vayume-idle-lock` runs `swayidle -w timeout 600
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
  `graphical-session.target.wants/vayume-idle-lock.service`. Not verified
  live - whether it actually fires after ten real minutes of idle needs a
  real session to watch.

---

[← PluginUpdateCheck.nix](core-pluginupdatecheck.md) · [Index](CONFIGURATION.md) · [Niri.nix →](desktop-niri.md)
