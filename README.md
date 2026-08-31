# Vayori

<p>
  <img alt="Built with Nix" src="https://img.shields.io/badge/built%20with-Nix-5277C3?logo=nixos&logoColor=white">
  <img alt="NixOS" src="https://img.shields.io/badge/NixOS-unstable-informational?logo=nixos&logoColor=white">
  <img alt="Compositor" src="https://img.shields.io/badge/compositor-niri-blue">
  <img alt="Shell" src="https://img.shields.io/badge/shell-DankMaterialShell-purple">
  <img alt="License" src="https://img.shields.io/badge/license-unspecified-lightgrey">
</p>

My NixOS setup. [niri](https://github.com/YaLTeR/niri) for windows,
[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) for
the bar/launcher/notifications, and a wallpaper-matching color theme that's
gone a little too far - it's in the editors, the login screen, GRUB, Wine's
dialog boxes. Change your wallpaper and basically everything on the machine
recolors itself to match. Rounded corners and blur on top because it's 2026
and we deserve nice things.

Written with [flake-parts](https://flake.parts/) and
[import-tree](https://github.com/vic/import-tree), which just means: every
`.nix` file under `modules/` gets picked up automatically. No import list to
maintain, no forgetting to wire a new file in. Drop a file in the right
folder and it works - see [Extending it](#extending-it).

> [!WARNING]
> **This is my actual laptop's config, not a template you can just run.**
> `modules/hosts/Diablo/` has my real disk UUIDs and GPU IDs baked in. Clone
> this and rebuild without changing anything and your machine **will not
> boot** - it'll go looking for hardware that isn't there. Totally fine to
> build on top of, just read
> [Using this on your own machine](#using-this-on-your-own-machine) first.

## Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start-on-the-reference-machines-exact-hardware)
- [Secrets](#secrets)
- [Using this on your own machine](#using-this-on-your-own-machine)
- [Layout](#layout)
- [Extending it](#extending-it)
- [Documentation](#documentation)
- [Keybinds](#keybinds-niri)
- [Credits](#credits)
- [Known caveats](#known-caveats)

---

## Features

**Desktop**
- **niri**, wired up through
  [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules)
  instead of home-manager's built-in module, because I wanted the whole
  compositor config - keybinds, layout, window rules - in one file I can
  actually read top to bottom.
- **DankMaterialShell** does the bar, launcher (`Mod+A`/`Mod+S`), clipboard,
  notifications, lock screen, and a wallpaper carousel that drives the
  color theme for basically everything else.
- A custom **SDDM** login screen and a **GRUB** theme (an orange/purple
  wave pattern, generated at build time), both matched to the same cursor
  as the desktop. Yes, I theme the boot loader. No regrets.
- Terminal: kitty + zsh with the usual plugins, plus fastfetch showing a
  random logo every time you open a shell, just to keep things interesting.

**Development**
- Three editors - **VS Code**, **Android Studio**, **Zed** - set up with my
  actual extensions and settings, pinned as real Nix packages instead of
  "trust me, install these 40 things by hand."
- Seven **language toggles** (C/C++, Rust, Kotlin, Dart+Flutter, Nix, Qt,
  Python). Flip one on and it installs that language's tooling *and* tells
  all three editors which of their own extensions to grab for it. Flip it
  off and everything related vanishes from every editor - no leftover
  extensions for languages I don't even have installed anymore. Details in
  [docs/core.md](docs/core.md#modulescoredevlanguagesnix).
- [Free Claude Code](https://github.com/Alishahryar1/free-claude-code) runs
  quietly in the background so Claude Code (CLI, VS Code, Android Studio)
  can talk to a free-tier model instead of burning through the paid API.
  Needs one free API key to set up, see
  [docs/apps-development.md](docs/apps-development.md#modulesappsdevelopmentfreeclaudecodefreeclaudecodenix).

**Gaming**
- Steam, Lutris + Heroic, GE-Proton, gamescope presets, and a MangoHud
  overlay that doesn't look like it's from 2015. Even Steam, Heroic,
  Vesktop, and Wine's ugly native dialogs get color-matched. I said it went
  too far and I meant it.

**Everything else**
- Nautilus, Zen Browser (locked down, no telemetry nonsense), Spicetify,
  Bitwarden, a small dev-tools bundle, and Vesktop - all opt-in per
  machine, all under `modules/apps/`.
- ASUS ROG stuff: a bar widget
  ([DankAsusControl](https://github.com/shazzaam7/DankAsusControl)) for
  switching power profiles and GPU mode without alt-tabbing to a terminal.

## Prerequisites

- NixOS (installed, or the live ISO) with flakes turned on - or just add
  `--extra-experimental-features 'nix-command flakes'` to every command
  below.
- UEFI boot. The GRUB config assumes it.

---

## Quick start (on the reference machine's exact hardware)

Two files never get committed - real disk UUIDs and a real username/password
hash aren't something to publish - so the build refuses to evaluate until
you've created them from their templates:

```bash
git clone https://github.com/aayush2622/Vayori-Rice.git vayori
cd vayori
cp modules/hosts/Diablo/_hardware.nix.example modules/hosts/Diablo/_hardware.nix
cp modules/hosts/Diablo/_user.nix.example modules/hosts/Diablo/_user.nix
$EDITOR modules/hosts/Diablo/_user.nix   # at least pick a username
sudo nixos-rebuild switch --flake path:.#Diablo
```

> [!NOTE]
> `path:.#Diablo`, not `.#Diablo` - see
> [Using this on your own machine](#using-this-on-your-own-machine) below for
> why that matters.

> [!NOTE]
> Any user without a `hashedPassword` set logs in with `changeme` the first
> time. Run `passwd` right after and forget I told you that.

---

## Secrets

A handful of small credentials (Free Claude Code's model-provider API
keys, a WakaTime key for Zed/VS Code/Android Studio, a Bitwarden CLI
email) live directly in that user's `secrets` block in `_user.nix`:

```nix
ash = {
  # ...
  secrets = {
    WAKATIME_API_KEY = "...";
    RBW_EMAIL = "...";
    PROVIDERS = {
      NVIDIA_NIM_API_KEY = "...";
    };
  };
};
```

Edit `_user.nix` and rebuild to apply - see
[Using this on your own machine](#using-this-on-your-own-machine). No
separate runtime file, no `$EDITOR` step; each app module reads its own
key straight from there at build time and writes it into whatever
config format that app natively wants (`crudini` for WakaTime,
`jq`-merged JSON for Zed/rbw, `.env` lines for Free Claude Code). Left
out entirely, a key falls back to a `"REPLACE_ME"` placeholder instead
of a Nix error - and whichever plugin/extension needed it (WakaTime in
Zed/VS Code/Android Studio) just doesn't get installed, rather than
sitting there configured with a key that would only fail. Same for rbw's
email and each `PROVIDERS` entry individually - only the ones with a
real value get written anywhere.

`PROVIDERS` is open-ended - Free Claude Code supports 17+ model
providers, and adding another one (`OPENROUTER_API_KEY`,
`DEEPSEEK_API_KEY`, whatever matches the provider) is just another line
in that attrset. No encryption layer, no keypair to generate or lose,
either - these aren't high-stakes secrets (a proxy token, a
time-tracking key, an email address), and `_user.nix` already lives
somewhere that's never committed to git - so a whole extra layer for
them wasn't buying much. Worth knowing: since these values flow through
normal Nix derivations to reach the files apps read, each one does end
up readable in `/nix/store` (world-readable on this machine, same as
any other Nix-built config) - fine for the low-stakes values above, not
a place to put anything you'd consider a real secret.

Actual login sessions (Zen Browser, Vesktop, VS Code/Zed accounts, rbw,
Bitwarden desktop, Free Claude Code's `.env`) get symlinked into one
fixed folder, `~/.config/vayori/session`, automatically on every
rebuild, regardless of where this repo happens to be checked out. So
that one folder is the only thing that ever needs to move for a fresh
install to come back already logged into everything. Copy it directly
(`cp -r`) for a same-trust move, or use a password-encrypted archive
for anywhere less trusted:

```bash
vayori-app-state backup ~/vayori-session.enc    # on the old machine
vayori-app-state restore ~/vayori-session.enc   # on the new one
```

Full mechanism is in
[docs/core.md](docs/core.md#modulescoreusersnix) (the `secrets` shape and
how each app reads it) and
[docs/apps-utils.md](docs/apps-utils.md#modulesappsutilsstatebackupstatebackupnix)
(the session folder + CLI).

---

## Using this on your own machine

A host is **three files** under `modules/hosts/<name>/`: `Host.nix`
(apps, timezone, bootloader), `_hardware.nix` (your disks and GPU,
basically `hardware-configuration.nix` with a different name), and
`_user.nix` (who logs in - usernames, groups, password hash, secrets).
Nothing else in the repo cares which machine it's running on.

> [!TIP]
> `_hardware.nix`/`_user.nix` start with an underscore on purpose.
> `import-tree` auto-imports everything under `modules/` *except* paths
> containing `/_`, so these stay plain NixOS modules, imported explicitly
> by `Host.nix`, instead of turning into their own thing. They're also
> **gitignored** - real disk UUIDs and a real username/password hash
> aren't something to publish - and required: `Host.nix` refuses to
> evaluate without both actually present, with a clear error pointing at
> the matching `*.nix.example` template if one's missing. Keep the
> underscore if you rename either.

> [!IMPORTANT]
> Build with `path:.#<host>`, not bare `.#<host>`. Nix resolves a bare
> flake ref through git's tracked-files-only view of the repo, which
> would make these two gitignored files look "missing" even when they're
> sitting right there on disk - `path:` uses the real directory as-is
> instead. Every command below already does this; the rebuild button in
> the bar does too.

1. **Copy the host folder**:

   ```bash
   cp -r modules/hosts/Diablo modules/hosts/<yourhostname>
   ```

   (This also copies your already-filled-in `_hardware.nix`/`_user.nix` if
   Diablo's got them - fine if it's the same machine under a new name,
   replace them in the next two steps if it's actually different hardware
   or different people.)

2. **Generate your own `_hardware.nix`**:

   ```bash
   sudo nixos-generate-config --show-hardware-config > modules/hosts/<yourhostname>/_hardware.nix
   ```

   Delete the Nvidia/Optimus block it copied over unless you're also on an
   Nvidia laptop - `intelBusId`/`nvidiaBusId` are PCI addresses specific to
   my machine, not yours.

3. **Write your own `_user.nix`**, starting from the template:

   ```bash
   cp modules/hosts/<yourhostname>/_user.nix.example modules/hosts/<yourhostname>/_user.nix
   mkpasswd -m sha-512   # paste the result in as hashedPassword
   $EDITOR modules/hosts/<yourhostname>/_user.nix
   ```

   One entry per person - `fullName`/`hashedPassword`/`extraGroups`/
   `secrets`, see [docs/core.md](docs/core.md#modulescoreusersnix) for the
   full shape and what each field does. Leave `hashedPassword` out and
   that person gets the `changeme` initial-password fallback instead.

4. **Edit `Host.nix`**:
   - Rename `Diablo` to `<yourhostname>` (the `nixosConfigurations` line and
     `networking.hostName`).
   - Adjust `vayori.apps` - just a list of app names pulled from
     `modules/apps/{development,gaming,utils}/**/*.nix`. `Host.nix` groups
     them by category for readability, but that's purely cosmetic - it
     flattens to a plain list before anything reads it.
   - Fix up timezone/locale/bootloader further down.

5. **Rebuild**:

   ```bash
   sudo nixos-rebuild switch --flake path:.#<yourhostname>
   ```

---

## Layout

<details>
<summary>Directory map (click to expand)</summary>

```text
flake.nix                    inputs + `import-tree ./modules` (see modules/core/)
modules/
  core/                       flake-parts wiring + the shared user/app framework, not per-host config
    Parts.nix                   supported `systems` for flake-parts
    Registry.nix                 declares flake.homeModules (flake-parts has no builtin for it)
    Users.nix                     the vayori.users / vayori.apps option definitions
    DevLanguages.nix              flake.devLanguages - language modules publish here, editors read it
    PluginPins.nix                declares flake.pluginPins - pinned-plugin specs, per app
    PluginUpdateCheck.nix         checks pinned plugins/extensions for updates, no extra commands needed
  hosts/<name>/               everything for one machine - just these two files:
    Host.nix                    nixosConfigurations.<name>: apps, timezone, bootloader, packages
    _hardware.nix                hardware-configuration.nix equivalent (disks, GPU) - gitignored + required, see .example
    _user.nix                    who logs in - usernames, groups, password hash, secrets - gitignored + required, see .example
  desktop/                    the DE stack: compositor, shell, login theme, fonts, portals
    Niri.nix / Dms.nix / Fonts.nix / Portals.nix / Baseline.nix (GTK/Qt theming every user gets)
    Matugen.nix                 shared matugen template content, one attr per themed app
  system/                     system-level infra unrelated to the desktop
    DevTooling.nix (docker/libvirtd/adbusers) / Zram.nix / GrubTheme.nix
  apps/                       opt-in per-user (home-manager) modules, picked via vayori.apps - one folder each
    development/                editors, dev-tools, FreeClaudeCode
      editors/                     Vscode, AndroidStudio, Zed - one folder each
      languages/                   one folder per language (Cpp/Rust/Kotlin/Flutter[+Dart]/Nix/Qt/Python) -
                                    installs that language's LSP/toolchain and publishes
                                    self.devLanguages.<Lang>, which editors read to decide which of
                                    their own extensions/plugins to install (see core/DevLanguages.nix)
    gaming/                      Gaming.nix (aggregator) + _launchers/_proton/_performance.nix
                                    (underscore = plain fragments, not their own flake-parts modules)
    utils/                       everything else opt-in: Terminal, Nautilus, ZenBrowser, Vesktop, ...
  assets/
    wallpapers/                 default wallpaper set (session.json seeded to point here, see desktop/Dms.nix)
```

</details>

## Extending it

**Add a person**: another entry in `_user.nix`'s `vayori.users` attrset (see
[Using this on your own machine](#using-this-on-your-own-machine) above) -
not in `Host.nix`, which doesn't declare users at all. Apps are picked once
per *machine*, not per person - everyone on a host gets the same set.

**Add an app**: drop a folder anywhere under `modules/apps/development/`,
`modules/apps/gaming/`, or `modules/apps/utils/` that sets
`flake.homeModules.apps.<Name>`. That's it - it's now a valid `vayori.apps`
entry automatically. The category folder is just for tidiness; only the
attribute name actually matters.

**Add a language**: drop a folder in `modules/apps/development/languages/`
that sets `flake.homeModules.apps.<Lang>` (the actual packages) and
`flake.devLanguages.<Lang>` (what the editors should install for it - see
[docs/core.md](docs/core.md#modulescoredevlanguagesnix) for the shape they
expect). Add `<Lang>` to `vayori.apps` and every editor picks it up on its
own.

**Add a host**: copy `modules/hosts/Diablo/`, follow
[Using this on your own machine](#using-this-on-your-own-machine).

---

## Documentation

The `.nix` files are kept comment-free - all the "why" (and the handful of
real gotchas worth knowing before you touch something) lives in `docs/`
instead, split up to match `modules/` so no single file turns into a wall
of text:

| Doc | Covers |
| --- | --- |
| [docs/CONFIGURATION.md](docs/CONFIGURATION.md) | Index - how it's all wired together, links to everything below |
| [docs/core.md](docs/core.md) | Users, apps, languages, the plugin checker, host/hardware config |
| [docs/desktop.md](docs/desktop.md) | DMS, niri, fonts/portals, the GTK/Qt baseline, matugen templates |
| [docs/system.md](docs/system.md) | Docker/libvirtd, GRUB theming |
| [docs/apps-development.md](docs/apps-development.md) | The three editors, per-language toggles, dev-tools, Free Claude Code |
| [docs/apps-gaming.md](docs/apps-gaming.md) | The gaming setup |
| [docs/apps-utils.md](docs/apps-utils.md) | Zen Browser, Spicetify, Nautilus, Bitwarden, Terminal, Vesktop |

Find the file you're editing, jump to its doc. Worth a read before you
touch `Host.nix`, `Niri.nix`, or `Dms.nix` especially - each has at least
one landmine that won't announce itself until it's already gone off.

---

## Keybinds (niri)

<details open>
<summary>Core bindings</summary>

| Key | Action |
| --- | --- |
| `Mod+Return` | terminal (kitty) |
| `Mod+E` | file manager (nautilus) |
| `Mod+C` | code (vscode) |
| `Mod+B` | browser (zen) |
| `Mod+A` / `Mod+S` | DMS app launcher (spotlight) |
| `Mod+V` | clipboard history |
| `Mod+Comma` | settings |
| `Mod+L` | lock |
| `Mod+Tab` | overview |
| `Mod+Shift+W` | wallpaper carousel |
| `Mod+Q` / `Alt+F4` | close window |
| `Mod+F` / `Shift+F11` | fullscreen |
| `Mod+W` | toggle floating |
| `Mod+←/→/↑/↓` | focus column/window |
| `Mod+Shift+←/→/↑/↓` | move column/window |
| `Mod+1`-`0`, `Mod+Shift+1`-`0` | switch / move to workspace 1-10 |
| `Mod+Shift+P` | color picker (hyprpicker) |
| `Print` / `Shift+Print` | screenshot region / screen |
| `Control+Shift+Escape` | btop |

</details>

Full list in [modules/desktop/Niri.nix](modules/desktop/Niri.nix).

---

## Credits

Standing on the shoulders of (see `flake.nix` for the full list):

| Project | What it's for |
| --- | --- |
| [niri](https://github.com/YaLTeR/niri) | scrolling Wayland compositor |
| [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) | bar, launcher, lock, theming |
| [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules) | declarative niri config wrapper |
| [home-manager](https://github.com/nix-community/home-manager) | per-user configuration |
| [flake-parts](https://flake.parts/) | modular flake structure |
| [import-tree](https://github.com/vic/import-tree) | auto-import every module file |
| [zen-browser-flake](https://github.com/youwen5/zen-browser-flake) | Zen Browser packaging |
| [spicetify-nix](https://github.com/Gerg-L/spicetify-nix) | Spotify theming |
| [nix-vscode-extensions](https://github.com/nix-community/nix-vscode-extensions) | VS Code marketplace extensions, auto-updated |
| [nix-jetbrains-plugins](https://github.com/nix-community/nix-jetbrains-plugins) | Android Studio plugins, auto-updated |
| [Elegant-grub2-themes](https://github.com/vinceliuice/Elegant-grub2-themes) | GRUB theme (wave) |

---

## Known caveats

- The `dankAsusControlCenter` widget builds fine but hasn't actually met
  real ASUS hardware yet in testing - see
  [docs/desktop.md](docs/desktop.md#modulesdesktopdmsnix) if `asusctl`/
  `supergfxctl` won't cooperate.
- No license file. Ask before you go redistributing this wholesale.
