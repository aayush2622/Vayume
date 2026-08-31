# Development apps reference

[← Back to index](CONFIGURATION.md)

---

## `modules/apps/development/editors/androidStudio/AndroidStudio.nix`

`adb` just works out of the box on a modern systemd - the `adbusers`
group in `extraGroups` is optional belt-and-suspenders, not actually
required anymore.

Plugins and settings are captured exactly as they exist on the real
machine, pinned as real Nix packages instead of fetched live every time:

- **17 real plugins** (with every language toggle on, the default here -
  fewer if you turn one off), coming from three places:
  - 8 generic ones (Catppuccin, the Claude Code plugin, git-worktree-
    manager, Discord integration, lsp4ij, One Dark theme, Perforce/SVN
    support) resolved against the *exact* installed IDE build, read
    live rather than hardcoded - so this only ever asks for plugins
    that actually match the version installed, closing a real gap
    where "latest on the marketplace" isn't necessarily compatible with
    what's actually running.
  - 7 more, language-specific, coming from each enabled language's own
    module: Flutter contributes 4 (Dart itself plus three Flutter
    plugins - Dart and Flutter share one toggle, see the languages
    section), Kotlin contributes the Kotlin Multiplatform plugin
    (regular Kotlin support is already built into the IDE), Nix
    contributes NixIDEA, Python contributes the Python plugin. Turn a
    language off and its plugins just disappear from this list on the
    next rebuild - nothing to edit by hand.
  - 2 manual holdouts (WakaTime, GitHub Copilot) still fetched the old
    way, with a pinned hash. WakaTime just isn't in the automated index.
    GitHub Copilot *is* there, but building it that way genuinely fails
    - it bundles a native Node addon that the build step can't patch up
    correctly, missing half a dozen shared libraries. Hit that as a real
    build failure while migrating everything else, not a hypothetical -
    so it stays on the plain fetch-and-unzip path that's always worked.
  - Only those 2 manual ones show up in the update-checker's watch list;
    the other 15 update automatically whenever the plugin-index input
    does.
- **The normal "add plugins" nixpkgs helper doesn't work here.** It
  assumes a plain IDE layout, and Android Studio's package is an
  FHS-wrapped launcher where the real IDE lives in a separate closure -
  the path that helper expects just doesn't exist. Confirmed with an
  actual failed build, not assumed. Instead, each plugin gets placed
  directly into the *user* plugins folder - the same one the IDE itself
  writes to when you install something through its own Settings menu -
  which sidesteps the wrapping problem completely and needed zero
  changes to the stock package. Checked every plugin folder name against
  the real machine's own install and they match exactly.
- The IDE's actual config-directory name gets read out of the built
  package's own metadata, not guessed from a version string - the real
  machine's installed build and the one pinned here don't share a
  version number, and that metadata file is the only reliable source of
  truth for which folder an IDE build actually reads from.
- Five XML option files (font, look-and-feel, color scheme, One Dark
  config, Vim emulation) are straight transcriptions of the real
  machine's own files.
