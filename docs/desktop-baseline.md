[Index](CONFIGURATION.md)

---

Every GTK and Qt app on this machine, themed - and the single most fought-over file in this whole repo, rewritten more times than anything else chasing one question: why won't the colors update on a window that's already open?

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
  shared file - see [Matugen.nix](desktop-matugen.md).
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
    `GSETTINGS_SCHEMA_DIR` in [Host.nix](core-host.md)
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
  [Users.nix](core-users.md)): the rsync routinely
  exceeded `TimeoutStartSec`, which killed the whole activation partway
  through and skipped everything after it, including the step that
  seeds DMS's wallpaper state. `iconTheme` is `Adwaita` now
  (`pkgs.adwaita-icon-theme`, already a system package) - no writable
  copy, no per-boot rsync, no accent-matched folder colors. If that
  trade is ever worth revisiting, the old mechanism is intact in git
  history on the commit before this removal.

---

[← Fonts.nix / Portals.nix](desktop-portals-fonts.md) · [Index](CONFIGURATION.md) · [Matugen.nix →](desktop-matugen.md)
