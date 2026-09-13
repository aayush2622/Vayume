[Index](CONFIGURATION.md)

---

The browser, chrome-scripted deep enough to reload its own theme colors live - and the file this session spent the most rounds getting actually right.

## `modules/apps/utils/zenBrowser/ZenBrowser.nix`

**The profile always lives at `~/.zen/default`** - a fixed path this repo
owns outright, instead of trying to guess what a previous install named
it. Doesn't exist yet? The activation script creates it. Already there?
It gets reused and re-synced on every rebuild.

- `zenPrefs` are the settings you'd normally poke at through `about:config`.
- **`zenUserPrefs`/`zenUserJs`** hold look-and-feel state (compact mode,
  floating urlbar, hidden sidebar, every mod's tuned values) pulled out
  of a real profile's `prefs.js`. These go into `user.js` instead of
  being locked via `zenPrefs`, because they're things you'd realistically
  keep fiddling with through Zen's own Settings - locking them would
  freeze you out of your own UI. Downside: `user.js` reapplies on every
  *launch*, so a live tweak survives until the next restart, not the next
  rebuild. Deliberately left out: Sync state (tied to an account), proxy
  settings (dead anyway, and copying a real IP around is a bad idea), and
  a backup-location path that only made sense on the source machine.
- **Adding an extension** (`zenExtensions`) means finding two IDs on
  addons.mozilla.org: the `slug` (in the URL) and the `guid` (from the
  API, or the search endpoint if multiple listings share a name - go by
  daily users). You need both - `slug` is just the rename-able download
  name, `guid` is the actual manifest ID that policy enforcement keys on.
  This can't be automated the way mods can: extension policy gets baked
  into `policies.json` at build time, and flakes evaluate with no network
  access, on purpose.
- **Theming**: Zen has no Pywalfox-style plugin for this, so it's plain
  `userChrome.css`. DMS renders the wallpaper palette into a stylesheet,
  the activation script symlinks it into the profile, and the one prefs
  flag that makes custom stylesheets legal gets locked so there's no
  manual `about:config` step.
- **"No live reload" isn't a bug in that wiring - it's Firefox's (and
  Zen's own) genuinely unsolved limitation. Pushed back on this once,
  checked three independent, authoritative sources instead of one, same
  answer from all three:**
  1. Mozilla's own tracker:
     [bugzilla 1409065](https://bugzilla.mozilla.org/show_bug.cgi?id=1409065),
     "Reload userChrome.css without restarting," open since 2017, no fix.
  2. Zen's own maintainers, directly: a 2025 Zen GitHub discussion
     states plainly that "hot reloading for themes in Zen Browser isn't
     currently built in" and that a `--reload-userchrome`-style flag is
     a requested-but-unimplemented feature - so this isn't a vanilla-
     Firefox-only gap Zen's own fork happens to have fixed; it doesn't
     have it either.
  3. Zen's own official docs, the "Live Editing Zen Theme" guide
     (docs.zen-browser.app) - the *only* documented way to see a
     `userChrome.css` change without restarting is editing it live
     inside the Browser Toolbox's Style Editor (after three specific
     `about:config` flags), with the change applied by the Style Editor
     itself, in that moment. The guide never claims an externally
     rewritten file (which is what matugen produces here) gets picked
     up the same way - and the two points above confirm it doesn't.

  DMS *does* regenerate the stylesheet's colors live on every wallpaper
  change (same `RunUnconditionally: true` matugen path as everywhere
  else) - Firefox's (and Zen's) chrome loader just never rereads
  `userChrome.css` for a window that's already open, full stop, and
  there's no signal or file-watcher to hook the way a handful of GTK
  apps can be given one. The only known workaround is the manual Style
  Editor flow above - not something a `home.activation` script can
  trigger from outside the running browser. A new window (or restart)
  is what actually picks up the new colors.
- **What the bridge changes about all of the above.** Everything in that
  finding is still true *for a stylesheet that gets rewritten on disk* -
  which is exactly what DMS's own zenbrowser matugen template does. The
  vendored `matugen-bridge.uc.js` sidesteps the limitation instead of
  solving it: it never asks Zen to reread a file, it sets the
  `--matugen-*` custom properties as **inline style on
  `document.documentElement`** from privileged chrome JS. Inline custom
  properties are live - every `var(--matugen-*)` in the already-parsed
  `userChrome.css` re-resolves against the new value with no reload. So
  live chrome theming does work here, just not by the route the sources
  above (correctly) rule out.
