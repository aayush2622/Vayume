[Index](CONFIGURATION.md)

---

Every hand-pinned plugin hash in this repo, checked against upstream on a schedule - so a stale pin gets noticed instead of quietly going stale forever.

## `modules/core/PluginUpdateCheck.nix`

A read-only update reporter for VS Code, Android Studio, and Zen
Browser's pinned plugins/extensions - deliberately *not* Zed, which has
nothing to check: its extensions are just names Zed resolves and
installs itself at its own next startup, nothing pinned here to go
stale. This script never touches a pin itself, it just tells you what's
outdated so you can bump it by hand.

- **Where the pins actually come from**: each app file hoists its own
  pinned-plugin list into a shared `flake.pluginPins.<AppName>` spot -
  same pattern as matugen templates. The home-manager module just
  references that same binding, so nothing about what actually gets
  installed changed when this got refactored.
- **VS Code and Android Studio's pins get aggregated now**, not just
  hoisted - once language-specific extensions moved into their own
  files, each editor's pin list has to fold in every enabled language's
  manual pins on top of its own. Has to stay keyed by editor name, not
  split per-language, since the checker script only ever looks for those
  two specific names.
- **Keys match the app's real attribute name exactly** (`Vscode`, not
  `vscode`), so filtering down to "only what's actually enabled on this
  host" needs no translation table, just a straight name comparison.
- The filtered result lands at `/etc/vayume/plugin-pins.json`, system-wide
  rather than per-user, since `vayume.apps` itself is host-wide anyway.
- **Zen Browser's pins have nothing to version-check** - everything
  installs at whatever's currently latest, there's no pinned version to
  compare against. So for Zen this script checks *existence* instead: did
  the extension/mod get renamed or pulled entirely, not "is there a
  newer version."
- **The checker itself is a small, dependency-free Python script**, built
  straight into `$PATH` system-wide. No `requests`, just `urllib` and a
  thread pool so every check runs at once instead of one at a time.
  Right now that's 1 VS Code extension, 2 Android Studio plugins, 17 Zen
  extensions, and 8 Zen mods with anything actually pinned to check -
  everything sourced automatically from the marketplace/plugin-index
  inputs tracks upstream on its own with nothing here to go stale.
  - VS Code: one API call per extension to the Marketplace, comparing
    the pinned version against whatever's currently published.
  - Android Studio: JetBrains' modern REST API flatly rejects the string
    plugin IDs this repo actually stores (confirmed by trying it
    directly, not assumed) - so this uses the older XML-based endpoint
    instead, and picks "latest" by publish timestamp rather than
    comparing version strings, since some plugins mix versioning schemes
    across their history and a naive max would just pick the wrong one.
  - Comparisons are plain string inequality, not semver - these pins mix
    real semver, JetBrains build numbers, and prerelease suffixes, so
    "not equal to what's pinned" is the only honest thing to report.
  - Every network call fails quietly on its own - a timeout or DNS
    hiccup doesn't get reported as "outdated," it just gets skipped. If
    literally everything fails (fully offline), the cache doesn't get
    written at all, so the next run retries properly instead of going
    silent for a full day over a coincidental blip.
  - Results cache for 24 hours, so rebuilding twice in one day doesn't
    mean two rounds of network calls. Force a fresh check by setting
    `VAYUME_PLUGIN_CHECK_FORCE=1`.
  - Silent when there's nothing to report - it only ever speaks up when
    it's actually found something, so it's not noise on every build.
- **Wired in through a zsh hook**, not an alias, since aliases get
  skipped when a command's prefixed with `sudo`. The hook watches for
  rebuild-shaped commands and runs a quick, 10-second-capped check right
  before letting the real command through - so the only thing anyone
  ever has to do is run the normal rebuild command, and a slow or dead
  network adds at most 10 seconds, never more.

---

[← DevLanguages.nix](core-devlanguages.md) · [Index](CONFIGURATION.md) · [Dms.nix →](desktop-dms.md)
