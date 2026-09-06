[Index](CONFIGURATION.md)

---

One toggle, three editors. How flipping on a language once tells VS Code, Android Studio, and Zed what to install for it, instead of configuring each by hand.

## `modules/core/DevLanguages.nix`

Declares `flake.devLanguages` - same "publish data at `self`" pattern as
matugen templates and plugin pins - so language modules and editors
never have to know about each other directly. A language module has no
idea which editors exist; an editor has no idea which languages exist.
They just agree on what shape this data comes in.

- **What this actually fixes**: before this existed, `Vscode.nix` just
  hardcoded a Dart extension reference and `AndroidStudio.nix` hardcoded
  a Dart plugin reference, with zero connection to whether Dart tooling
  was even installed. Remove "Dart" as a concept and nothing changes in
  either editor. That mismatch - editors quietly carrying extensions for
  languages you don't even have a compiler for - is exactly what this
  file exists to close.
- **Every language folder sets two things**: a normal app
  (`flake.homeModules.apps.<Lang>`, installs the actual LSP + toolchain,
  toggled through `vayori.apps` like anything else) and pure data
  (`flake.devLanguages.<Lang>`, no packages, just what each editor should
  grab). The data has a loose conventional shape but nothing enforces
  it - an editor reads whichever keys it understands and ignores the
  rest, so adding a new editor, or a new field for one language, never
  requires touching every other file.
- **Editors do their own filtering.** The published data is unfiltered -
  it's flake-level, evaluated once, with no host to filter against yet.
  Each editor works out which languages are actually enabled on its own,
  right where `vayori.apps` is actually available, then folds in
  whatever each enabled language contributed. Turn a language off and
  its extensions disappear from every editor on the next rebuild -
  nothing to go update by hand.
- **Zed merges its settings with a deep merge, VS Code with a shallow
  one** - and that's not arbitrary. Zed nests language-adjacent settings
  under a couple of shared top-level keys, so two languages touching the
  same key need to survive together, not clobber each other. VS Code's
  settings happen to never collide this way today (every language uses
  its own distinct key), so a shallow merge is safe there for now - just
  not guaranteed to stay that way forever if a future language collides.
- **Extension names for VS Code are plain strings**
  (`"rust-lang.rust-analyzer"`), not direct package references - language
  modules don't have `pkgs` in scope at the point they publish this data.
  The string gets resolved inside VS Code's own module instead, and a
  typo throws loudly rather than silently installing nothing. That's
  exactly how a real bug got caught here: `fwcd.kotlin` isn't actually in
  nixpkgs' curated extension set (only a similarly-named one is), and the
  throw caught it during a real build, not during review.
- **Manually-pinned extensions/plugins still funnel through the editor's
  own pin list**, not a separate per-language one - the update-checker
  script only knows to look for `Vscode`/`AndroidStudio` by name, so
  anything else would just get silently skipped. Each editor gathers
  every enabled language's manual pins into its own list instead.
- **Dart and Flutter are one toggle, not two.** `pkgs.flutter` already
  bundles its own Dart SDK, and every real Dart project on this machine
  is a Flutter one anyway - splitting them never bought anything.

---

[← Users.nix](core-users.md) · [Index](CONFIGURATION.md) · [PluginUpdateCheck.nix →](core-pluginupdatecheck.md)