- **The editor gets a real matugen-driven color scheme**, replacing the
  static default - since neither DMS nor Android Studio has any built-in
  hookup for this, it's a from-scratch template (see
  [Matugen.nix](desktop.md#modulesdesktopmatugennix)). The generated
  scheme file deliberately isn't declared as a normal managed file -
  matugen writes it directly on every wallpaper change, and letting
  home-manager also claim ownership would just mean the two fight over
  the same file.
- **The Free Claude Code wrapper** takes the real Android Studio binary
  and wraps it (`symlinkJoin` + `makeWrapper`) to set FCC's environment
  variables on that process specifically, not system-wide. Checked the
  built wrapper directly: it sets the vars, then execs the real binary
  under its original name, and the app's own `.desktop` entry references
  it by that same bare name - so both the app launcher and a plain
  terminal launch resolve to the wrapped version automatically, no
  desktop-file patching needed.
- **The WakaTime plugin's key comes from `~/.wakatime.cfg`**, not a
  plugin-specific settings file - that's the one file WakaTime's own
  plugins for virtually every editor read from, JetBrains included, so
  it's the correct place regardless of what this repo does elsewhere.
  An activation script sets just the `api_key` line via `crudini`
  (reads `WAKATIME_API_KEY` from
  `~/.config/vayori/session/secrets.json`), leaving any other settings
  already in that file - proxy config, excluded projects - untouched.
  VS Code's own WakaTime extension reads the exact same file, so both
  editors end up correctly configured from one shared mechanism.

---

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
  [AndroidStudio.nix](#modulesappsdevelopmenteditorsandroidstudioandroidstudionix)
  above. Nothing extension-specific to configure here; WakaTime's own
  plugins across editors all read that one file by convention.
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

## `modules/apps/development/editors/zed/Zed.nix`

Home-manager's own native Zed module - extensions and settings, a direct
transcription of the real config on this machine, split the same
generic-vs-language way as VS Code. This file only ever had to
*aggregate* language contributions; it never carried any language-
specific settings of its own to begin with.

- **Extensions here are just names, nothing more** - unlike VS Code's
  pinned marketplace packages or Android Studio's fetched plugins, Zed
  just resolves and installs each named extension itself at its own next
  startup. Nothing to pin or hash, and nothing for the update checker to
  watch either - there's no version pinned anywhere to go stale.
- **Settings stay mutable on purpose.** Zed's activation script merges
  this file's declared settings on top of whatever's already sitting in
  the real settings file, rather than replacing it outright - so
  declared settings still win every rebuild, but the file stays normal
  and editable in between, the way Zed itself expects to be able to
  write to it from its own UI.
- **The WakaTime API key isn't declared in this file's own settings** -
  it's a real credential, and even outside a public repo, a plain Nix
  value here would end up baked into the world-readable `/nix/store`
  forever. It's spliced in separately, after Zed's own settings merge
  has run, by a small `jq` patch reading `WAKATIME_API_KEY` straight out
  of `~/.config/vayori/session/secrets.json` - see
  [core/Users.nix](core.md#modulescoreusersnix) for that file's
  mechanism, which Free Claude Code's API key and VS Code/Android
  Studio's own WakaTime setup all go through too.
- Fonts here track the one shared theme font setting, not a hardcoded
  copy of whatever the real config happened to say - same reasoning as
  every other themed app in this repo.
- **Kotlin's Zed setup pulls in Java and Groovy too** - real Kotlin/
  Android projects mix in Java interop files and Groovy build scripts
  often enough that gating them separately would just mean two more
  toggles that always get flipped on together with Kotlin anyway.
- **C/C++ only needs one extra extension here** - Zed bundles clangd
  support natively, unlike VS Code, so the only real gap is CMake
  project-file support.
- **Rust and Python need no Zed extension at all** - same story, Zed
  bundles both natively (rust-analyzer, and a Pyright-based Python
  server).
- **Arduino was in the real installed-extensions list but got dropped
  here on request**, along with the settings block it needed, since
  nothing here actually uses it.
- **Zed uses DMS's own matugen-driven theme now, not a custom one** -
  `theme = "DankShell Dark"` names a theme straight out of DMS's own
  `dank-zed-theme.json`, which DMS keeps regenerating at
  `~/.config/zed/themes/dank-zed-theme.json` on every theme change -
  `matugenTemplateZed` isn't even declared in
  [Dms.nix](desktop.md#modulesdesktopdmsnix) any more, since `true` is
  DMS's own default too.
  This repo used to hand-author its own ~140-key theme against Zed's
  published schema instead; DMS's own file covers the same ground (it
  ships four ready variants - `DankShell Dark`/`Light`, plus
  `Transparent` pairs) so the custom one was dropped rather than run
  both for the same result. Zed just scans `~/.config/zed/themes/*.json`
  for a `name` match, so nothing beyond that string has to agree with
  what DMS writes.

---

## `modules/apps/development/languages/*/*.nix`

Seven independent toggles, each installing one language's own tooling
and telling the three editors above what to install for it. All seven
are on by default here - and this was actually checked as a group, not
just individually: flip all seven off at once, rebuild, and every
editor's extension list should drop to exactly its generic baseline with
zero language packages left anywhere on `$PATH`. That's exactly what
happened (VS Code 50→21, Android Studio 17→10, Zed 16→8), then flipping
them back on rebuilt clean again.

| App | Packages | VSCode extension(s) | Android Studio | Zed |
| --- | --- | --- | --- | --- |
| `Cpp` | `clang-tools` (clangd + clang-format), `cmake`, `gdb` | `ms-vscode.cpptools`(-extension-pack), `cmake-tools`, `twxs.cmake`, `vadimcn.vscode-lldb`, `boundarystudio.cpp-extentions-pack` (manual) + 3 marketplace | - | `neocmake` |
| `Rust` | `rustc`, `cargo`, `rust-analyzer`, `rustfmt`, `clippy` | `rust-lang.rust-analyzer` | - | - (bundled) |
| `Kotlin` | `kotlin`, `kotlin-language-server` | `mathiasfrohlich.kotlin`, `vscjava.vscode-gradle` + `fwcd.kotlin`/`esafirm.kotlin-formatter`/`naco-siren.gradle-language` (marketplace) | `kmm-plugin` (Kotlin Multiplatform - regular Kotlin support is already built in) | `kotlin`, `java`, `groovy` + JVM target/language-server settings |
| `Flutter` | `flutter` (bundles its own Dart SDK - covers Dart too, see below) | `dart-code.dart-code` + `dart-code.flutter` | `Dart`, Flutter Enhancement Suite, `flutter-intellij`, `flutter-intl` | `dart`, `flutter-snippets` |
| `Nix` | `nil`, `nixfmt` | `jnoortheen.nix-ide`, `arrterian.nix-env-selector` + `ziyyun.nix-forge`/`pinage404.nix-extension-pack` (marketplace) | NixIDEA | `nix` |
| `Qt` | `kdePackages.qtdeclarative` (qmlls) | `theqtcompany.qt-core`/`qt-qml` (marketplace) | - | `qml` |
| `Python` | `python3` | `ms-python.python`/`vscode-pylance`/`debugpy`/`vscode-python-envs` + `kevinrose.vsc-python-indent`/`njqdev.vscode-python-typehint` (marketplace) | `python-ce` | - (bundled) |

- **`fwcd.kotlin` turned out to only exist on the marketplace, not in
  nixpkgs' own curated set** - only a similarly-named extension from a
  different publisher is actually pre-packaged there. Caught this
  because the resolver throws loudly on a bad reference instead of
  silently doing nothing - it failed a real build, which is exactly the
  point of making it throw.
- **Flutter covers Dart too - one toggle, not two.** The Flutter package
  already bundles its own Dart SDK, and every real Dart project on this
  machine is a Flutter one anyway. There's also a sharper, more concrete
  reason: while these were still separate modules, having both installed
  broke `home-manager`'s build outright, since both packages ship a
  file at the same internal path and can't coexist in one profile. Not
  a style call - a real conflict that merging them sidesteps completely.
- **C and C++ are one toggle, not two** - nothing in this setup treats
  plain C differently from C++, so splitting them would just be two
  toggles that always get flipped on together anyway.
- **Python's only real package is the interpreter itself** - the
  language servers on all three editors do their own thing without
  needing a separate binary, so the interpreter is the one thing
  actually missing without this toggle.
- **A Python interpreter shows up on `$PATH` even with this toggle
  off** - not a bug, checked this directly while testing the toggle:
  Free Claude Code installs its own Python unconditionally for its setup
  step, completely unrelated to this language toggle. Both things can be
  true: no Python-specific editor extensions without the toggle, but
  still a Python binary around if Free Claude Code is also enabled.
- Nix's own packages overlap with what's already installed system-wide
  for root-level editing - left as-is on purpose, since the Nix store
  dedups the actual files regardless and the two lists serve genuinely
  different scopes.

---

## `modules/apps/development/devTools/DevTools.nix`

`git` isn't listed here - it's already installed system-wide, since
flakes need it available regardless of which apps anyone's picked.

---

## `modules/apps/development/freeClaudeCode/FreeClaudeCode.nix`

Wires [Free Claude Code](https://github.com/Alishahryar1/free-claude-code)
(FCC) - a local proxy that lets Claude Code talk to non-Anthropic model
providers instead of the paid API - into the CLI, the VS Code extension,
and Android Studio's plugin.

- **Deliberately not a from-scratch Nix package.** FCC needs a recent
  Python and around 20 dependencies, several of which aren't packaged in
  nixpkgs at all, and it moves fast enough that hash-pinning the whole
  thing would be constant upkeep for no real benefit. Instead, `uv` gets
  installed declaratively and the actual clone-and-sync work happens in
  its own one-shot systemd service - `uv` manages the Python interpreter
  itself, nothing extra needed for that. Same trade-off already made
  elsewhere in this repo for Zen Browser's mod-fetching: a real network
  dependency for something too fast-moving to fully pin, not the norm
  everywhere else.
- **That setup work deliberately does *not* run inline during
  activation** - it used to, and that was a real, observed bug: syncing
  Python plus twenty packages ran synchronously inside the main
  activation service, blocking the entire rebuild on it, and on a slow
  connection could run past home-manager's own activation timeout and
  kill the *whole* rebuild, not just this one app's setup. Watched this
  actually happen in testing. Fixed by moving the heavy lifting to its
  own service and having activation just kick it off in the background -
  activation returns immediately no matter how long the sync takes, and
  the actual server waits for a real, finished sync before it starts,
  whether that start comes from the background kick or a later login.
- **The server itself runs as a normal user service**, restarting
  automatically on failure with a generous retry budget - mostly a
  leftover safety net from before the setup got split out, kept because
  it's cheap insurance against a slow first start.
- **The home-manager activation timeout got tuned down to 30 seconds**
  from the 5-minute default - and that number is worth double-checking
  if a rebuild ever ends up failing with a timeout in the logs. A live
  VM test at that value did show activation getting killed a little over
  20 seconds in, before some steps had even run - so on a slow first
  activation, this really can cut things short. It's a real trade-off,
  not obviously the right number forever.
- **The API-config file's base scaffold is seeded once and never
  overwritten - the provider keys are a different story.** Checked FCC's
  own source to confirm this exact path (not the cloned repo's own
  `.env`) is what the running server actually reads live config from,
  and what its own admin UI writes settings back into. Force-declaring
  the *whole file* the way some other config files in this repo are
  managed would fight that admin UI for ownership - so the scaffold
  (`MODEL`, `PROXY_AUTH_ENABLED`, the auth token, `FCC_OPEN_BROWSER`) is
  only written if the file doesn't exist yet, same "seed once" pattern
  as the Papirus icon copy elsewhere. Provider API keys are handled
  separately, and *do* re-sync every rebuild: every entry under
  `PROVIDERS` in `~/.config/vayori/session/secrets.json` (see
  [core/Users.nix](core.md#modulescoreusersnix) for the full schema)
  gets merged in as its own `.env` line, keyed by whatever name is
  already in `PROVIDERS` - FCC itself supports 17+ providers, each
  needing its own correctly-named key (`NVIDIA_NIM_API_KEY`,
  `OPENROUTER_API_KEY`, `DEEPSEEK_API_KEY`, and so on, straight from
  FCC's own naming, not something this repo invents), so this is a real
  loop over however many keys are actually there, not three hardcoded
  ones. Verified for real: four providers merged correctly, then a fifth
  added and one existing key changed, re-ran clean with no stale
  duplicates and no lines lost. Generating a key itself still isn't
  something this repo can do for you - grab one from whichever provider
  and drop it into `PROVIDERS`, or set it through FCC's own admin UI
  instead.
- **Claude Code's own state file gets one specific flag merged in** -
  documented upstream as the fix for Claude Code still prompting a real
  Anthropic login even with FCC's URL/token already set. Merged in with
  `jq`, not overwritten outright, since this file is Claude Code's real
  session state and a full overwrite would either destroy that or fight
  the CLI for ownership of a file it's constantly writing to itself.
- **JetBrains' own agent registry gets the same careful, merge-only
  treatment** - it's a shared, IDE-wide file that could list other
  unrelated agents, so the merge only ever touches the one entry this
  setup cares about, additively, so it can't clobber anything else
  already registered there.
- **Android Studio gets covered a more direct way, separately** - the
  JetBrains-wide registry patch above targets JetBrains' generic
  mechanism for this, but whether Anthropic's own dedicated plugin
  actually reads that same registry is genuinely unverified upstream.
  So Android Studio also gets the wrapped-binary treatment described in
  its own section - more reliable anyway, since whatever the plugin
  spawns as a subprocess just inherits the wrapped process's environment
  through normal OS process inheritance, regardless of which internal
  mechanism the plugin actually uses to read its config.
- **None of this is wired system-wide, on purpose.** The FCC connection
  details only get set inside VS Code's own settings, the JetBrains
  registry, and Android Studio's wrapped binary specifically - never as
  a plain session-wide environment variable, which would silently
  redirect *every* terminal's real `claude` command through FCC too and
  break normal, properly-authenticated Claude Code usage everywhere
  else. FCC ships its own separate launcher for terminal use instead,
  which only sets these variables for itself.
- **Only Claude Code gets wired up here** - FCC's own installer offers
  hookups for several other agent CLIs too, each with its own
  third-party installer script. None of that runs; only what Claude Code
  actually needs gets installed.
- **The connection details live in exactly one shared place**, not
  copied into three separate files - it used to be copied, and that was
  a real bug: turning FCC off in `vayori.apps` left VS Code and Android
  Studio still pointed at a proxy that was never actually started, with
  no error, just a Claude Code integration silently trying to talk to a
  dead port instead of falling back to the real API. Fixed by
  publishing the connection info from one shared place and having both
  editors check whether FCC is actually enabled before using it -
  verified in both directions: built with FCC on (nothing changed), then
  built again with it stripped from `vayori.apps` and confirmed both
  editors cleanly fell back to their plain, unwrapped configuration.
- **Android Studio's `CHROME_EXECUTABLE = "zen"` got the identical
  fix, for the identical reason** - it only gets set when Zen Browser is
  actually enabled, since otherwise it'd point at a binary that doesn't
  exist. A repo-wide check for this exact pattern - one app module
  hardcoding another app's binary, URL, or port - turned up only these
  two real cases.
