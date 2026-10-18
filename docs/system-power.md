[Index](CONFIGURATION.md)

---

`modules/system/Power.nix` holds the options (`vayume.power.*`: idle lock, screen off, suspend, power button, lid, and the ultra power saver); `modules/system/PowerProfile.nix` is the `vayume power` command and the live hooks. Everything is on the Power page of [Vayume Settings](desktop-settings.md).

## Power profile, battery, graphics

`vayume power status` prints JSON for the page and `vayume power profile|battery-limit|gpu|overdrive|auto-brightness <value>` changes one thing. The backend is picked at run time: asusd (`asusctl`) when it answers, otherwise `power-profiles-daemon` (`powerprofilesctl`), otherwise the profile card says so. `supergfxctl` provides the graphics mode, and `asusctl armoury` the panel overdrive and auto brightness - controls the hardware doesn't expose (this laptop's asusd has no armoury interface) are hidden, not greyed out.

These values live in the hardware services, which keep them across reboots and rebuilds, so they are not Nix options. They replace the profile picker, charge limit and GPU buttons of the DMS ASUS plugin as the place to configure them, and work under every shell.

## Ultra power saver

`vayume.power.ultraSaver` (off by default) strips everything decorative so the apps get the machine. It saves resources, not performance, so the power profile is never changed (pick that yourself above):

| What | How |
| --- | --- |
| Hyprland | animations, blur, shadows off, rounding 0, window opacity 1. Written to `~/.config/hypr/vayume-saver.lua`, which the generated `hyprland.lua` loads last, then `hyprctl reload`; an `hyprctl eval` alone was wiped by the next reload, and DMS triggers one every time it regenerates its layout file |
| DMS | animation speed none, ripples, blur (bar, wallpaper, overview), elevation shadows, notification shadows and popup/dock transparency off; the audio visualizer (the `cava` processes), weather, the clock's seconds and the lock screen video off; every desktop widget disabled |
| Matugen | DMS's own switch: the `dms` unit runs with `DMS_DISABLE_MATUGEN=1`, which makes the shell skip matugen entirely (the colours stay as they were), plus `DMS_DISABLE_CAVA` (audio visualizer), `DMS_DISABLE_LAYER` (layer effects on popouts) and `DMS_DISABLE_HOT_RELOAD`. The settings flags `runUserMatugenTemplates` and `runDmsMatugenTemplates` alone only skip the per-app templates - DMS still ran `dms matugen queue` to colour itself, which is why the first version of the saver did not stop it. `vayume theme` (what Noctalia and Caelestia call on a wallpaper change) exits without doing anything unless `VAYUME_THEME_FORCE=1` |
| Desktop pet | stopped |
| Shell priority | `dms`, `noctalia` and `caelestia` services at CPUWeight and IOWeight 20 instead of 100 |

Those environment variables are only read when DMS starts, so turning the saver on or off restarts `dms.service` once (the shell disappears for a second); the unit gets them from `systemctl --user set-environment` live and from `Environment=` after a rebuild. Turned on from Vayume Settings it is applied at once ([live settings](core-settings.md#live-settings)): `vayume power saver on` runs the steps above in the running session, creating `~/.local/state/vayume/saver-active` (the marker `vayume theme` checks; a rebuild syncs it to the option), writing the DMS `settings.json` it finds (the file DMS watches) and recording what it overwrote under `~/.local/state/vayume/` so turning it off puts everything back, including keys that did not exist. The same option is read by `Hyprland.nix`, `Dms.nix` (settings and the unit's CPU/IO weight) and `Pet.nix` (no service), so after a rebuild the generated files already hold the saver state and the session is identical to the live one.

Not covered, by design of what can be reached from outside: niri's compositor effects (its configuration is built as a package without access to the system options, so there is nothing to bake - niri has no IPC for animations either), and Noctalia's and Caelestia's own effects. Under those only the profile, the pet, the shell priority and (on Hyprland) the compositor part apply.

## Other live setting

`desktop.pet.enable` starts and stops `vayume-pet.service` immediately (`vayume power pet on|off`). The unit exists only when the pet was enabled at the last rebuild, so switching it on for the first time reports "rebuild to apply" and the line is saved for the rebuild. While the ultra saver is on, the pet stays off.

---

[← Network.nix](system-network.md) · [Index](CONFIGURATION.md)
