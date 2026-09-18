[Index](CONFIGURATION.md)

---

The heaviest editor in this repo, and the one with the most moving parts to patch into place.

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
  [Matugen.nix](desktop-matugen.md)). The generated
  scheme file deliberately isn't declared as a normal managed file -
  matugen writes it directly on every wallpaper change, and letting
  home-manager also claim ownership would just mean the two fight over
  the same file.
- **The whole IDE chrome (title bar, panels, toolbars), not just the
  editor pane, follows the live matugen palette too**, via a locally-
  authored "fake plugin" (`dankmatugen-theme`) dropped straight into the
  user plugins folder - IntelliJ discovers plugins by scanning that
  folder for a subdirectory with its own `META-INF/plugin.xml`, the same
  way the real fetched plugins above are installed, so this one just
  declares a `themeProvider` pointing at a matugen-templated
  `.theme.json` instead of shipping compiled code. It shows up as its
  own entry ("DankMatugen") in Settings > Appearance > Theme. The
  generated `.theme.json` has to live under `classes/`, not the plugin
  root - `plugin.xml` at the root is a special-cased entry point the
  descriptor loader checks directly, but `UIThemeProvider` resolves its
  `path` via the plugin's normal runtime classloader, which for an
  exploded (non-jar) plugin is `classes/` + `lib/*.jar`, not the bare
  plugin directory (confirmed via `idea.log`: the plugin loaded fine,
  but logged "Cannot find theme resource" until moved here).
- **JCEF (the embedded Chromium used for the Gemini/Assistant panel,
  App Quality Insights, and any in-IDE browser preview) is swapped in.**
  Google's own Android Studio download ships a JBR with no JCEF at all -
  not the native Chromium bits, not even the `jcef-plugin` directory
  every JetBrains-branded IDE bundles, just the bare
  `intellij.libraries.jcef.jar` on the Java side, so every JCEF-backed
  feature is silently unavailable out of the box. `jetbrains.jdk` is the
  same JBR line built from source with JCEF enabled (its default), and
  is exactly what nixpkgs' own JetBrains IDE packages (idea, pycharm,
  clion, ...) use for this, so it gets swapped in for the bundled `jbr`
  the same way. Its `libcef.so` is a proper Nix build linked against
  nixpkgs' own cairo/pango/nss/etc, not the FHS-style blob other IDEs
  ship, so no `LD_LIBRARY_PATH` additions are needed on top. One
  subtlety: `jetbrains.jdk`'s own output is *not* a JBR root - it's one
  level above it, with `bin`/`include` symlinked down into `lib/openjdk`
  so plain `java` still resolves `java.home` correctly through them.
  Android Studio's native launcher doesn't do that same resolution - it
  opens `$IDE_ROOT/jbr/lib/server/libjvm.so` directly - so linking `jbr`
  straight to `jetbrains.jdk` leaves it looking one level too shallow
  and the IDE fails to start ("Failed to load 'libjvm.so'"); it has to
  point at `lib/openjdk` itself, which *is* a flat JBR root. The
  launcher's `startScript` also has the unpatched store path hardcoded
  into it at eval time, so overriding `unwrapped` alone doesn't reach
  it - the reference gets rewritten too.
- **`nodejs` is in `home.packages` for the Claude Code plugin
  (`claude-code-jetbrains-plugin`) specifically** - it runs its own Node
  backend (`backend.mjs`) in-process and just shells out to whatever
  `node` it finds on `PATH`, and nothing else in this config puts a JS
  runtime there.
- **The WakaTime plugin's key comes from `~/.wakatime.cfg`**, not a
  plugin-specific settings file - that's the one file WakaTime's own
  plugins for virtually every editor read from, JetBrains included, so
  it's the correct place regardless of what this repo does elsewhere.
  An activation script sets just the `api_key` line via `crudini`
  (from `vayumeSecrets.WAKATIME_API_KEY`, see
  [vayume/VayumeUsers.nix](core-users.md)), leaving any other
  settings already in that file - proxy config, excluded projects -
  untouched. VS Code's own WakaTime extension reads the exact same
  file, so both editors end up correctly configured from one shared
  mechanism.
- **No real key, no plugin - `allManualPluginsSpec` filters the
  `com.wakatime.intellij.plugin` entry out entirely** (by `id`, so it
  doesn't disturb `androidStudioManualPluginsSpec`'s own use as the
  `flake.pluginPins` source, which stays complete regardless of any one
  user's secrets) when `vayumeSecrets.WAKATIME_API_KEY` is still
  `"REPLACE_ME"`, and the `crudini` activation above becomes a no-op via
  `lib.optionalString` - so there's no plugin sitting there pointed at a
  placeholder key that would just fail every heartbeat.

---

[← Waydroid.nix](system-waydroid.md) · [Index](CONFIGURATION.md) · [Vscode.nix →](apps-dev-vscode.md)
