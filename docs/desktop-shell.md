[Index](CONFIGURATION.md)

---

Which shell draws the bar, notifications and OSD - DMS, Noctalia or Caelestia - picked at build time, like an app.

## `modules/desktop/Shell.nix`, `noctalia/Noctalia.nix`, `caelestia/Caelestia.nix`

- **The shell is a build-time choice.** `vayume.desktop.shell` is `dms` (default), `noctalia` or `caelestia`. Set it in Vayume Settings (Appearance), or `vayume config settings set desktop.shell noctalia`, then `vayume rebuild`. Only the selected shell's module is evaluated, so the others' flake inputs are never fetched and their packages are never built. A dry-run of the DMS build lists no Noctalia, Caelestia or Quickshell derivations; the Caelestia build is the one that fetches its CLI and Quickshell.
- **Switching works from Vayume Settings or a terminal.** Vayume Settings is a standalone app ([desktop-settings.md](desktop-settings.md)) and runs under every shell, so the Shell setting is always reachable. `vayume config settings set desktop.shell dms` followed by a rebuild does the same from a terminal.
- **Native first, fallback second.** Every action goes to the selected shell's own feature when it has one. Only when a shell has no equivalent does it use Vayume's own tool, and that tool is installed only in that case: a shell that has everything installs none of rofi, cliphist, wlogout or swaylock. The four that can fall back are the launcher (rofi), clipboard (cliphist + rofi), power menu (wlogout) and lock (swaylock); the rest can only notify.
- **Keybinds name actions, not shells.** The binds call `vayume launcher`, `clipboard`, `powermenu`, `lock` and `vayume shell <bar|settings|wallpaper|wallpaper-next|wallpaper-prev|screenshot>`. Each shell's module fills `vayume.desktop.shellCommands` with what that action runs. A `null` or missing entry means no equivalent: the four above then run the fallback, the others show a "Not available on <shell>" notification instead of failing silently.
- **What each action runs.**

| Action | DMS | Noctalia | Caelestia |
|---|---|---|---|
| launcher | `dms ipc call spotlight toggle` | `noctalia msg panel-toggle launcher` | `caelestia shell drawers toggle launcher` |
| clipboard | `dms ipc call clipboard toggle` | `noctalia msg panel-toggle clipboard` | fallback: cliphist + rofi |
| powermenu | `dms ipc call fullscreenPowerMenu toggle` | `noctalia msg panel-toggle session` | `caelestia shell drawers toggle session` |
| lock | `dms ipc call lock lock` | `noctalia msg session lock` | `caelestia shell lock lock` |
| bar | `dms ipc call bar toggle index 0` | `noctalia msg bar-toggle` | none |
| settings | `dms ipc call settings toggle` | `noctalia msg settings-toggle` | `caelestia shell drawers toggle dashboard` (no real settings UI) |
| wallpaper | `dms ipc wallpaperCarousel open` | `noctalia msg panel-toggle wallpaper` | none |
| wallpaper-next / prev | `dms ipc call wallpaper next` / `prev` | `noctalia msg wallpaper-next` / `wallpaper-previous` | `caelestia wallpaper -r` / none |
| screenshot | `dms ipc call screenshotPlus capture` | `noctalia msg screenshot-region` | `caelestia shell picker open` |

- **`vayume widgets` follows the shell too.** DMS keeps its own script. On the other shells a generic one calls the shell's show/hide commands (Noctalia has them, Caelestia has no desktop widgets) and always starts or stops the desktop pet.
- **The idle lock and the media inhibitor don't belong to any shell.** They used to live in `Dms.nix`. The idle service is swayidle, and it locks with the same command as the keybind (the shell's own lock, or swaylock when the shell has none) both on idle and before suspend. `security.pam.services.swaylock` is only declared when swaylock is actually the lock, since without that PAM service it cannot verify a password. Noctalia and Caelestia also have idle handling of their own; this service does not turn it off.
- **DMS-only things stay DMS-only.** The vayume desktop widgets and the Tor, cava and Asus plugins are DMS plugins and are not built under the other shells. VS Code's matugen theme is DMS's, so the other shells get Catppuccin instead.
- **Caelestia targets Hyprland.** Its keybinds are Hyprland global shortcuts, so the build prints a warning, and on niri only the bar, drawers and IPC are expected to work.
- **Theming follows the wallpaper under every shell.** DMS runs the matugen templates itself (see [Theming.nix](desktop-theming.md)). Under Noctalia and Caelestia, `vayume theme [wallpaper]` runs `matugen image` for the wallpaper the shell reports, and both shells call it from their wallpaper-changed hook. `vayume-shell-init` runs at login: it points the shell at the repo's wallpaper folder, sets a default wallpaper if none is set, then themes from it. `vayume widgets` toggles the shell's own desktop widgets where it has them.

---

[← DesktopTools.nix](desktop-tools.md) · [Index](CONFIGURATION.md) · [Misc.nix →](system-misc.md)
