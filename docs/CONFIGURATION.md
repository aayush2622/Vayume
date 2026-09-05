# Configuration reference

`.nix` files stay comment-free in this repo, so all the "why" lives here
instead. Organized to match `modules/` - find the file you're editing,
jump to its doc.

Looking for "how do I add a host/user/app" instead? That's the README's
[Using this on your own machine](../README.md#using-this-on-your-own-machine)
and [Extending it](../README.md#extending-it) - the walkthrough, not the
deep dive.

## Contents

- [How it's wired together](#how-its-wired-together)
- [Project structure](#project-structure)

**Core & hosts**
- [core/Users.nix](core.md#modulescoreusersnix)
- [core/DevLanguages.nix](core.md#modulescoredevlanguagesnix)
- [core/PluginUpdateCheck.nix](core.md#modulescorepluginupdatechecknix)
- [hosts/\<name\>/Host.nix](core.md#moduleshostsnamehostnix)
- [hosts/\<name\>/\_hardware.nix](core.md#moduleshostsname_hardwarenix)
- [hosts/\<name\>/Vm.nix](core.md#moduleshostsnamevmnix)

**Desktop**
- [desktop/Dms.nix](desktop.md#modulesdesktopdmsnix)
- [desktop/Niri.nix](desktop.md#modulesdesktopnirinix)
- [desktop/Hyprland.nix](desktop.md#modulesdesktophyprlandnix)
- [desktop/Fonts.nix / Portals.nix](desktop.md#modulesdesktopfontsnix--portalsnix)
- [desktop/Baseline.nix](desktop.md#modulesdesktopbaselinenix)
- [desktop/Matugen.nix](desktop.md#modulesdesktopmatugennix)

**System**
- [system/DevTooling.nix](system.md#modulessystemdevtoolingnix)
- [system/Zram.nix](system.md#modulessystemzramnix)
- [system/GrubTheme.nix](system.md#modulessystemgrubthemenix)

**Apps - development**
- [apps/development/editors/vscode/Vscode.nix](apps-development.md#modulesappsdevelopmenteditorsvscodevscodenix)
- [apps/development/editors/androidStudio/AndroidStudio.nix](apps-development.md#modulesappsdevelopmenteditorsandroidstudioandroidstudionix)
- [apps/development/editors/zed/Zed.nix](apps-development.md#modulesappsdevelopmenteditorszedzednix)
- [apps/development/devTools/DevTools.nix](apps-development.md#modulesappsdevelopmentdevtoolsdevtoolsnix)
- [apps/development/freeClaudeCode/FreeClaudeCode.nix](apps-development.md#modulesappsdevelopmentfreeclaudecodefreeclaudecodenix)
- [apps/development/languages/\*/\*.nix](apps-development.md#modulesappsdevelopmentlanguagesnix) (Cpp, Rust, Kotlin, Flutter [+Dart], Nix, Qt)

**Apps - gaming**
- [apps/gaming/Gaming.nix](apps-gaming.md#modulesappsgaminggamingnix)

**Apps - utils**
- [apps/utils/zenBrowser/ZenBrowser.nix](apps-utils.md#modulesappsutilszenbrowserzenbrowsernix)
- [apps/utils/spicetify/Spicetify.nix](apps-utils.md#modulesappsutilsspicetifyspicetifynix)
- [apps/utils/nautilus/Nautilus.nix](apps-utils.md#modulesappsutilsnautilusnautilusnix)
- [apps/utils/bitwarden/Bitwarden.nix](apps-utils.md#modulesappsutilsbitwardenbitwardennix)
- [apps/utils/stateBackup/StateBackup.nix](apps-utils.md#modulesappsutilsstatebackupstatebackupnix)
- [apps/utils/terminal/Terminal.nix](apps-utils.md#modulesappsutilsterminalterminalnix)
- [apps/utils/vesktop/Vesktop.nix](apps-utils.md#modulesappsutilsvesktopvesktopnix)
- [apps/utils/distrobox/Distrobox.nix](apps-utils.md#modulesappsutilsdistroboxdistroboxnix)

---

## How it's wired together

`flake.nix` calls `inputs.import-tree ./modules`, which just grabs every
`.nix` file under `modules/` and imports it automatically. No import list
to maintain. Two things trip people up because of that:

- **Anything with `/_` in the path gets skipped.** That's why
  `_hardware.nix` gets to be a plain NixOS module instead of needing its
  own `flake.nixosModules.*` name - it's deliberately invisible to the
  auto-import.
- **Untracked files are invisible files.** A new `.nix` file that hasn't
  been `git add`ed doesn't error, it just quietly doesn't exist as far as
  `nix flake check`/`nix build` is concerned. If something "isn't picking
  up," this is almost always why.

Three option namespaces get filled in across all these files:

| Namespace | Set by | Read by |
| --- | --- | --- |
| `flake.nixosModules.*` | `hosts/`, `desktop/`, `system/`, `core/Users.nix` | `Host.nix`'s `modules` list |
| `flake.homeModules.apps.*` | `modules/apps/**/*.nix` (any depth) | `core/Users.nix`, via `vayori.apps` |
| `flake.devLanguages.*` | `modules/apps/development/languages/*/*.nix` | `Vscode.nix`/`AndroidStudio.nix`, filtered by `vayori.apps` |

None of this cares about file paths, only attribute names - `Host.nix`
imports `self.nixosModules.dms`, never a path. Move a file wherever you
want; nothing breaks unless you also rename the attribute.

## Project structure

```
modules/
  core/        flake-parts wiring + the shared user/app framework
  hosts/<name>/  one machine: Host.nix + _hardware.nix, nothing else
  desktop/     the DE stack — compositor, shell, login theme, fonts,
               portals, and the GTK/Qt baseline every user gets
  system/      system-level infra unrelated to the desktop
  apps/        per-user opt-in modules (vayori.apps), one folder each
  assets/      static, non-code files (wallpapers)
```

The `core`/`desktop`/`system` split, quickly: **core** is pure plumbing -
nothing in it is itself a setting, just the framework that lets settings
exist (`Parts.nix`, `Registry.nix`, the `vayori.users`/`vayori.apps`
definitions). **desktop** is everything that makes this rice look and
feel the way it does - swap the compositor or shell and this whole
category changes. **system** is infra that doesn't care what desktop
you're running - Docker, GRUB theming. The dividing line is "does this
need niri/DMS to exist" - GRUB theming doesn't, so it lives in `system`
even though it's still, technically, theming.

`apps/` splits into three categories - `development/`, `gaming/`,
`utils/` - and every app gets a folder (`apps/<category>/<name>/<name>.nix`)
whether it needs one yet or not, so adding a stray asset later never means
restructuring anything. The category itself is just for tidiness: the
only thing that actually matters anywhere else in the repo is the
`flake.homeModules.apps.<Name>` attribute name, so an app can move
between categories, or nest as deep as it wants, and nothing outside its
own folder notices.

`apps/development/editors/` is where the three editors live (`Vscode`,
`AndroidStudio`, `Zed`) - each a normal app that also *reads*
`flake.devLanguages` (more on that below). Grouped in their own folder
mostly so "these are the apps that care about languages" is obvious from
the file tree instead of something you'd have to go grepping for.

`apps/development/languages/` is its own thing inside `development/`: one
folder per language (`Cpp`, `Rust`, `Kotlin`, `Flutter` - covers Dart too,
one toggle does both, see that section - `Nix`, `Qt`). Each one is a
normal app (`flake.homeModules.apps.<Lang>` installs the actual
LSP/toolchain) that's *also* a data source (`flake.devLanguages.<Lang>`)
every editor reads to figure out what extensions it needs. See
[core/DevLanguages.nix](core.md#modulescoredevlanguagesnix).

`apps/gaming/` is one app (`Gaming`) spread across a few files just so no
single file gets huge: `Gaming.nix` is the real
`flake.homeModules.apps.Gaming` entry, and `_launchers.nix`/`_proton.nix`/
`_performance.nix` are plain fragments it pulls in by relative path. The
underscore keeps import-tree from trying to treat them as modules of
their own - same trick as `_hardware.nix`.

---
