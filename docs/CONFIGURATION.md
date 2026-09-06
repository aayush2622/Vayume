# Configuration reference

`.nix` files stay comment-free in this repo, so all the "why" lives here
instead - one page per module, in the order you'd actually meet them if
you were setting this up for the first time. Each page ends with a link
to the next one, so you can read straight through like a book, or jump
straight to the one file you're actually editing.

**New here?** [Getting started](getting-started.md) has the setup - the
three files a host needs, and how to point this at your own machine.
After that, [Host.nix](core-host.md) is the file everything else in this
repo exists to serve, and reading it first makes every other page make
more sense.

Looking for "how do I add a host/user/app" instead? That's
[Getting started](getting-started.md) - the walkthrough, not the deep
dive.

## The whole story, in reading order

**Setup**
0. [Getting started](getting-started.md)

**Core & hosts** - who this machine is, and who's allowed to use it
1. [hosts/\<name\>/Host.nix](core-host.md)
2. [hosts/\<name\>/\_hardware.nix](core-hardware.md)
3. [hosts/\<name\>/Vm.nix](core-vm.md)
4. [core/Users.nix](core-users.md)
5. [core/DevLanguages.nix](core-devlanguages.md)
6. [core/PluginUpdateCheck.nix](core-pluginupdatecheck.md)

**Desktop** - the part you actually look at all day
7. [desktop/Dms.nix](desktop-dms.md)
8. [desktop/Niri.nix](desktop-niri.md)
9. [desktop/Hyprland.nix](desktop-hyprland.md)
10. [desktop/Fonts.nix / Portals.nix](desktop-portals-fonts.md)
11. [desktop/Baseline.nix](desktop-baseline.md)
12. [desktop/Matugen.nix](desktop-matugen.md)

**System** - infrastructure that doesn't care what desktop you're running
13. [system/DevTooling.nix](system-devtooling.md)
14. [system/Zram.nix](system-zram.md)
15. [system/GrubTheme.nix](system-grubtheme.md)

**Apps - development**
16. [apps/development/editors/androidStudio/AndroidStudio.nix](apps-dev-androidstudio.md)
17. [apps/development/editors/vscode/Vscode.nix](apps-dev-vscode.md)
18. [apps/development/editors/zed/Zed.nix](apps-dev-zed.md)
19. [apps/development/languages/\*/\*.nix](apps-dev-languages.md) (Cpp, Rust, Kotlin, Flutter [+Dart], Nix, Qt)
20. [apps/development/devTools/DevTools.nix](apps-dev-devtools.md)
21. [apps/development/freeClaudeCode/FreeClaudeCode.nix](apps-dev-freeclaudecode.md)

**Apps - gaming**
22. [apps/gaming/Gaming.nix](apps-gaming.md)

**Apps - utils**
23. [apps/utils/zenBrowser/ZenBrowser.nix](apps-utils-zenbrowser.md)
24. [apps/utils/spicetify/Spicetify.nix](apps-utils-spicetify.md)
25. [apps/utils/nautilus/Nautilus.nix](apps-utils-nautilus.md)
26. [apps/utils/bitwarden/Bitwarden.nix](apps-utils-bitwarden.md)
27. [apps/utils/stateBackup/StateBackup.nix](apps-utils-statebackup.md)
28. [apps/utils/terminal/Terminal.nix](apps-utils-terminal.md)
29. [apps/utils/vesktop/Vesktop.nix](apps-utils-vesktop.md)
30. [apps/utils/distrobox/Distrobox.nix](apps-utils-distrobox.md)

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
[core/DevLanguages.nix](core-devlanguages.md).

`apps/gaming/` is one app (`Gaming`) spread across a few files just so no
single file gets huge: `Gaming.nix` is the real
`flake.homeModules.apps.Gaming` entry, and `_launchers.nix`/`_proton.nix`/
`_performance.nix` are plain fragments it pulls in by relative path. The
underscore keeps import-tree from trying to treat them as modules of
their own - same trick as `_hardware.nix`.

---

**[Start reading → Getting started](getting-started.md)**
