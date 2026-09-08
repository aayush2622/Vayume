# Vayori

<p>
  <img alt="Built with Nix" src="https://img.shields.io/badge/built%20with-Nix-5277C3?logo=nixos&logoColor=white">
  <img alt="Compositor" src="https://img.shields.io/badge/compositor-niri%20%2B%20Hyprland-blue">
  <img alt="Shell" src="https://img.shields.io/badge/shell-DankMaterialShell-purple">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-green"></a>
  <a href="https://github.com/aayush2622/Vayori-Rice/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/aayush2622/Vayori-Rice?style=flat&color=yellow"></a>
</p>

My NixOS setup. [niri](https://github.com/YaLTeR/niri) and
[Hyprland](https://hypr.land) side by side - same keybinds, picked at the
login screen - both driving
[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell), with a
wallpaper-matching color theme that's gone a little too far: editors, login
screen, GRUB, Discord, Wine dialogs, all of it.

Written with [flake-parts](https://flake.parts/) +
[import-tree](https://github.com/vic/import-tree), so every `.nix` file under
`modules/` gets picked up automatically - no import list to maintain.

> [!WARNING]
> This is my actual laptop's config, not a template you run as-is. Real
> disk UUIDs and login info live in two gitignored files that don't exist
> until you make them - the build refuses to evaluate without them, on
> purpose. Takes two minutes:
> **[Getting started](docs/getting-started.md)**.

If this saves you an evening, a star costs nothing. ⭐

<p>
  <img src="screenshots/desktop.png" width="49%">
  <img src="screenshots/dev.png" width="49%">
</p>
<p align="center">
  <img src="screenshots/media.png" width="60%">
</p>

---

## What's in it

**Desktop** — niri and Hyprland, both always available and swappable at the
greeter, with matching binds so muscle memory carries over. DMS handles the
bar, launcher, notifications and lock screen. Themed SDDM greeter and GRUB,
kitty + zsh with fastfetch.

**Dev** — VS Code, Android Studio and Zed, pre-configured. Seven language
toggles that install the toolchain *and* tell all three editors what to load
for it. [Free Claude Code](https://github.com/Alishahryar1/free-claude-code)
wires a free-tier model into your CLI and editors.

**Gaming** — Steam, Lutris, Heroic, GE-Proton, MangoHud. Color-matched too,
down to the Wine dialogs.

**Network** — Cloudflare DNS over TLS by default, network-stack hardening
sysctls, and a Tor transparent proxy behind a DMS control-center toggle that
routes the whole machine rather than just a browser.

**Everything else** — Zen Browser (chrome-scripted so its theme reloads
live), Nautilus and Thunar, Spicetify and Fastpotify, Bitwarden, Vesktop, an ASUS control
widget, Waydroid for Android apps (signature spoofing and microG included),
native AppImage support, and an isolated Distrobox escape hatch for the
Ubuntu-only tail.

Everything under `modules/apps/` is one boolean in `Host.nix`:

```nix
vayori.apps = {
  Vscode.enable = true;
  Gaming.enable = true;
  Rust.enable = false;
};
```

---

## Secrets

API keys live in `_user.nix` (gitignored), under
`vayori.users.<name>.secrets` — `<name>` is whichever key you picked for
yourself in `vayori.users` above it. `ash` is just this repo author's
username, not a reserved word:

```nix
vayori.users.<yourname>.secrets = {
  # VS Code, Android Studio, Zed - installs WakaTime, writes ~/.wakatime.cfg
  WAKATIME_API_KEY = "waka_...";

  # Bitwarden's rbw client, to pre-fill the email prompt
  RBW_EMAIL = "you@example.com";

  # Open-ended - each one becomes an env var for Free Claude Code.
  # Any provider it supports works here; these are the common ones.
  PROVIDERS = {
    NVIDIA_NIM_API_KEY = "nvapi-...";
    OPENROUTER_API_KEY = "sk-or-...";
    GROQ_API_KEY       = "gsk_...";
    GEMINI_API_KEY     = "...";
    DEEPSEEK_API_KEY   = "sk-...";
    MISTRAL_API_KEY    = "...";
    TOGETHER_API_KEY   = "...";
    CEREBRAS_API_KEY   = "csk-...";
    FIREWORKS_API_KEY  = "fw_...";
    HUGGINGFACE_API_KEY = "hf_...";
    COHERE_API_KEY     = "...";
    # Full list: github.com/Alishahryar1/free-claude-code#readme
  };
};
```

Leave a key out — or the whole block — and whatever needed it simply
doesn't get installed, rather than being configured with a key that would
only fail. Full shape in [docs/core-users.md](docs/core-users.md).

Browser profiles, editor logins and the rbw session live in one portable
folder, `~/.config/vayori/session`, with its own encrypted backup CLI:

```bash
vayori-app-state backup ~/vayori-session.enc
```

---

## Keybinds

Same on both compositors. `Mod` is Super.

| Key | | Key | |
| --- | --- | --- | --- |
| `Mod+Return` | terminal | `Mod+Q` / `Alt+F4` | close window |
| `Mod+E` | files | `Mod+W` | float |
| `Mod+C` | code | `Mod+F` / `Shift+F11` | fullscreen |
| `Mod+B` | browser | `Mod+←↑↓→` | focus |
| `Mod+A` | launcher | `Mod+Shift+←↑↓→` | move window |
| `Mod+V` | clipboard | `Mod+1`–`0` | workspace |
| `Mod+Comma` | settings | `Mod+Shift+1`–`0` | send to workspace |
| `Mod+L` | lock | `Mod+Shift+P` | color picker |
| `Mod+Shift+W` | wallpapers | `Print` / `Shift+Print` | screenshot |

Hyprland adds mouse-drag move/resize (`Mod`+left/right click), a scratchpad
on `Mod+S`, and silent workspace moves on `Mod+Alt+1`–`0`.

Full lists: [Niri.nix](modules/desktop/Niri.nix) ·
[Hyprland.nix](modules/desktop/Hyprland.nix)

---

## Layout

```text
flake.nix          inputs + import-tree ./modules
modules/
  core/               flake-parts wiring, the shared user/app framework
  hosts/<name>/       Host.nix + _hardware.nix + _user.nix
  desktop/            niri, Hyprland, DMS, fonts/portals, GTK/Qt, matugen
  system/             docker/podman, zram, GRUB theme
  apps/               opt-in per-user modules, toggled in Host.nix
    development/        editors, languages, dev-tools, Free Claude Code
    gaming/             launchers, proton, performance tweaks
    utils/              terminal, browser, everything else
  assets/wallpapers/  default wallpaper set
```

**Add a person**: an entry in `_user.nix`. **Add an app**: a folder under
`modules/apps/*/` setting `flake.homeModules.apps.<Name>` — picked up
automatically. **Add a host**: copy `modules/hosts/Diablo/`.

---

## Documentation

[**docs/CONFIGURATION.md**](docs/CONFIGURATION.md) is the index — one page
per module, in the order you'd meet them, each linking to the next so it
reads straight through. Start with
[Getting started](docs/getting-started.md).

The `.nix` files stay comment-free; all the "why" lives in those pages.

---

## Credits

| Project | For |
| --- | --- |
| [niri](https://github.com/YaLTeR/niri) · [Hyprland](https://hypr.land) | the compositors |
| [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) | bar, launcher, lock, theming |
| [matugen](https://github.com/InioX/matugen) | the color engine behind all of it |
| [home-manager](https://github.com/nix-community/home-manager) · [flake-parts](https://flake.parts/) · [import-tree](https://github.com/vic/import-tree) | the Nix plumbing |
| [Bibata](https://github.com/ful1e5/Bibata_Cursor) · [Catppuccin](https://github.com/catppuccin) | cursor/editor theme |
| [Free Claude Code](https://github.com/Alishahryar1/free-claude-code) · [WakaTime](https://wakatime.com/) | the dev-editor integrations |
| [Vencord](https://github.com/Vendicated/Vencord) · [DankAsusControl](https://github.com/shazzaam7/DankAsusControl) | Discord mods, ASUS widget |

Full pinned list: `flake.nix`.

## License

[MIT](LICENSE). Use it, fork it, take what you want.

## Known caveats

`dankAsusControlCenter` builds fine but hasn't met real ASUS hardware in
testing yet — see [docs/desktop-dms.md](docs/desktop-dms.md) if
`asusctl`/`supergfxctl` won't cooperate.
