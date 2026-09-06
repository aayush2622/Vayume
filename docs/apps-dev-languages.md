[Index](CONFIGURATION.md)

---

Seven small files that are secretly two things at once: an app that installs a toolchain, and a data source every editor above reads to figure out what it needs.

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

[← Zed.nix](apps-dev-zed.md) · [Index](CONFIGURATION.md) · [DevTools.nix →](apps-dev-devtools.md)
