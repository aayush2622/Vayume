# Utility apps reference

[← Back to index](CONFIGURATION.md)

---

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

## `modules/apps/utils/spicetify/Spicetify.nix`

**Custom font**: Spotify's client reads its UI font from a CSS custom
property, not plain `font-family`, so the theme CSS sets it explicitly
to the shared theme font and pulls the font package in as a dependency
of the themed build. The theme's own options get merged with, not
replaced by, this override - safe since Spicetify's theme option takes a
freeform attrset.

---

## `modules/apps/utils/nautilus/Nautilus.nix`

- Thumbnails kick in for bigger files instead of falling back to a
  generic icon.
- Mouse back/forward buttons navigate history.
- Drag a file over a folder and it opens automatically instead of making
  you wait.
- Opens maximized - the cramped default window size helps nobody.
- Drives/USB/SD cards auto-mount and pop a window open, but nothing ever
  auto-runs. Nobody needs that surprise.
- The open-terminal extension defaults to gnome-terminal, which isn't
  installed here, so it's pointed at kitty instead.
- gvfs and tumbler run system-wide via `Host.nix` - they're daemons, not
  a per-user concern.

---

## `modules/apps/utils/bitwarden/Bitwarden.nix`

Just the desktop app - nixpkgs calls it `bitwarden-desktop`, not
`bitwarden` (that name throws a "this package got renamed" error if you
try it). Signing in and syncing still needs doing once by hand; Nix just
makes sure the app itself is there.