- **Which makes *who owns `userChrome.css`* the thing that actually
  matters - and DMS was winning it.** Symptom: content/websites retinted
  live, but tab bar, toolbar, URL bar and sidebar stayed frozen. The
  bridge wasn't at fault - its own log
  (`~/.zen/default/chrome/matugen-bridge.log`) said `Wrote 8 prefs` /
  `Applied 8 vars to chrome :root` on every change, no errors, and the
  six distinct `var(--matugen-*)` names the chrome CSS consumes are all
  within those eight. The actual cause was two separate bugs stacking:
  1. **DMS owned the file.** Its `matugenTemplateZenBrowser` setting
     (defaults `true`) writes `~/.config/DankMaterialShell/zen.css` and
     makes `userChrome.css` a *symlink* to it. That file hardcodes hex
     with `!important` onto Zen's own native variables
     (`--zen-primary-color`, `--toolbar-color`, `--sidebar-text-color`)
     and references no `--matugen-*` var at all - so the sheet Zen
     actually loaded was structurally incapable of live-updating, and
     the vendored zen-wabi CSS was never being loaded at all.
     Now `false` in [Dms.nix](desktop-dms.md), which
     adds `zenbrowser` to matugen's `--skip-templates` (confirmed in
     DMS's own `Common/Theme.qml`, not assumed).
  2. **`cp -f` writes *through* a symlink.** The activation deployed the
     vendored file with `cp -f`, which follows the symlink and
     overwrites its *target* rather than replacing the link - so it was
     silently clobbering DMS's `zen.css` with zen-wabi's content, DMS
     regenerated that file on the next theme change, and the symlink
     survived untouched the whole time. Both CSS deployments now use
     `cp --remove-destination`, which unlinks first so a real file lands
     at the path.

  Because `userChrome.css` is still only *parsed* at startup, Zen needs
  one restart after the rebuild that lands this; from then on the
  bridge's inline vars carry every subsequent theme change live.
- **First-run bootstrap**: if the profile doesn't exist, the script runs
  Zen's own `-CreateProfile` command. That command still tries to talk to
  GTK even with no window to show, so it fails with "no DISPLAY" if run
  headless - it's wrapped in `xvfb-run` (a fake, disposable X server)
  purely to give it something to talk to.
- **That command, and every `curl` call in this file, is time-boxed.**
  Not paranoia - a real bug. `-CreateProfile` under Xvfb (no GPU, nothing
  for its telemetry pings to reach) doesn't always exit cleanly, and an
  activation script that never returns blocks the *entire* rebuild, not
  just Zen's little corner of it. Watched this actually happen while
  testing. An earlier, tighter timeout was too tight - `-CreateProfile`
  genuinely needs more than 45 seconds under these conditions, so it kept
  getting killed mid-setup instead of just being slow.
- **"Did it finish" is checked via a file, not a directory.** A killed
  `-CreateProfile` can leave a half-built profile folder behind - if the
  check were just "does the folder exist," that half-finished mess would
  look done forever and never get retried. `times.json` only gets written
  once profile creation genuinely completes, so a botched attempt leaves
  nothing behind to fool the next rebuild.
- **The script narrates itself** - profile creation starting/done/timed
  out, mods being fetched one by one - instead of running silently.
  That's on purpose: a slow-but-working setup and a genuinely stuck one
  look identical from the outside with zero output. This makes the
  difference visible in a normal terminal, not just buried in
  `journalctl`.
- **Emoji rendered broken and inconsistent - some codepoints fine,
  others wrong or monochrome, no visible pattern.** `zenUserPrefs` pins
  `font.name-list.emoji` explicitly, but that turned out not to be the
  actual cause - Firefox already defaults it to Noto Color Emoji first.
  The real bug was system-wide, in fontconfig's own fallback ranking,
  not Zen-specific at all - see [Fonts.nix](desktop-portals-fonts.md)
  for the actual root cause and fix (a `DejaVu Sans` vs `Noto Color
  Emoji` fontconfig priority bug that hit every app using the system
  UI font as a fallback, Zen just made it most visible). The
  `font.name-list.emoji` pref here is harmless and slightly more
  explicit than Firefox's own default, but wasn't what fixed it.
