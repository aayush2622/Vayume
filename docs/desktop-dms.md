[Index](CONFIGURATION.md)

---

The bar, the launcher, the lock screen, the notification center - one shell, DankMaterialShell, doing the job four separate GNOME/KDE daemons usually split between them.

## `modules/desktop/dms/`

**Only built when `vayume.desktop.shell` is `dms`.** The whole module and every plugin and patch file under it sit behind that check, so choosing Noctalia or Caelestia drops DMS, its plugins and its patched package from the build. See [Shell.nix](desktop-shell.md).

**The idle lock and the media inhibitor are no longer here.** They were DMS-only for no reason and moved to `Shell.nix`, where they serve every shell. DMS's own `lockBeforeSuspend` stays on; the idle service also locks before sleep, which is harmless when both fire.

**screenshotPlus captures are kept in `~/.cache/screenshot-plus`.** Upstream writes each capture to `/tmp` and deletes it ten seconds after copying it to the clipboard, so a clipboard-history entry pasted later pointed at a file that no longer existed. The plugin source is copied and patched to use the cache directory and to skip the delete; the folder is created on activation and is not pruned.

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

**`Dms.nix` only carries plugins with nothing custom behind them.**
`dankAsusControlCenter`, `cavaVisualizer`, and `tor` each have real custom
Nix - a patch, or a locally-authored QML widget - and get their own file
under `modules/desktop/dms/plugins/`, `import`ed by `Dms.nix` itself
rather than declared as their own top-level `flake.nixosModules.*`
entry - the module system merges their
`programs.dank-material-shell.plugins.<name>` definitions into the same
option `Dms.nix` sets for everything else. Every plugin declared directly
in `Dms.nix` is a plain `enable`/`settings` passthrough with nothing to
split out. The dms-shell package itself is patched too, in
`_shellPatch.nix` - split out of `Dms.nix` for the same reason: it's a
self-contained block, not something every other option in `Dms.nix`
needs to read. The actual patch machinery behind all of this -
`registryPlugins`, the `assertPatched`/`assertPatchedLine`/
`mkPatchedPlugin` helpers, and the `audioIsPlayingScript` shared by both
the `cavaVisualizer` plugin's own watchdog patch and `_shellPatch.nix`'s
dms-shell watchdog patch (below) - lives in `modules/lib/DmsPlugins.nix`,
so none of the plugin files need to re-derive any of it themselves.