**`programs.rbw`** is a separate CLI vault, unrelated to the desktop
app's own login - it's what the Bitwarden launcher plugin in DMS actually
talks to behind the scenes. Its account email now comes from
`vayoriSecrets.RBW_EMAIL` (see
[core/Users.nix](core.md#modulescoreusersnix)) rather than a manual
`rbw config set email`, merged into `~/.config/rbw/config.json` every
rebuild via `jq`, leaving everything else already in that file
untouched - not through `programs.rbw.settings` directly, since that
writes an immutable store-linked file and a value that changes per
machine should never sit in one of those. `rbw login` (the actual vault
unlock) still needs doing by hand - the master password itself never
goes through Nix, or anywhere else in this repo. That one stays a
manual, interactive step on purpose.

**No real email, no config write.** The whole `rbwEmail` activation
script is wrapped in `lib.optionalString (vayoriSecrets.RBW_EMAIL !=
"REPLACE_ME")` - `programs.rbw` still gets enabled either way (the CLI
itself doesn't need an email to exist), but `rbw`'s config file is left
exactly as it is rather than getting seeded with a literal
`"REPLACE_ME"` as the account email.

---

## `modules/apps/utils/stateBackup/StateBackup.nix`

One canonical folder - `~/.config/vayori/session` - for every app's real
login/session state (Zen Browser's profile, Vesktop, VS Code/Zed account
sign-ins, the JetBrains/Android Studio data dir, rbw's own session, the
Bitwarden desktop app's local storage, Free Claude Code's `.env` - see
[core.md](core.md#modulescoreusersnix)), plus one command to move that
folder around safely. Fixed under `$HOME`, on purpose - completely
independent of wherever this flake repo happens to be checked out, so
it's the same folder whether the repo lives at `~/vayori`, got cloned
somewhere else entirely, or isn't even on disk right now (restoring a
backup doesn't need the repo present at all).

**`home.activation.linkSessionState`** runs on every rebuild. For each
path in the list above, it symlinks the app's real config location into
`~/.config/vayori/session/<same path>` instead of leaving it where the
app would normally put it - so that one folder becomes the single thing
that ever needs to move for a fresh install to come back already logged
into everything.

- **Self-healing, not "run once and hope."** A path that's already a
  symlink is left alone - a cheap, near-zero-cost no-op on every
  subsequent rebuild. A path that's still real, un-migrated data gets
  *moved* (not copied-and-abandoned) into `session/` before the symlink
  goes in, so nothing ends up duplicated in two places or silently
  ignored. Checked this against real scenarios, not just read through
  the logic: migrating a machine with real existing data, re-running on
  already-migrated state (clean no-op), and a brand new `$HOME` picking
  up a pre-populated `session/` folder and coming up already logged in.
- **Nothing about the app-specific paths in this list was verified
  against a live app the way most of this repo's other claims were** -
  there's no way to actually launch Zed/VS Code/Android Studio and watch
  where they store auth tokens in this environment. Standard, well-known
  locations, not guesses, but worth a quick check against the real
  thing.

**`vayori-app-state backup <file>` / `restore <file>`** turns that same
folder into a single password-encrypted archive and back - AES-256-CBC,
keyed via PBKDF2 (SHA-256, 10000 iterations) from a passphrase typed at
the prompt, never passed as a CLI argument (that'd leak through process
listings/shell history). For a same-trust move - a USB drive only you
touch, say - a plain `cp -r ~/.config/vayori/session` is just as valid
and a lot faster; this command exists for moving that folder somewhere
*less* trusted (cloud sync, email to yourself) without shipping it in
the clear.

- **The password is confirmed twice on backup, once on restore** - a
  typo locking you out of your own backup is a worse failure mode than
  a few extra keystrokes. A wrong password on restore fails loudly
  (openssl's own AEAD/padding check rejects it) rather than silently
  producing garbage - checked this for real, including confirming the
  session folder is left completely untouched on a failed restore, not
  partially overwritten.
- **Restore never clobbers outright.** It decrypts and unpacks into a
  temporary directory first, only swapping it into place after
  confirming the archive actually contained a real `session/` folder -
  and if `~/.config/vayori/session` already exists, it gets moved aside
  with a timestamp suffix instead of being deleted, so a restore never
  destroys data by mistake.

---

## `modules/apps/utils/terminal/Terminal.nix`

Kitty + zsh (oh-my-zsh) + fastfetch + Starship + eza, one toggle. Fastfetch
picks a random logo out of `modules/apps/utils/terminal/images/` every
time you open a shell, and falls back to its own default if that folder
ever ends up empty.

- **The logo picker used to `find` the images folder fresh on every
  single new shell**, piped through `shuf` - two subprocesses and a real
  filesystem walk paid on every terminal open for a folder that's
  entirely static within the flake. Now it's a plain bash array, baked
  in at build time (`fastfetchImagePaths`, computed once from
  `builtins.readDir`) - same "pick a random one" behavior, same set of
  images, just an array index instead of a filesystem scan. Checked the
  real generated `.zshrc` directly to confirm all the actual image paths
  ended up baked in correctly, not just that the Nix side evaluated.
- **Starship replaced a hand-rolled prompt.** The old one was a manual
  `precmd` hook that could only show the current branch - no dirty/staged/
  ahead-behind state, nothing. Starship fully owns prompt rendering once
  enabled, so the old code got deleted rather than left fighting it for
  the prompt.
- **eza replaces `ls` outright** via zsh integration (`ls`/`la`/`ll`/
  `lla`/`lt` all get aliased automatically) - the goal was a better `ls`,
  not a second tool to remember on top of it.
- **btop gets an actual theme now.** It used to just be an unconfigured
  package. Now it's told to look for a theme literally called `matugen`,
  which gets rewritten to match the wallpaper on every change - through a
  plain file, deliberately *not* home-manager's own theme option, since
  that option writes an immutable file and would just fight matugen for
  control of it. Same class of problem this repo already solved for GTK,
  Qt, and Android Studio.
- **cava** gets the same treatment, minus the "theme vs settings" split
  btop has - it only has the one config file, so matugen just owns it
  outright and cava fills in every other setting with its own built-in
  defaults.
- **Spicetify and Starship were skipped when wiring up matugen
  everywhere else**, on purpose - both are hand-extracted, curated
  configs from the real machine, not generic templates, and there's no
  clean way to splice in a dynamic palette without undoing the actual
  point of extracting them "as they really are." Covering every possible
  app with matugen was never the goal; not clobbering deliberately-tuned
  settings mattered more.

---

## `modules/apps/utils/vesktop/Vesktop.nix`

Two real config files, pinned straight off the reference machine, plus a
matugen theme - same "capture what's actually there" approach as the
editors. Declared as plain Nix data and serialized out, not copied in as
opaque `.json` files, so it reads like everything else in this repo.

- **Vencord's settings and plugin list** are just every plugin actually
  enabled on the real machine, with any non-default tuning (blur amount,
  ignore lists, that kind of thing). Unlike JetBrains plugins, nothing
  here needed fetching - every Vencord plugin ships built into the app,
  so "installing" one is just flipping a boolean.
- **Vesktop's own settings** (tray behavior, update branch, spellcheck
  languages, splash colors) live in a separate, smaller file at a
  different path, captured the same way.
- **Plugins that are just plain "off" got left out entirely** rather than
  spelled out one by one - of about 172 real plugins, 68 made the cut
  (everything on, plus anything with non-default settings even while
  off, plus the framework "*API" plugins kept explicit either way, since
  other plugins hook into them and it costs nothing to be safe). Checked
  Vencord's own source for this rather than assuming: leaving a plugin
  out resolves to exactly the same default it'd get if it were "off" and
  unmentioned, for every single one of them.
- **Runs through home-manager's native Vesktop module** now, not
  hand-written files - it grew one after this was first set up, and it
  writes to the exact same two paths this repo always used, so nothing
  needed restructuring. One real difference: the native module doesn't
  force-overwrite, so a leftover file from an earlier manual Vesktop
  launch can collide with it on the very first switch - a one-time
  delete of those two files clears that up.
- **QuickCSS imports DMS's own theme rather than shipping a custom
  one.** This repo used to carry its own hand-recolored DiscordRecolor
  theme via a dedicated matugen template; DMS ships its own
  matugen-themed Vesktop CSS too (the well-known
  [midnight-discord](https://github.com/refact0r/midnight-discord)
  theme, recolored), at `~/.config/vesktop/themes/dank-discord.css` -
  running both was pure duplicated work for the same result, so the
  custom template was dropped and DMS's own is used directly.
  Vesktop only auto-loads QuickCSS, not the `themes/` folder DMS writes
  to (same "needs a manual toggle" gap as GTK's own Apply button, just
  for Vesktop's Settings > Themes tab), so
  `home.activation.applyDmsVesktopTheme` writes
  `~/.config/vesktop/settings/quickCss.css` as a plain `@import
  url("../themes/dank-discord.css");` on every rebuild - a real file via
  `install`, not a `home.file` symlink, so the relative import resolves
  against Vesktop's own real config directory rather than wherever a
  Nix store symlink's target happens to sit (same reasoning as the GTK4
  `@import` fix in [desktop.md](desktop.md#modulesdesktopdmsnix)).
- **The shared font still reaches Discord's own chrome, not just
  colors** - Discord/Vencord's UI reads its font off a `--font` custom
  property, appended after the `@import` in the same generated
  `quickCss.css` so it layers on top of DMS's own theme rather than
  needing DMS to know about this repo's font choice at all.

---

## `modules/apps/utils/distrobox/Distrobox.nix`

The escape hatch for software that only ever ships a `.deb` - CodeTantra
and NeoColab being the reason this exists. Neither is in nixpkgs, neither
publishes anything but an Ubuntu package, and `nix-ld`/FHS wrappers don't
help when the vendor expects a real apt dependency graph. A distrobox
container is the honest answer; this module just stops it from being a
pile of remembered shell commands.

**Backend is rootless podman, not the Docker that's already enabled.**
[DevTooling.nix](system.md#modulessystemdevtoolingnix) gains
`virtualisation.podman` alongside the existing Docker, with
`dockerCompat = false` so nothing fights over the `docker` binary.
Distrobox prefers podman when both exist, and rootless podman is what
makes a GUI app in the box write files into `$HOME` as *you* rather than
as root. No user wiring was needed - nixpkgs already defaults
`autoSubUidGidRange = true` for normal users with no explicit ranges
(checked against `users-groups.nix`, not assumed), which is exactly what
rootless podman needs.

**The box does not share your home directory.** This is the one place
this module deliberately departs from distrobox's defaults. Distrobox
mounts all of `$HOME` into the container on purpose - tight host
integration is its whole design - but that means anything installed in
the box can read every file you own, which is the wrong default for
vendor software you don't control and can't audit. `isolateHome`
(on by default) gives the box its own home under
`~/.local/share/vayori-boxes/<name>` instead, and `unshare` defaults to
`[ "ipc" "process" ]` for namespace separation on top.

`netns` and `devsys` are deliberately *not* in that default. Unsharing
the network namespace cuts the box off the internet, and hiding host
devices takes the GPU with it - either one breaks a networked GUI app,
which is the entire use case. They're available in the option's enum if
a given box genuinely wants them.

Isolation has one consequence worth knowing: `distrobox-export` writes
its `.desktop` entry into the *box's* home, which is no longer the
host's, so an exported app would never reach the launcher. Both
`vayori-box-export` and `vayori-box-sync` therefore copy new entries and
icons back out to `~/.local/share/{applications,icons}` and refresh the
desktop database, so launcher integration still works exactly as it
would with a shared home.

**Flags only apply at creation time.** An existing box does not
retroactively gain an isolated home or new namespaces - `vayori-box-reset`
destroys and recreates it (prompting first, and keeping the box's home
directory) for when the options change.

**The box is created on demand, never at activation.** Every helper
starts by checking `distrobox list` and creating the container only if
it's missing. That's deliberate: pulling a container image is a slow
network operation, and activation runs before login (see
[Users.nix](core.md#modulescoreusersnix) on why that ordering is the
whole reason boot used to stall). Nothing here can delay a boot.

Six commands, all idempotent:

| Command | Does |
| --- | --- |
| `vayori-box` | Enter the box; with arguments, run them inside it |
| `vayori-box-install <x.deb\|apt-pkg>...` | Install local `.deb` files (apt resolves their dependencies) or plain apt packages |
| `vayori-box-apps` | List desktop entries the box now provides |
| `vayori-box-export <app>...` | Export an entry to the host launcher, so it shows up in DMS's spotlight like any native app |
| `vayori-box-sync` | Re-apply `vayori.ubuntuBox.aptPackages` + `exportApps` declaratively |
| `vayori-box-reset` | Destroy and recreate the box, picking up changed creation flags |

So the CodeTantra path is `vayori-box-install ~/Downloads/codetantra.deb`,
then `vayori-box-apps` to see what it registered, then
`vayori-box-export <name>`.

**`vayori.ubuntuBox` makes the result reproducible** once you know the
names: `aptPackages` and `exportApps` are re-applied by
`vayori-box-sync`, so a rebuilt machine gets the same box without
repeating the discovery. A downloaded `.deb` can't be declared this way -
it isn't in any apt repo and often sits behind a login - so that stays a
one-liner rather than a lie about being declarative. `name`/`image`
default to `ubuntu`/`ubuntu:24.04` and exist for when something needs a
different base.

**A container is not a VM, and it can't pretend to be a bare-metal
host.** Distrobox shares the host kernel, so `/proc`, cgroups,
`/run/.containerenv` and `systemd-detect-virt` all identify it from the
inside; there is no configuration here that hides that, and none is
planned. Software whose *licensing or proctoring* checks refuse a
container is refusing on purpose. If something fails to launch for an
ordinary reason instead - a missing shared library, a systemd or sandbox
error - that's a normal packaging problem worth debugging on its own
terms.

Anything with a nixpkgs equivalent belongs in `home.packages`. This is
for the genuinely Ubuntu-only tail.
