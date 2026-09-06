[Index](CONFIGURATION.md)

---

A second compositor, deliberately built to mirror the first - same binds, same feel, different tiling model, picked at the login screen instead of hardcoded.

## `modules/desktop/Hyprland.nix`

A second compositor, deliberately mirroring niri's own shape rather than
reinventing one - same gaps/borders/opacity/blur values, same keybind
set (terminal/files/code/browser/`dms ipc call` spawns, focus/move,
workspaces 1-10 with `0` mapped to workspace 10), so switching sessions
at the SDDM greeter changes the compositor, not the muscle memory. Both
`nixosModules.Hyprland` and `homeModules.Hyprland` exist, imported next
to their niri counterparts in `Host.nix`/`Users.nix` - both compositors
are always available, picked per-login, not toggled by a single option.

**DMS needed nothing new to run under it.** It starts as a systemd user
service bound to `graphical-session.target`
([Dms.nix](desktop-dms.md)'s `systemd.enable = true;`), which
either compositor's session provides - no `exec-once`/spawn-at-startup
line required, confirmed by checking there's no niri-specific assumption
in how DMS's own `programs.dank-material-shell` module starts it.

**Four places genuinely have no niri equivalent, not just an oversight**
- Hyprland is a dwindle tiler, niri is a scrollable-column WM, and some
concepts don't translate:
- No built-in overview (niri has one; Hyprland needs the `hyprexpo`
  plugin, not pulled in here) - `Mod+Tab` maps to `cyclenext` instead, a
  stand-in, not an equivalent.
- No column operations (`consume-window-into-column`,
  `expel-window-from-column`, preset column widths) - `Mod+J`/`Mod+R` map
  to `togglegroup`/`pseudo`, the nearest dwindle concepts, not real
  matches.
- No built-in screenshotting - niri has `.screenshot`/`.screenshot-screen`
  actions; Hyprland gets `grim`/`slurp` instead (already in
  `environment.systemPackages` via [Host.nix](core-host.md)),
  with `Mod+Shift+S` doing the region-select variant.
- Resize is `resizeactive` in pixels rather than niri's
  `set-column-width` proportions - dwindle has no column-proportion
  concept to resize against.

**The brightness binds needed the same device-resolution logic niri's
own already has, not a bare `dms ipc call brightness increment 5`.**
Checked DMS's own default keybind list
(`Common/KeybindActions.js`) rather than assume the device argument was
optional - its own defaults always pass a third argument, even if empty
(`brightness increment 5 ""`). Matched niri's existing, more robust
approach instead of DMS's bare default: resolve the actual backlight
device name via `dms ipc call brightness list | awk '$1 ~
/^backlight:/ {print $1; exit}'`, same shell substitution as
[Niri.nix](desktop-niri.md)'s own binds, verified against the
real rendered `hyprland.conf` line for line.

Verified against a real build, not just eval: the generated
`hyprland.conf` has 70 `bind*` lines including all 20 workspace binds
(`0` correctly mapping to workspace `10`), and both `niri-26.04` and
`hyprland-0.56.1` show up in `services.displayManager.sessionPackages` -
SDDM will actually offer both.

**`windowrulev2` doesn't work on this pinned Hyprland version - real,
live feedback, not caught by any of the build-time verification above.**
`nixpkgs.hyprland` here is `0.56.1`, and this build/eval-only session has
no way to launch a real compositor session - only Hyprland's own
`--verify-config` (which parses the config for real, but was only run
once, before this bug, not re-run against every later change) would ever
have caught this. `class:REGEX`-style selectors were replaced with a
`match:` prefix - confirmed straight from Hyprland's own source
(`src/config/legacy/ConfigManager.cpp`: a selector token has to
`start_with("match:")`, colon immediately joined to the field name with
no space, then a space before the value - `class:.*` is genuinely
invalid now, not just deprecated-but-working). Fixed to `match:class
.*`, then actually re-verified against the real
`Hyprland --config ... --verify-config` binary this time (not just
`nix build`) - `config ok`, zero parse errors, on the exact config this
repo generates.

---

[← Niri.nix](desktop-niri.md) · [Index](CONFIGURATION.md) · [Fonts.nix / Portals.nix →](desktop-portals-fonts.md)