**These plugin/patch files are `imports`, not independent flake modules -
on purpose.** They used to each declare their own
`flake.nixosModules.DmsPlugin<Name>`, which meant `Host.nix` needed one
import line per file (seven, for `Dms.nix` plus its six pieces) even
though every one of them only ever gets used together, always in the
same combination. Now each file is a plain NixOS module value (no
`flake.nixosModules.*` wrapper) with an underscore-prefixed name -
`_shellPatch.nix`, `plugins/_tor.nix`,
`plugins/_cavaVisualizer.nix`, `plugins/dankAsusControlCenter/_dankAsusControlCenter.nix`
- so import-tree's own auto-discovery skips them (same convention as
`_hardware.nix`/`_config.nix`), and `Dms.nix`'s own `flake.nixosModules.Dms`
pulls them in via a plain `imports = [ ./_shellPatch.nix ./plugins/_tor.nix ... ];`
list instead. `Host.nix` now imports just `self.nixosModules.Dms`. The
underlying NixOS module-merging behavior is identical either way - every
file still separately sets its own slice of `home-manager.users.<name>.*`,
and the module system still merges them all together the same way it
always has; only how they're *discovered* changed, from "seven names in
a flat, global namespace" to "one name, with an explicit `imports` list
describing what it's made of."

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
  plain terminal first. Upstream (`shazzaam7/DankAsusControl`) only
  implements the DankBar widget interface (`horizontalBarPill`/
  `popoutContent`) - no `capabilities` field in its `plugin.json` at all,
  and nothing for the control center. DMS's control center instead looks
  for a separate `ccWidget*`/`ccDetailContent` interface (see
  DankMaterialShell's own `PLUGINS/ControlCenterDetailExample`), so the
  patch inserts a `CcWidget.qml` block - a second copy of
  `popoutContent`'s body against that interface, since QML Components
  aren't values the two could share - right before the file's final
  closing brace, and declares the `capabilities` DMS's own example
  plugin uses for it fresh, since upstream's `plugin.json` has none to
  merge into. Tapping the pill cycles the power profile, the same
  one-tap-cycle convention DMS's own built-in toggle pills use.
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
- **`spotifyMatugen` was replaced by `musicTheme`.** It locked DMS's
  dynamic color to the album art of the playing track, but only for a
  player whose MPRIS name contains "spotify" (checked in its
  `SpotifyMatugen.qml`), so it never matched Spotifast
  (`org.mpris.MediaPlayer2.spotifast`). Music Theme does the same for any
  MPRIS player; the two would also both drive the theme at once, so only
  the new one is enabled. See [Spotifast.nix](apps-utils-spotifast.md).
- **`mediaUseAlbumArtAccent = true` is required for `musicTheme`.** The
  plugin themes from `MediaAccentService.accent`, which is the color
  quantized from the cover only when that DMS setting is on; when it is
  off (the DMS default) the accent is just `Theme.primary`, so the plugin
  re-applied the same color for every track.
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
**Rebuild/GC integration lives in its own file, `modules/desktop/dms/_rebuild.nix`**,
`import`ed by `Dms.nix` the same way the plugin files are - the sudoers
`NOPASSWD` rule, the two underlying scripts, and the stable
`vayume rebuild`/`vayume gc` bare commands, all pulled out of `Dms.nix`
proper since none of it is really DMS-specific (it's what any GUI, or a
person's own terminal, needs to trigger a rebuild without a password
prompt) - see [core-vayume-config.md](core-vayume-config.md) for the
stable-wrapper rationale.

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
  bare one, so `_hardware.nix`/`_config.nix` (gitignored, see
  [core.md](core-hardware.md)) actually resolve
  instead of looking "missing" through git's tracked-files-only view of
  the repo.
- **`controlCenterWidgets`' `plugin_tor` and `plugin_dankAsusControlCenter`
  entries** refer to the plugins [Network.nix](system-network.md) and
  this file's own `dankAsusControlCenter` (above) install - DMS looks
  these up by `id.replace("plugin_", "")` in its own `DragDropGrid.qml`,
  hence the bare plugin id with the `plugin_` prefix stripped. DMS only
  actually loads a plugin whose id has `enabled: true` in
  `plugin_settings.json` (generated solely from
  `programs.dank-material-shell.plugins`) - dropping a plugin's files on
  disk alone leaves it installed but never loaded. See
  [Network.nix](system-network.md) for why Tor's actual service, iptables
  rules, and CLI live outside DMS entirely.
- **DankSession** (window-session restore - remembers open windows,
  workspaces, and Hyprland scrolling-layout geometry across logout/
  login) was fully wired in Nix from early in this repo's history -
  `services.dankSession` (the backend daemon, `autoStart = true`) and
  `programs.dank-material-shell.plugins.dankSession` (the bar widget's
  QML) both enabled, matching upstream's own recommended Home Manager
  config verbatim - but the widget was never actually added to any bar
  section, so there was nothing to click. Added to `rightWidgets`,
  unprefixed (`id = "dankSession"`, matching `dankAsusControlCenter`'s
  own plain id in this same list - bar widget ids don't take the
  `plugin_` prefix that `controlCenterWidgets` entries do, e.g.
  `plugin_tor` above). **Hyprland-only per DankSession's own README** -
  window/scrolling-geometry restore isn't implemented for niri yet, so
  the widget will show far less on a niri session (this repo runs
  both). Automatic *saving* runs as soon as the daemon's up; automatic
  *restoration* stays opt-in on purpose - upstream's own guidance is to
  configure explicit application rules in
  `~/.config/danksession/config.json` (DankSession never derives launch
  commands from a running process, only from rules you write), use the
  widget's **Preview**/`danksession restore --dry-run` to check what
  would happen, and only then flip "Restore after login" in the
  plugin's own settings - that toggle is live app state, not something
  this repo's Nix config should set on someone's behalf.
- **The blurred-wallpaper layer only ever showed on niri, never on
  Hyprland, regardless of `blurredWallpaperLayer`.** Not a config bug -
  DMS's own `shell.qml` hardcodes `active: SettingsData.blurredWallpaperLayer
  && CompositorService.isNiri`, gating the whole layer to niri no matter
  what the setting says. Patched (same technique as the cava patches)
  to `(CompositorService.isNiri || CompositorService.isHyprland)`.
  Requested despite the real risk that it visually stacks with
  Hyprland's own native compositor blur (`decoration.blur` in
  [Hyprland.nix](desktop-hyprland.md)) rather than replacing it - DMS's
  blur here is entirely self-contained (a GPU shader over a captured
  wallpaper texture, no compositor protocol involved), so nothing
  *stops* it from rendering under Hyprland's own blur too; whether the
  combined look is actually wanted needs eyes on the real screen, not
  assumed from source alone.
- **Cava stopped attaching at all, even with genuine active playback -
  the fixed `pw-dump`/`jq` detection script had its own bug.** Its
  `!= ""` guard, meant to skip a failed name lookup, also silently
  excluded any REAL client that legitimately reports an empty
  `application.name`/`node.name` - confirmed live against `fastpotify`
  (this repo's Spotify client), whose PipeWire node has both set to
  `""` (checked directly via `pw-dump`, not assumed). A blank name is
  still a real, active client - the only name that should ever be
  excluded is literally `"cava"` itself, to avoid a self-referential
  match. Fixed by dropping the `!= ""` half of the guard.
- **`cavaVisualizer`'s config file only lists an estimated `curvePoints`/
  `curveLineWidth` (`24`/`3`)** - read off slider handle position in a
  screenshot, not the actual values. Confirm/correct these once the real
  numbers are available.
- **Bluetooth dual-connect couldn't hand off audio to the phone - two
  orphaned `cava` processes were the real cause, not JBL firmware.** This
  plugin's own widget and DMS core's `enableAudioWavelength` each run
  their own `cava`, and both were permanently capturing the Bluetooth
  sink's *monitor* port (to draw the visualizer) regardless of whether
  anything was actually playing. PipeWire won't idle-suspend a sink while
  any client - even a monitor-only capture client like cava - stays
  attached, and BlueZ won't release the A2DP media transport while
  PipeWire's local representation of the sink stays un-suspended. So
  cava, just by existing, was the one thing keeping the Bluetooth link
  busy enough that it never handed off to the phone. Confirmed live by
  directly attaching/detaching cava from the Bluetooth sink and watching
  handover succeed or fail in lockstep - not a guess.

  The fix is `audioIsPlayingScript` (shared by both patches below): exit
  0 if the current default sink has a genuine, non-cava active playback
  link right now, exit 1 otherwise. It's deliberately keyed on "is
  anything ELSE already keeping this sink busy," not amplitude/silence -
  if something else holds the sink open, cava piggybacking costs
  nothing; if nothing else does, cava must not become the sole reason the
  sink can't idle-suspend. A plain silence check would still leave cava
  as that sole reason on a truly idle Bluetooth sink.

  It matches on `pw-dump`'s numeric node ids, not `wpctl status`'s
  display names - `wpctl`'s own text turned out not to be internally
  consistent: the internal speaker shows as "Raptor Lake-P/U/H cAVS
  Speaker" in the Sinks list but gets abbreviated to just "Speaker" in a
  Streams link line (`> Speaker:playback_FL [active]`). A first version
  of this script parsed exactly that display text and silently never
  matched for the internal speaker - it only ever happened to work for
  the JBL headphones, whose short and long names coincide. `pw-dump`'s
  link objects carry `link.output.node`/`link.input.node` as plain node
  ids instead, immune to this whole class of display-string mismatch.
  Found and fixed by instrumenting the actual running watchdog (a
  filesystem side-effect counter, since plain `console.log` calls from
  inside a `Process.onExited` handler never showed up in DMS's own logs
  for reasons never fully explained) and confirming the poll loop was
  firing correctly but the name match inside it wasn't.

  **The `cavaVisualizer` plugin controls its `cava` process entirely by
  imperative assignment**, unlike DMS core's own clean declarative
  `running: <expr>` binding - `configWriter.onRunningChanged` sets
  `cavaProcess.running = true`, and the plugin's own `rebuildTimer`/
  `retryTimer` do too. A plain `&& root.playbackActive` added to a
  binding wouldn't even apply here, and worse, the existing retry-timer
  crash-recovery logic would actively fight an intentional stop: it
  treats any stop where `configWriter` also isn't running as a crash and
  reschedules a restart within 2 seconds, undoing the watchdog's own
  stop. Both the starting condition and that retry guard have to be
  patched explicitly for the watchdog to actually hold. The watchdog
  reconciles `playbackActive` and cava's running state on *every single
  poll*, rather than reacting only to `playbackActive`'s `onChanged`:
  the widget's own unpatched `Component.onCompleted` always kicks cava
  off once at startup regardless of whether anything's actually playing
  yet, and an `onChanged` handler would never fire (never see a
  transition) if playback simply stays inactive the whole time - leaving
  that initial unconditional start never corrected. Reconciling
  unconditionally on every poll is correct no matter the starting state.

  Patching in the cava config's `[input]` section (`method = pipewire`,
  `source = auto`) used plain bash single-quoted literals inside the
  build script, rather than building the replacement text as a Nix
  string - the search/replace target is JS string-concatenation source
  (`"...\n" +` fragments), and single-quoting sidesteps stacking Nix's
  own escaping on top of JS's. `source = auto` is only safe now that
  `running` is actually gated on real playback activity - before, cava
  had no `[input]` section at all and fell back to whatever pipewire
  picked as its default capture source.

  **DMS core's own `CavaService.qml` got the same watchdog**, patched
  into `inputs.dms.packages.${system}.dms-shell` rather than a small
  plugin - a much bigger, riskier target. `source=auto` here is what lets
  cava actually follow whatever's currently playing, Bluetooth included,
  since each start re-resolves "auto" fresh and the watchdog Timer is
  exactly what triggers a fresh start when playback resumes. The new
  Timer/Process pair is inserted as a sibling of the existing
  `cavaProcess`, not nested inside it - Quickshell's `Process` type isn't
  documented as supporting arbitrary child objects the way a plain `Item`
  does. That Timer's own `running` condition was deliberately written to
  *not* be textually identical to the old `cavaProcess.running`
  condition it's extending: a first version of this patch used one
  blanket search/replace for both, which matched the Timer's own
  `running:` line too and silently deadlocked the whole thing - once
  `playbackActive` went false, the Timer doing the polling stopped right
  along with it, so nothing was left running to ever notice playback
  resume. The poll loop has to stay unconditional; only `cavaProcess`'s
  own `running` gets the `playbackActive` gate.

  Patching the whole `dms-shell` package needed a real `cp -r`, not
  `pkgs.symlinkJoin` (which failed with completely empty, unreadable
  build logs, never root-caused) - and not a shallow copy either:
  `bin/dms` is a wrapper script that hardcodes its *own* original store
  path in its `exec ... -c <path>/share/quickshell/dms` line, verified by
  reading it directly. A first patch attempt copied `share/quickshell/dms`
  but left `bin/dms` untouched, and it silently kept loading the
  unpatched QML from the original path. The build's own verification step
  had to check for the OLD path's *absence* rather than the new patch's
  presence, written as `if grep ...; then exit 1; fi` rather than
  `grep ... && { exit 1; }` - the latter's own exit status (1, on the
  successful/expected path where grep finds nothing) becomes the whole
  script's exit status when it's the last command run, failing the Nix
  build even when the patch worked correctly.
- **`dms.service` failed to start after a real `nixos-rebuild switch` -
  `203/EXEC` on `bin/dms-shell`, a binary that doesn't exist (only
  `bin/dms` does).** `pkgs.runCommand` doesn't carry over `meta` from
  the package it copies, so `dmsShellPatched` lost the original
  `dms-shell` derivation's `meta.mainProgram = "dms";` - confirmed by
  the build's own warning ("does not have the meta.mainProgram
  attribute... assume the main program has the same name"). Without it,
  `lib.getExe` (used by DMS's own home-manager module to build this
  service's `ExecStart`) falls back to guessing the binary is named
  after the *package* (`dms-shell`) instead of reading the real one off
  disk. Silent for a long stretch of iteration because that whole time
  used lightweight `systemctl --user restart` plus manually-edited
  `ExecStart` lines to test each patch quickly, never re-running a full
  `nixos-rebuild switch` that would let home-manager regenerate the unit
  file from its own (buggy) `getExe` call - so the bug was latent until
  the first real rebuild after `dmsShellPatched` existed. Fixed by
  passing `meta.mainProgram = "dms";` through explicitly on the patched
  derivation.
- **That same rebuild also failed home-manager's own collision check**
  on `~/.config/DankMaterialShell/plugins/cavaVisualizer` -
  "existing file would be clobbered." Also self-inflicted: a manually
  created `ln -sfn` symlink from the same live-testing above, used to
  swap in test builds of the plugin without a full rebuild, pointed at
  a specific store path home-manager itself didn't manage. Deleting the
  stray symlink (it was never real data, just a testing shortcut) let
  home-manager place its own back on the next activation.
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
- **A scoped sudo rule** lets `wheel` users run two fixed root scripts
  without a password - `vayume rebuild` (a `nixos-rebuild switch` of
  the discovered repo) and `vayume gc` - keyed on their exact store
  paths, so no arguments can be smuggled in. Not blanket passwordless
  sudo, just enough for the panel's buttons to work without a TTY to
  type a password into.
- **`vayume gc` keeps the newest 5 system generations.** It used to be
  `nix-collect-garbage -d`, which deletes *every* old generation - one
  click and there was nothing left to roll back to. Now it deletes
  generations older than the newest 5, collects garbage, then runs
  `switch-to-configuration boot` so the GRUB menu stops listing the
  generations that were just deleted (booting one of those would fail).
  The weekly `nix.gc` in `Host.nix` (older than 30 days) is unchanged.
- **The app-launcher icon theme** is a separate icon pack (MaterialOS)
  fetched straight from its own repo (not in nixpkgs), scoped to DMS's
  launcher only via an env var DMS specifically documents for this - it
  doesn't touch Nautilus or anything else system-wide.

  **A `home.activation` step mirrors hicolor into it, because the
  launcher's real icon-rendering path silently ignores hicolor
  otherwise.** The launcher grid (`DankLauncherV2`/`ResultItem.qml`)
  doesn't go through DMS's own `IconThemeService.qml` (a bespoke QML
  reimplementation of the Inherits-chain walk, which resolves hicolor
  fine) - it goes through a shared `AppIconRenderer` that calls
  `Quickshell.iconPath()`, a thin wrapper over Qt's own native
  `QIconLoader`. Verified directly against the live session with
  `qs -p` one-off scripts and `--log-rules "*.debug=true"`: even an
  isolated, otherwise-valid theme literally named "hicolor" - freshly
  authored, `Hidden=` stripped, containing nothing but one known-good
  icon - still resolves to nothing through this path, while the exact
  same file under any other theme name works. So every app whose icon
  only lives in hicolor (most third-party ones MaterialOS doesn't
  itself curate - Zen, Vesktop, Lutris, Zed, ...) rendered as a blank
  letter avatar despite genuinely having a usable icon on disk.
  `home.activation.materialOSIconFallback` in `Dms.nix` copies
  MaterialOS's own icons into a user-local `~/.local/share/icons/MaterialOS`
  first (so its curated icons still win by filename for what it
  explicitly covers - Spotify, Android Studio, ...), then overlays the
  real, already-merged `~/.nix-profile/share/icons/hicolor` on top and
  keeps *its* far more complete `index.theme` (hicolor declares every
  standard size up to 512px, `@2x` variants, and `scalable/`; MaterialOS's
  own only goes up to 128px) - a size hicolor ships but MaterialOS's
  index doesn't declare is a real file sitting in a bucket the theme
  spec says to ignore. Both copies use `--no-preserve=mode`, since both
  source trees are read-only Nix store paths and the second copy needs
  to write into what the first one created. It is re-derived from
  scratch (`rm -rf` first) rather than merged incrementally, but only when
  something it copies from changed: a stamp file inside the theme holds the
  icon package, the three profile paths and the modification times of the
  local `hicolor` and `pixmaps` folders, and matching activations skip the
  copy (0.31 s at boot, where home-manager holds up the login screen).

  **Later extended, because `~/.nix-profile` is only one of the places
  icons live.** System packages (Waydroid, waydroid-helper, CUPS, Vim,
  pavucontrol, nvidia-settings, ROG Control Center) install into
  `/run/current-system/sw/share/icons/hicolor`, home-manager packages can
  land in `/etc/profiles/per-user/$USER`, Steam games and AppImages write
  to `~/.local/share/icons/hicolor`, and some apps only ship a flat
  `share/pixmaps` icon (htop, ProtonUp-Qt). The activation now copies
  hicolor from all of those too, and every `pixmaps/*.png|svg` into
  `scalable/apps/`, all with `cp -n` so nothing already there (MaterialOS's
  own icons, the `~/.nix-profile` hicolor) is overwritten. It also adds
  `Inherits=Papirus-Dark` to the merged `index.theme` and installs
  `pkgs.papirus-icon-theme`: unlike hicolor, an inherited theme *is*
  followed by `Quickshell.iconPath()`, which covers generic names no app
  ships itself (`x-office-calendar` for ikhal, `wine` for Protontricks).
  Checked with an offscreen quickshell resolving every visible app's
  `Icon=` against a scratch copy built by the same script: 26 of 41
  resolved before, 40 of 41 after. The last one, the Hytale launcher,
  names an icon its package doesn't ship; `_hytale.nix` now installs
  Papirus's game-controller icon under that name. Steam games and
  AppImages installed after the last rebuild only get their icons on the
  next rebuild, since the copy runs at activation.
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

  swayidle only counts Wayland idle inhibitors, and music players don't
  create one, so it locked in the middle of a song.
  `systemd.user.services.vayume-media-inhibit` runs
  `wayland-pipewire-idle-inhibit`, which holds a Wayland idle inhibitor
  while any PipeWire output stream is playing (after five seconds, its
  default), so swayidle waits until playback stops. It follows audio, not
  MPRIS, so calls and browser video count too.

**Vayume Settings** is no longer a DMS plugin: it is a standalone Quickshell app (see [desktop-settings.md](desktop-settings.md)) that works under every shell.

### Where things go

Every page has one subject, and each module says which page its settings
and buttons belong on, so nothing is placed by a list in the QML:

| Page | What is on it |
| --- | --- |
| Home | greeting, rebuild state, counts for apps, development, users and free disk space, shortcuts |
| Appearance | font, cursor, the **Top bar** style |
| Desktop pet | an animated preview of the chosen skin, then **Your pet**, **Behaviour**, **Placement** |
| Users | accounts, groups, passwords, per-user packages |
| Applications | apps by section (Internet, Music, Files, Gaming, System, Security, Containers) with their icons, each app's own options and buttons underneath it (Waydroid's reinstall and repair are under Android (Waydroid) in Containers) |
| Development | languages, editors, tools, with icons and which editors support each language |
| Default apps | which app opens what |
| Network | **DNS**, **Tor**, **Privacy** |
| Performance | **Kernel**, **Tuning**, and the boot time report |
| Storage | a disk usage bar, **Reclaim space** (disk usage report, clean caches, old generations), **Build output** |
| Updates | rebuild, everything waiting for a rebuild, **Checks** (`_config.nix` and plugin updates), and anything that names no page |
| About | the host and its repository |

- **Settings** are placed by their group: `vayume.settingsGroups.<name>`
  takes `page` and `order` (the card's position on that page) besides
  `icon` and `description`, and `vayume.settingsMeta.<path>` takes `order`
  for the row's position inside its card. `settings.json` carries them as
  `groupPage`, `groupOrder` and `order`.
- **Buttons** are placed by their command: a `panel` in
  [`vayume.commands`](core-commands.md) takes `page` and `group` (the card
  title; unset uses the page's own tools card). A panel with `app` goes under
  that app in Applications instead, as before.
- **Nothing gets lost.** A setting or button whose page is unset or unknown
  lands on Updates, so a new module's option still shows up before anyone
  decides where it belongs. `pageOfSetting` and `pageOfAction` on the widget
  are the one place this rule lives; `PageOptions.qml` draws a page's
  settings cards and tool cards from it, and every page except Home, Users,
  Development, Default apps and About is mostly that component.
- **Apps** carry their presentation in `flake.appMeta.<Name>` in the app's
  own file: `label` (the name shown, such as "Zen Browser" for
  `ZenBrowser`), `description` (the line under it), `icon` (a freedesktop icon name),
  `symbol` (a Material symbol used when the icon theme has no such icon) and
  `section`. `vayume config apps list` and `development list` include them.
  Icons are looked up with `Quickshell.iconPath(name, true)`, so they come
  from the app itself once it is installed and from Papirus for most of the
  rest; `tests/eval.sh` checks every app has an entry.
- **Tool rows** show the command's icon, label and description. The
  `vayume ...` command line is no longer printed under each one, and
  commands marked `confirm` carry a quiet "Asks first" tag; they still need
  a second click within five seconds.

Running a button reuses the rebuild machinery: `runCommand` in the widget
starts the process, streams stdout and stderr into the same log at the
bottom of the window, and shows "<label> - running..." then "<label>
finished." or "failed (exit N)" in the sidebar's status card. Only one command runs at a
time, and the buttons and the status card's Rebuild button are disabled while one
does. The disk figures on Home and Storage come from `df` and are read
again after every command, so a cleanup shows its effect straight away.
"Check _config.nix" is the place to catch a bad edit before a
rebuild, since settings edits are not evaluated when saved.

The pet preview draws the sprite sheets the [Pet module](desktop-pet.md)
puts in `/etc/vayume/pet-skins` (every skin, plain and kuroneko), cycling
through sitting, washing, walking and napping with the skin, colours and
name that are saved, so a change shows before the rebuild.

### Bar styles

`vayume.desktop.barStyle` picks between two looks for the top bar, `classic`
(the default) and `m3`. It is an ordinary `vayume.*` option, so it shows up in
Vayume Settings under **Appearance → Top bar → Bar style** and switches on
the next rebuild; in `_config.nix` it is `vayume.desktop.barStyle = "m3";`.

The profiles live in `modules/desktop/dms/_barProfiles.nix` as overrides on
top of the settings in `Dms.nix`: `shell` is merged into DMS's global
settings and `bar` into the main bar's entry in `barConfigs`. `classic` is
empty, so it produces exactly the settings used before the option existed
(checked by diffing the generated `settings.json`). `m3` turns the screen
frame off (with the frame on, DMS draws the bar inside the frame surface),
gives every widget its own `surfaceContainerHigh` pill at 80% opacity on a
fully transparent bar, and raises the shell-wide corner radius from 12 to 16.
Its spacing values were read off DMS's own bar settings (Edge Spacing 0, Size 8,
Padding 14, Bar Inset Padding 6, no exclusive-zone offset or length padding),
with slightly larger text and icons. The option and its
settings label are declared in `_barStyle.nix`.

Both were checked by rendering DMS's own `Frame` and `DankBar` components in a
headless sway session with a copy of the generated settings, over the
wallpaper.

### Desktop widgets

Besides the Pure Lyrics and Cava Visualizer widgets, four of this repo's own
DMS desktop-widget plugins make the desktop: two columns, clock over weather on
the left and now playing over system on the right, both ending just below the
lyrics so the bottom stays clear for the visualiser:

| Widget | Place | What it shows |
| --- | --- | --- |
| `plugins/vayumeClock` | top left | the lock screen's stacked hour and `primary` minutes, AM/PM chip, full date and greeting, no card |
| `plugins/vayumeWeather` | left, under the clock | current temperature, feels-like and condition in a tonal icon badge, and the next four days (`WeatherService`); the city is left out so screenshots don't give away where you are |
| `plugins/vayumeSystem` | right, under the media card | wavy rings for CPU, memory and battery (`DgopService`, `BatteryService`); CPU and memory turn `error`-red above 90%, battery only when low and not charging |
| `plugins/vayumeMedia` | top right | the active player (`MprisController.activePlayer`) in a card whose background is the album art blurred under a scrim, the art itself, title, artist, a wavy progress bar, times and an M3 Expressive button group |

**Hiding them.** `Mod+D` (both compositors) runs `vayume widgets toggle`,
which is also a button on the Appearance page of Vayume Settings. It
disables every enabled desktop widget through DMS's own
`desktopWidget disable <id>` IPC and stops the `vayume-pet` service,
writing what it turned off to `$XDG_RUNTIME_DIR/vayume-hidden-widgets`; the
next press turns exactly those back on, so a widget you had switched off
yourself stays off. `hide`, `show` and `status` do what they say. Whether
they count as hidden is checked against DMS's current list rather than
trusted from the file, so after DMS restarts (which brings every widget
back) one press hides them again instead of doing nothing. `Mod+H` hides
and shows the top bar with `dms ipc call bar toggle index 0`.

Both only last until DMS restarts or the next rebuild: `settings.json` is a
read-only link into the store, so DMS keeps the change in memory and its
save fails quietly. That is the intended behaviour for a quick clean
screen, and nothing needs undoing afterwards.

**The media progress bar can be dragged.** It follows the Material 3
Expressive wavy style: the played part is a sine wave that moves while the
track plays and flattens when paused, a gap and a rounded handle mark the
position, and the rest is a flat track with an end dot. Pressing or dragging
anywhere on it previews the new time in the time label and seeks on release
(`player.position`, only when the player reports `canSeek` and a length).
The position is read every half second rather than only on MPRIS signals,
which Quickshell does not emit for a steadily advancing position. The play
button is a wider pill that squares off while playing and springs back
when paused; every button tightens its corners while pressed.

`WavyBar.qml` and `WavyRing.qml` live in `plugins/vayumeCommon/` and are drawn
on a `Canvas`. A DMS plugin is loaded from its own directory, so
`_vayumeWidgets.nix` copies them into each plugin that uses them
(`withCommon`) instead of importing across plugins. They are registered in
`plugins/_vayumeWidgets.nix` and placed by entries in `desktopWidgetInstances`,
and can be moved or resized from DMS as usual (right-drag). The desktop pet is
not a DMS widget; see [desktop-pet.md](desktop-pet.md).

**Positions are seeded into `session.json`.** DMS keeps instance positions in
`SessionData.desktopWidgetInstancePositions` (the machine-specific
`~/.local/state/DankMaterialShell/session.json`), not in `settings.json`. It
imports the `positions` written in `settings.json` only while that session
key is still empty, so a widget added later would appear centred at 200x200.
`home.activation.seedDesktopWidgetPositions` merges the positions from
`desktopWidgetInstances` into `session.json` for IDs it doesn't have yet; the
existing entries win in the merge, so a widget you dragged stays where you put
it. DMS watches that file, so the change shows up without a restart.

Checked by rendering DMS's `DesktopWidgetLayer` with the real plugins in a
headless sway session over the wallpaper.

### Lock screen

DMS's own lock screen UI is replaced by the Vayori one, the same design as
the [login screen](desktop-sddm.md). `_shellPatch.nix` copies
`modules/desktop/lockscreen/vayori/` and
`modules/desktop/lockscreen/VayoriLockContent.qml` into the patched shell's
`Modules/Lock/`, then swaps `LockScreenContent` for `VayoriLockContent` in
`LockSurface.qml` (the real lock) and `LockScreenDemo.qml` (the preview in
DMS Settings), asserting both swaps so a DMS update that moves them fails
the build instead of silently keeping the old screen.

**Only the drawing changed.** `VayoriLockContent` has the same properties,
signals and functions `LockSurface` uses (`pam`, `passwordBuffer`,
`passwordEdited`, `unlockRequested`, `resetLockState`,
`focusPasswordField`, `unlocking`), sends every keystroke to DMS's shared
password buffer, starts DMS's own `Pam` on Enter, and shows its
`state`/`lockMessage`; the session only unlocks when that `Pam` object
says so. The `loginctl.lockerReady` handshake is copied as-is: it is sent
only once the compositor reports the session lock as secure, so the sleep
inhibitor is not released while the desktop could still be on screen. The
lock screen settings in DMS still apply - the lock wallpaper override,
the lock font, 12/24h clock, show weather, show media player, show power
actions, and the notification mode (off by default; count, app names, or
full content).

What it shows beyond the login screen: the current wallpaper for that
monitor with the matugen colours, weather top left, battery, network and
the connected Bluetooth device as chips, a media card with controls, and
the notification card. Checked by loading `VayoriLockContent` from the
built package in a headless sway window with live DMS services and a stub
PAM object (typing, busy spinner, failed attempt); the real
`WlSessionLock` path was not exercised there.

**Typing goes straight to the password field.** `LockSurface` is a
`FocusScope` whose content item has `focus: true`; `VayoriLockContent` was a
plain `Item`, so its `focus: true` and the scene's competed in that one scope
and the field never got active focus until clicked. It is a `FocusScope` now,
the scene focuses the field when it appears and whenever the field is enabled
again after a failed attempt, and a key typed while something else has focus
is moved into the field.

## Notes from the code

Explanations that used to be comments in the source files.

### `modules/desktop/dms/plugins/dankAsusControlCenter/CcWidget.qml`

- Above `ccDetailHeight: 480`: DragDropGrid's own detailHeight.js sizes the popup from ccDetailHeight, defaulting to 250 (PluginComponent.qml) when a plugin doesn't set it - our content (profile picker, battery slider, GPU mode buttons) runs taller than that, so it was getting clipped and GPU Mode - being last - never showed at all.
- Above `onCcWidgetToggled: { }`: DMS's CompoundPill (used whenever ccDetailContent is set) has two independent click zones: the icon tile fires ccWidgetToggled, the text label fires ccWidgetExpanded and opens ccDetailContent below. There's no real on/off state here to toggle - profile switching belongs in the detail view where you can see and pick a specific one, not behind a silent cycle-and-toast on a stray icon tap.


## Light mode

Every app theme was audited for hard-coded dark values; the ones found were changed so switching the DMS dark/light toggle retints everything through the normal matugen run (its post hooks reload GTK3 through a fresh named theme, GTK4 through the `color-scheme` gsettings key, and the file-watching apps pick up their regenerated files):

- `terminalsAlwaysDark` is `false`, so kitty follows the mode instead of staying dark on a light desktop.
- GTK3 no longer forces `gtk-application-prefer-dark-theme`; the mode comes from the generated colors.
- Zed uses `mode = "system"` with `DankShell Light` and `DankShell Dark`, both of which the matugen template already generates.
- Zen's `prefers-color-scheme.content-override` is `2` (follow the system) instead of `0` (always dark).
- The Android Studio theme template writes `"dark": {{is_dark_mode}}` and no longer names `Islands Dark` as its parent, since matugen templates can't pick a parent by mode. Not checked in Android Studio itself.
- VS Code auto-detects the system color scheme (`window.autoDetectColorScheme`) and switches between the DMS extension's `(Dark)` and `(Light)` themes; the single `Dynamic Base16 DankShell` entry is declared `vs-dark`, so its window chrome stayed dark in light mode.
- Already mode-aware and left alone: kitty (`dank-theme.conf`), btop, cava, Spotifast (`"base": "{{mode}}"`), Vesktop and Wine (`.default` colors), the Nautilus and Thunar GTK apps.
- Not mode-aware: the Spicetify Hazy theme for the official Spotify client is a dark-only theme.
- Not changed: `mod.cleanedurlbar.customcolor` in the Zen prefs is a fixed dark value, and the GRUB theme is `dark`.

---

[← AutoUpdate.nix](core-autoupdate.md) · [Index](CONFIGURATION.md) · [Niri.nix →](desktop-niri.md)