- **Zen's settings page (and any other isolated `about:` content
  document) showed a jarring green that didn't match the rest of the
  desktop at all.** Correctly diagnosed as a theme bug, not the
  Hyprland blur tint fixed alongside it - two unrelated things that
  happened to surface around the same time. `renderTheme`'s eight
  `{{placeholder}}` colors are a Nix-build-time seed, substituted once
  and baked into the derivation - `matugen-bridge.uc.js` only
  overwrites them live for the browser *chrome* (tabs, toolbar,
  sidebar), by setting `--matugen-*` custom properties on
  `document.documentElement`. `about:preferences` and similar pages
  are separate top-level content documents outside that chrome DOM
  entirely - privileged chrome JS has no route into them, so whatever
  the seed says is what they show, permanently, not just for a brief
  flash before the bridge catches up. The seed values were also just
  stale - a warm, olive-toned palette (`tertiary: #a3c9a8`, a sage
  green) left over from whenever this template was first wired up,
  completely unrelated to the actual blue/purple/pink palette the
  current wallpaper generates (checked directly against the live
  `~/.zen/default/chrome/matugen-vars.json`, not guessed). Updated the
  eight hardcoded values to match today's real palette - a fix for
  right now, but the underlying gap (seed only ever refreshed at
  `nixos-rebuild` time) was still there.
- **Made the seed itself track real theme changes**, closing that gap
  properly rather than leaving it as a "fixed for today" patch.
  `zenThemeSyncScript` re-renders the same two `./theme/*.template`
  files - the exact same `{{bg}}`-style substitution `renderTheme`
  does at Nix build time - but reads its color values from
  `matugen-vars.json` instead of hardcoding them, and runs as that
  file's own matugen `post_hook`, so it fires every time matugen
  actually regenerates it (every real theme change), not just at the
  next rebuild. `renderTheme`'s build-time version still exists and
  still matters - it's the only seed that exists *before* matugen has
  ever run (first boot, or a profile that predates this mechanism);
  the sync script only has something to read once
  `~/.zen/default/chrome/matugen-vars.json` exists at all, so it exits
  quietly rather than erroring when it doesn't yet. Verified the whole
  chain for real, not just by reading the script: swapped in
  synthetic, unmistakable colors (`#ff0000`/`#00ff00`/`#0000ff`) in
  place of a real matugen run, ran the built script directly, confirmed
  all three landed in the rendered `userChrome.css`, then restored the
  genuine palette the same way and re-verified. This still doesn't make
  an *already-open* Zen window repaint live - see the "no live reload"
  finding above for why that's a real Firefox/Zen limitation this
  script can't route around - but it does mean the file itself is
  always correct by the next restart, not stuck until the next
  `nixos-rebuild`.
- **Zen Mods** live in the same activation script (theming, `user.js`,
  and mods all need the same resolved profile path), traced through
  Zen's own source rather than guessed at:
  - The mods file is a JSON object keyed by mod ID, each entry carrying
    its metadata plus `enabled`.
  - `zenMods` here is just a `name -> id` map. Unlike extensions, this
    *can* be resolved live -
    [zen-browser/theme-store](https://github.com/zen-browser/theme-store)
    publishes a full index, so the script fetches it, filters to the IDs
    listed, and writes the result straight out. No hand-copied metadata
    to drift out of date.
  - Each mod's actual CSS/prefs get fetched separately, only if missing -
    self-heals if a file disappears, doesn't refetch on every rebuild.
  - **One broken mod takes the rest down with it.** Zen loops over
    enabled mods with no per-mod error handling, so one missing file
    throws and nothing themes that session. One mod ("Remove Browser
    Padding") is simply missing from upstream's own index right now, so
    it's absent here too - add it back whenever upstream does.
  - **Every `curl` call spells out the full store path**, never bare
    `curl` - an interactive shell has `curl` on `PATH`, the systemd
    service running activation scripts has a much narrower one, and a
    missing `curl` there fails silently instead of loudly. Found this by
    actually booting a fresh VM, not by guessing.

---

[← Gaming.nix](apps-gaming.md) · [Index](CONFIGURATION.md) · [Spicetify.nix →](apps-utils-spicetify.md)
