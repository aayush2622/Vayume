<div align="center">

# Vayume

**A NixOS flake for a complete Wayland desktop — niri and Hyprland, DankMaterialShell, one config file, and a settings app that edits it.**

[![eval](https://github.com/aayush2622/Vayume/actions/workflows/eval.yml/badge.svg)](https://github.com/aayush2622/Vayume/actions/workflows/eval.yml)
![Built with Nix](https://img.shields.io/badge/built%20with-Nix-5277C3?logo=nixos&logoColor=white)
![Compositors](https://img.shields.io/badge/compositors-niri%20%7C%20Hyprland-4c6ef5)
![Shell](https://img.shields.io/badge/shell-DankMaterialShell-8b5cf6)
[![License: MIT](https://img.shields.io/badge/license-MIT-22c55e)](LICENSE)

<img src="screenshots/desktop.png" width="49%" alt="Desktop">
<img src="screenshots/dev.png" width="49%" alt="Development setup">

</div>

## Overview

Vayume is a NixOS configuration built with [flake-parts](https://flake.parts/) and [import-tree](https://github.com/vic/import-tree). It runs **niri** and **Hyprland** side by side with identical keybinds, both driving [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell), and generates a colour scheme from the wallpaper with [matugen](https://github.com/InioX/matugen) that reaches editors, the browser, Discord, Spotify, Steam, Wine, GTK and Qt.

Everything you change day to day lives in one gitignored file per host, `_config.nix`. The **Vayume Settings** app in the DMS control center and the `vayume` CLI both edit that same file, so the repository stays the single source of truth and every change is applied — or rolled back — through a normal rebuild.

> [!WARNING]
> This is a real laptop configuration, not a drop-in template. Disk UUIDs and user details live in two gitignored files that you create yourself; the build refuses to evaluate without them. See **[Getting started](docs/getting-started.md)** — it takes a couple of minutes.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Vayume Settings](#vayume-settings)
- [Command line](#command-line)
- [Keybinds](#keybinds)
- [Project layout](#project-layout)
- [Testing](#testing)
- [Documentation](#documentation)
- [Known limitations](#known-limitations)
- [Credits](#credits)
- [License](#license)

## Features

| Area | What you get |
|---|---|
| **Desktop** | niri and Hyprland with identical keybinds, chosen at login · DankMaterialShell bar, launcher, notifications and control center · wallpaper-derived colours via matugen, following the dark/light toggle |
| **Boot and login** | Custom Material 3 GRUB theme · SDDM login screen and DMS lock screen built from one shared QML design — fixed wallpaper at login, live wallpaper and colours when locked |
| **Settings** | Vayume Settings: apps, languages, default apps, users, every `vayume.*` option, maintenance commands, search, live rebuild log |
| **Development** | VS Code, Zed and Android Studio with language-aware extensions · one toggle each for C++, Rust, Kotlin, Flutter/Dart, Nix, Qt and Python · cc-switch · ripgrep, fd, fzf, btop, nil, nixfmt |
| **Gaming** | Steam, Lutris, Heroic, GE-Proton, MangoHud, gamemode · colour-matched Wine dialogs and Proton prefixes |
| **Network** | DNS over TLS by default · network-stack hardening · whole-machine Tor proxy behind a control-center toggle |
| **Apps** | Zen Browser with live theme reload · Nautilus and Thunar · Spicetify and Spotifast · Bitwarden and rbw · Vesktop with Vencord · Waydroid · Distrobox · AppImage support |
| **Tooling** | One `vayume` command with an fzf menu and completion · encrypted app-state backup and restore · a CI test suite that evaluates every host |

## Requirements

- NixOS on a UEFI machine. Flakes don't need to be enabled beforehand — for the very first rebuild `install.sh` prints the right command, or prefix it yourself with `sudo env NIX_CONFIG='experimental-features = nix-command flakes'`.
- `mkpasswd` to generate password hashes: `nix run nixpkgs#mkpasswd`.

## Installation

### Try the existing host

```bash
git clone https://github.com/aayush2622/Vayume.git vayume
cd vayume
cp modules/hosts/Diablo/_hardware.nix.example modules/hosts/Diablo/_hardware.nix
cp modules/hosts/Diablo/_config.nix.example modules/hosts/Diablo/_config.nix
chmod 600 modules/hosts/Diablo/_config.nix  # it will hold password hashes
$EDITOR modules/hosts/Diablo/_config.nix   # at minimum, pick a username
sudo nixos-rebuild switch --flake path:.#Diablo
```

> **Why `path:.#Diablo`?** A bare flake ref resolves through git's *tracked files* view, making the gitignored `_hardware.nix` and `_config.nix` appear missing. `path:` reads the real directory as-is.

Any user without a `hashedPassword` gets `changeme` as a password. Users are immutable (`users.mutableUsers = false`), so `passwd` changes don't survive the next rebuild — set a real hash in `_config.nix`, or use **Vayume Settings → Users → Password** and rebuild.

### Add your own host

```bash
# Interactive (recommended)
./install.sh

# Or manual:
mkdir modules/hosts/<yourhostname>
cp modules/hosts/Diablo/{Host.nix,*.example} modules/hosts/<yourhostname>/
sudo nixos-generate-config --show-hardware-config > modules/hosts/<yourhostname>/_hardware.nix
# The host name is the folder name; edit Host.nix for timezone, locale, bootloader
cp modules/hosts/<yourhostname>/_config.nix.example modules/hosts/<yourhostname>/_config.nix
# Fill in _config.nix: username, password hash (mkpasswd -m sha-512), enable apps
sudo nixos-rebuild switch --flake path:.#<yourhostname>
```

`./install.sh --help` shows all flags; `--dry-run` previews without writing anything.

### Rebuild, roll back, test

```bash
vayume                                  # every Vayume helper, as a searchable menu (vayume help lists them)
vayume rebuild                          # after first boot: rebuild from wherever the repo lives, no password prompt (wheel users)
sudo nixos-rebuild switch --rollback    # back to the previous generation (older ones are in the GRUB menu)
nix run path:.#vm                       # boot this config in a throwaway QEMU VM first
./tests/eval.sh                         # does a fresh clone of the repo still evaluate? (what CI runs)
```

## Configuration

Everything you configure day-to-day lives in **one file**: `modules/hosts/<host>/_config.nix` (gitignored, required).

```nix
# modules/hosts/<host>/_config.nix
{ pkgs, ... }:
{
  vayume.users = {
    yourname = {
      fullName = "Your Name";
      extraGroups = [ "networkmanager" "wheel" "video" "input" ];  # "wheel" = sudo
      hashedPassword = "$6$...";  # mkpasswd -m sha-512
      secrets = {
        WAKATIME_API_KEY = "waka_...";
        RBW_EMAIL = "you@example.com";
      };
    };
  };

  vayume.apps = {
    Vscode.enable = true;
    Gaming.enable = true;
    Rust.enable = false;
    # ... one line per module under modules/apps/
  };
}
```

- **Type `vayume.apps.`** in an editor with Nix LSP — every available app appears by name. A typo is a real evaluation error, not a silently ignored entry.
- **Leave an app `false`** rather than deleting it — keeps it visible as "exists but off".
- **Default apps** (`vayume.defaultApps.editor = "zeditor";` etc.) pick which enabled app opens folders, links and code files, and which one the keybinds start — see [docs/desktop-default-apps.md](docs/desktop-default-apps.md).
- **Secrets** live here too (`vayume.users.<name>.secrets`). Missing keys (or the whole block) fall back to `"REPLACE_ME"` placeholders — the consumer simply disables that feature instead of configuring it with a useless value. Full schema: [docs/core-users.md](docs/core-users.md).

## Vayume Settings

Open **Vayume Settings** from the DMS control center. It reads and writes the real `_config.nix` through `vayume config`, validates every write with Nix, and shows which changes are saved but not yet applied.

| Page | Purpose |
|---|---|
| **Overview** | Host, git and rebuild status, quick counts, and every pending change with an undo button |
| **Appearance** | Font size and family, cursor theme |
| **Applications** / **Development** | Enable apps, languages, editors and tools; each app's own options open inside its card |
| **Default Apps** | Which app handles links, folders and code, and which one the keybinds start |
| **System Options** | Every `vayume.*` option declared by a module, discovered automatically, with search and a Modified filter |
| **Users** | Accounts, groups, per-user packages from a nixpkgs search, app secrets and passwords |
| **Maintenance** | Rebuild, read-only checks and reports, and cleanup commands that ask for confirmation |
| **About** | Host, repository, branch and config file, with copy and open actions |

The sidebar search finds options, apps and commands across every page and lets you change them in place. Shortcuts: `Ctrl+F` search · `Ctrl+1`–`Ctrl+9` pages · `Ctrl+R` reload · `Ctrl+B` rebuild · `Ctrl+L` log · `Esc` clear search.

## Command line

```bash
vayume                        # searchable menu of every helper (vayume help lists them)
vayume rebuild                # rebuild from wherever the repo lives, no password prompt for wheel users
vayume config apps list       # the same backend Vayume Settings uses, as JSON
vayume config validate        # check _config.nix before rebuilding
vayume disk                   # where the disk space goes and what is safe to reclaim
```

Adding a command is a `vayume.commands` entry in the module that owns it; see [docs/core-commands.md](docs/core-commands.md).

## Keybinds

Same on both compositors. `Mod` = Super.

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `Mod+Return` | Terminal | `Mod+Q` / `Alt+F4` | Close window |
| `Mod+E` | Files | `Mod+W` | Float |
| `Mod+C` | Code editor | `Mod+F` / `Shift+F11` | Fullscreen |
| `Mod+B` | Browser | `Mod+←↑↓→` | Focus |
| `Mod+A` | Launcher | `Mod+Shift+←↑↓→` | Move window |
| `Mod+V` | Clipboard | `Mod+1–0` | Workspace |
| `Mod+Comma` | Settings | `Mod+Shift+1–0` | Send to workspace |
| `Mod+L` | Lock | `Mod+Shift+P` | Color picker |
| `Mod+Shift+W` | Wallpapers | `Print` / `Shift+Print` | Screenshot |

**Hyprland extras:** mouse-drag move/resize (`Mod`+left/right click), scratchpad on `Mod+S`, silent workspace moves on `Mod+Alt+1–0`.

Full lists: [Niri.nix](modules/desktop/Niri.nix) · [Hyprland.nix](modules/desktop/Hyprland.nix)

## Project layout

```
flake.nix           inputs + import-tree ./modules
modules/
  vayume/           the settings schema itself — theme, users, apps, CLI/GUI backend
  core/             flake-parts wiring + shared app-registry framework
  lib/              shared helper values/functions
  hosts/<name>/     one machine: Host.nix + _hardware.nix (gitignored) + _config.nix (gitignored)
  desktop/          DE stack — compositor, shell, login theme, fonts, portals, GTK/Qt baseline
    dms/plugins/vayumeSettings/   the Vayume Settings app (ui/components, ui/pages)
    lockscreen/                   login/lock screen UI, shared by SDDM and the DMS lock
    sddm/Theme/                   the SDDM theme around it
  system/           system-level infra (GRUB theme, Docker, zram, network, Waydroid, VM harness)
  apps/             per-user opt-in modules (vayume.apps), one folder each
    development/      editors, languages, dev-tools, cc-switch
    gaming/           launchers, proton, performance tweaks
    utils/            terminal, browser, everything else
  assets/wallpapers/ default wallpaper set
```

**Add a person:** an entry in `_config.nix`.
**Add an app:** a folder under `modules/apps/*/` setting `flake.homeModules.apps.<Name>` — picked up automatically, then flip it on in `_config.nix`.
**Add a host:** `./install.sh`, or copy `Host.nix` + the `*.example` files from any folder under `modules/hosts/` into a new folder; the folder name becomes the host name.

**Conventions:** no comments in code — the reasoning lives in `docs/`, in each page's "Notes from the code" section; every `.nix` file is `nixfmt`-formatted. `tests/eval.sh` checks both.

## Testing

`tests/eval.sh` copies the tracked tree to a temporary directory and checks it the way CI does ([`.github/workflows/eval.yml`](.github/workflows/eval.yml)):

- shell scripts pass `bash -n` and shellcheck, every `.nix` file is `nixfmt`-formatted, and no code file carries comments (explanations live in `docs/`);
- markdown links resolve and the app registries agree with each other;
- every host evaluates with its example config, and with every app switched on and off;
- the terminal, font and `vayume` command wiring behave as expected, `vayume config` edits the example `_config.nix` correctly, and `install.sh` can create a new host end to end;
- `nix flake check` passes for every system.

```bash
./tests/eval.sh
nix run path:.#vm      # boot the configuration in a throwaway QEMU VM
```

## Documentation

[**docs/CONFIGURATION.md**](docs/CONFIGURATION.md) is the index: one page per module, in the order you would meet them, each linking to the next. Start with **[Getting started](docs/getting-started.md)**. Each page ends with a "Notes from the code" section holding the reasoning that would otherwise be code comments.

## Known limitations

- **`dankAsusControlCenter`** builds fine but hasn't met real ASUS hardware in testing — see [docs/desktop-dms.md](docs/desktop-dms.md) if `asusctl`/`supergfxctl` won't cooperate.
- This config assumes a single-user laptop workflow. Multi-user setups work but haven't been exercised heavily.
- Waydroid's first boot takes a while (image download + signature spoofing patch).
- **Spotifast is pinned to one release, not "latest".** Nix needs a fixed hash for the prebuilt binary, so [`Spotifast.nix`](modules/apps/utils/spotifast/Spotifast.nix) names a single version (currently `0.9.1`) and its hash. It never updates by itself: a new release means bumping both by hand — see [docs/apps-utils-spotifast.md](docs/apps-utils-spotifast.md).

## Credits

| Project | For |
|---------|-----|
| [niri](https://github.com/YaLTeR/niri) · [Hyprland](https://hypr.land) | The compositors |
| [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) | Bar, launcher, lock, theming |
| [matugen](https://github.com/InioX/matugen) | The color engine behind all of it |
| [home-manager](https://github.com/nix-community/home-manager) · [flake-parts](https://flake.parts/) · [import-tree](https://github.com/vic/import-tree) | The Nix plumbing |
| [Bibata](https://github.com/ful1e5/Bibata_Cursor) · [Catppuccin](https://github.com/catppuccin) | Cursor/editor theme |
| [cc-switch](https://github.com/farion1231/cc-switch) · [WakaTime](https://wakatime.com/) | Dev editor integrations |
| [Vencord](https://github.com/Vendicated/Vencord) · [DankAsusControl](https://github.com/shazzaam7/DankAsusControl) | Discord mods, ASUS widget |

Full pinned list: `flake.nix` inputs.

## License

Released under the [MIT License](LICENSE).
