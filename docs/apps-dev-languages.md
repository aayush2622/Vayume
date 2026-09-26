[Index](CONFIGURATION.md)

---

Seven small files that are secretly two things at once: an app that installs a toolchain, and a data source every editor above reads to figure out what it needs.

## `modules/apps/development/languages/*/*.nix`

Seven independent toggles, each installing one language's own tooling
and telling the three editors above what to install for it. They
are independent, and five of the seven are on for this host (`Rust` and
`Flutter` are the two currently `false`). The isolation was checked as a
group, not just individually: flip all seven off at once, rebuild, and every
editor's extension list should drop to exactly its generic baseline with
zero language packages left anywhere on `$PATH`. That's exactly what
happened (VS Code 50→21, Android Studio 17→10, Zed 16→8), then flipping
them back on rebuilt clean again.

| App | Packages | VSCode extension(s) | Android Studio | Zed |
| --- | --- | --- | --- | --- |
| `Cpp` | `gcc`, `gnumake`, `clang-tools` (clangd + clang-format), `cmake`, `gdb` | `ms-vscode.cpptools`(-extension-pack), `cmake-tools`, `twxs.cmake`, `vadimcn.vscode-lldb`, `boundarystudio.cpp-extentions-pack` (manual) + 3 marketplace | - | `neocmake` |
| `Rust` | `rustc`, `cargo`, `rust-analyzer`, `rustfmt`, `clippy` | `rust-lang.rust-analyzer` | - | - (bundled) |
| `Kotlin` | `kotlin`, `kotlin-language-server` | `mathiasfrohlich.kotlin`, `vscjava.vscode-gradle` + `fwcd.kotlin`/`esafirm.kotlin-formatter`/`naco-siren.gradle-language` (marketplace) | `kmm-plugin` (Kotlin Multiplatform - regular Kotlin support is already built in) | `kotlin`, `java`, `groovy` + JVM target/language-server settings |
| `Flutter` | `flutter` (bundles its own Dart SDK - covers Dart too, see below) | `dart-code.dart-code` + `dart-code.flutter` | `Dart`, Flutter Enhancement Suite, `flutter-intellij`, `flutter-intl` | `dart`, `flutter-snippets` |
| `Nix` | `nixd`, `nil`, `nixfmt` | `jnoortheen.nix-ide`, `arrterian.nix-env-selector` + `ziyyun.nix-forge`/`pinage404.nix-extension-pack` (marketplace) | NixIDEA | `nix` |
| `Qt` | `kdePackages.qtdeclarative` (qmlls) | `theqtcompany.qt-core`/`qt-qml` (marketplace) | - | `qml` |
| `Python` | `python3` | `ms-python.python`/`vscode-pylance`/`debugpy`/`vscode-python-envs` + `kevinrose.vsc-python-indent`/`njqdev.vscode-python-typehint` (marketplace) | `python-ce` | - (bundled) |

- **VS Code uses `nixd` for Nix, pointed at this flake, with `nil` kept for
  the other editors.** `nixd` can complete real option names because it
  evaluates them: the settings give it this repo's pinned nixpkgs, the
  NixOS options of the host named in `/etc/hostname` (the first host in the
  flake if none matches, so nothing is hard-coded), and the home-manager
  options (`options.home-manager.users.type.getSubOptions [ ]`). That
  gives completion of option names, hover with each option's type and
  description, and Ctrl+click (go to definition) on an option to where it
  is declared, besides the usual jumps to `let` bindings and imported
  files.
- **The flake is evaluated in place, not copied.** `builtins.getFlake`
  copies the repo into the store first, so Ctrl+click on a `vayume.*`
  option used to open a read-only `/nix/store/...-source` copy instead of
  the file you can edit. The expressions now load the flake through
  `flake-compat` (already in `flake.lock`, found by its repo name) with
  `src = { outPath = <repo>; }`, which it imports from that path directly,
  so declarations point at the real files; nixpkgs options still open the
  nixpkgs source. The gitignored `_config.nix` and `_hardware.nix` are
  read in place too, which is also why a plain `getFlake` of the path would
  not do. The repo is found the same way `vayume rebuild` finds it
  (`vayumeLib.repoDiscovery`: `~/vayume`, `~/dotfiles`, `~/.dotfiles`,
  `/etc/nixos`), falling back to the directory nixd runs in, so it works
  whatever folder or single file VS Code has open. Checked by driving nixd
  over LSP from `/tmp` with the generated settings: option completion,
  hover, and go to definition into `_barStyle.nix` and `Users.nix` in the
  checkout.
- **Not everything can be followed.** Names reached through flake
  outputs, such as `self.nixosModules.Dms` or `self.homeModules.apps.Zed`,
  are built by `import-tree` from the file layout at evaluation time, so
  no Nix language server can jump from them to a file; open the module by
  its path instead (`Ctrl+P`, `Dms`). Format-on-save
  runs `nixfmt` through the `nix-forge` extension. Zed's Nix extension
  still uses `nil`, which is why both servers are installed.
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
- **A compiler is part of the toggle, not assumed to be there.**
  `clang-tools` ships clangd and clang-format but no compiler at all, so
  for a while the editors had a working language server and no way to
  actually build anything - VS Code's C/C++ extension in particular just
  reports "cannot find compiler" rather than failing loudly. `gcc` and
  `gnumake` are in the package list for that reason, and the extension
  is pointed straight at the store path
  (`C_Cpp.default.compilerPath = "${pkgs.gcc}/bin/g++"`) instead of
  being left to search `$PATH`, which on NixOS is exactly where that
  search goes wrong. Standards are pinned alongside it - C++23 and C17 -
  so IntelliSense agrees with what the compiler would actually accept.

- **C and C++ are one toggle, not two** - nothing in this setup treats
  plain C differently from C++, so splitting them would just be two
  toggles that always get flipped on together anyway.
- **Python's only real package is the interpreter itself** - the
  language servers on all three editors do their own thing without
  needing a separate binary, so the interpreter is the one thing
  actually missing without this toggle.
- Nix's own packages overlap with what's already installed system-wide
  for root-level editing - left as-is on purpose, since the Nix store
  dedups the actual files regardless and the two lists serve genuinely
  different scopes.

---

[← Zed.nix](apps-dev-zed.md) · [Index](CONFIGURATION.md) · [DevTools.nix →](apps-dev-devtools.md)
