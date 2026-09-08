[Index](CONFIGURATION.md)

---

The default editor - extensions, theme, and every language toggle's settings folded in automatically.

## `modules/apps/development/editors/vscode/Vscode.nix`

Settings, one custom keybinding, and every extension are a direct
transcription of the real config on this machine, not a live importer -
split, as of the per-language system, between generic stuff declared
right here and language-specific stuff this file only pulls in:

- The generic extension lists here are exactly that: nothing tied to any
  one language. Some come pre-packaged in nixpkgs directly; others
  resolve through a community-maintained marketplace overlay that
  refreshes daily, so there's no hash to compute by hand for those - the
  trade-off being its idea of "latest" can lag the real marketplace by a
  version or two, since it's a heuristic scrape, not strict semver
  tracking. Worth it to never touch a hash again.
- **Every language-specific extension lives in its own language module
  instead** - C/C++'s tooling, Rust's analyzer, Kotlin's extensions plus
  Gradle support, Dart/Flutter's extensions, Nix's tooling, Qt's
  extensions, Python's stack. This file just filters the published
  language data down to whatever's actually enabled and folds it in.
  Extension names from nixpkgs come through as plain dotted strings
  rather than direct package references, since language modules don't
  have package access at the point they publish this data - the string
  gets resolved right here instead, and a typo throws loudly rather than
  silently installing nothing.
- The one remaining manually-pinned extension (a small C++ pack not on
  the automated index) moved into the Cpp language module along with
  everything else C/C++-related, and this file aggregates every enabled
  language's manual pins back into one shared list for the update
  checker to watch.

VS Code itself used to live inside the generic dev-tools file, before it
grew enough config to earn its own module.

- **The DMS theme extension gets installed as a real, writable copy**
  through an activation script, not the normal extensions list. DMS
  bundles this extension itself and rewrites its theme files live on
  every wallpaper change, but the normal extensions mechanism symlinks
  straight into the read-only Nix store - which would make DMS's writes
  fail outright. Hence the real copy instead.
- **The installed folder name has to be all-lowercase**, even though the
  extension's own metadata declares a capitalized publisher name - DMS's
  own code globs for the lowercase form specifically, matching how VS
  Code itself lowercases publisher names on disk. Found this the hard
  way in a real VM: the capitalized version just silently never matched,
  so the theme file sat there holding its static bundled default
  forever, never actually updating.
- **The WakaTime extension's key is set via `~/.wakatime.cfg`**, the same
  shared file (and same `crudini`-based mechanism) Android Studio's
  WakaTime plugin uses - see
  [AndroidStudio.nix](apps-dev-androidstudio.md)
  above. Nothing extension-specific to configure here; WakaTime's own
  plugins across editors all read that one file by convention. Same
  disable-when-missing rule too: `wakatime.vscode-wakatime` only gets
  appended to `nixpkgsExtensions` (`lib.optional hasWakatime ...`) when
  `vayumeSecrets.WAKATIME_API_KEY` is a real value, so a fresh setup
  with no key yet doesn't install an extension that would just sit
  there erroring.
- **One Dark syntax highlighting sits on top of the matugen theme,
  rather than replacing it.** The overall UI theme stays matugen-driven,
  tracking the current wallpaper; a separate, VS Code-documented
  mechanism overrides just the syntax colors on top of whatever theme is
  active, using the real color values pulled straight out of the
  packaged One Dark extension. A pre-existing italic-comment rule sticks
  around alongside it - VS Code merges multiple rules for the same
  scope instead of letting the later one win outright, so comments end
  up both colored *and* italic, matching the original intent plus the
  added color.

---

[← AndroidStudio.nix](apps-dev-androidstudio.md) · [Index](CONFIGURATION.md) · [Zed.nix →](apps-dev-zed.md)
