[Index](CONFIGURATION.md)

---

The fast one - same language-aware wiring as VS Code, a different settings shape underneath.

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
  it's spliced in separately, after Zed's own settings merge has run, by
  a small `jq` patch that sets it from the `vayoriSecrets.WAKATIME_API_KEY`
  argument (see [core/Users.nix](core-users.md) - the same
  mechanism Free Claude Code's provider keys and VS Code/Android
  Studio's own WakaTime setup all go through), so it lands after
  `zedSettingsActivation`'s own merge onto the real settings file rather
  than getting folded into the `settings` attrset above and merged in
  the same pass.
- **No real key, no extension.** `"wakatime"` only gets appended to
  `extensions` (`lib.optional hasWakatime "wakatime"`) and the `jq`
  patch above only runs (`lib.optionalString hasWakatime`) when
  `vayoriSecrets.WAKATIME_API_KEY` is a real value - a fresh setup with
  no key yet gets neither, instead of an extension configured with a
  key that would just fail.
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
  [Dms.nix](desktop-dms.md) any more, since `true` is
  DMS's own default too.
  This repo used to hand-author its own ~140-key theme against Zed's
  published schema instead; DMS's own file covers the same ground (it
  ships four ready variants - `DankShell Dark`/`Light`, plus
  `Transparent` pairs) so the custom one was dropped rather than run
  both for the same result. Zed just scans `~/.config/zed/themes/*.json`
  for a `name` match, so nothing beyond that string has to agree with
  what DMS writes.

---

[← Vscode.nix](apps-dev-vscode.md) · [Index](CONFIGURATION.md) · [languages/*/*.nix →](apps-dev-languages.md)
