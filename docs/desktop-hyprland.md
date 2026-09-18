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

**The actual app launch commands (terminal, file manager, editor,
browser, its reload script, the system monitor, the color picker) live
in one place**, [`modules/lib/VayumeLib.nix`](../modules/lib/VayumeLib.nix)'s
`flake.vayumeLib.desktopActions` - both this file and
[Niri.nix](desktop-niri.md) read the same attrset instead of each
hardcoding its own copy of `"kitty"`/`"thunar"`/etc. Niri's `spawn`
takes the argv list directly; Hyprland's own `spawn` helper wants one
shell string, so this file joins each list with spaces once, in the
`let` block, rather than at every call site. Genuinely shared *data*,
not a shared binding syntax - each compositor still declares its own
binds its own way.

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

**`vayume-type-clipboard` takes two positional overrides**: the first
argument is the per-keystroke delay in ms passed to `ydotool type
--key-delay`; the second is a grace period (seconds) before typing
starts, to give you time to refocus/click into the target field first.

**Screenshot binds are split three ways, not all hyprshot.** Plain
`Print` goes through the `screenshotPlus` plugin instead of hyprshot -
region capture with live annotation (draw while selecting) beats a bare
clipboard grab. `Shift+Print` (whole output) and `Mod+Print` (active
window) stay on hyprshot, since screenshotPlus only does interactive
region selection - it has no equivalent for "the whole screen" or "the
focused window" in one key. The redundant region-only hyprshot binds
(bare `Print`'s old hyprshot call, plus a duplicate `Mod+Shift+S`) were
dropped once screenshotPlus took over that job.

**Zen's Picture-in-Picture popup floats and pins (stays visible across
workspace switches)** - `hl.window_rule` is Hyprland's native Lua
window-rule API, a *completely different* shape from the classic
`windowrulev2 = "action,cond1,cond2"` string syntax: it's
`hl.window_rule({ match = { class = ..., title = ... }, <action
fields>... })`, one table argument, not a repeated string keyword -
confirmed the hard way, `hl.windowrulev2(...)` (a natural first guess,
modeled on how `bind` renders) doesn't exist and fails
`--verify-config` with "attempt to call a nil value." `match.class`/
`match.title` take the same regex Hyprland's classic string syntax
does, not Lua patterns - traced directly through Hyprland's own bundled
`hyprland.lua` reference config and its `hl.meta.lua` type stub, not
guessed. Matched the same way as niri's equivalent rule (`class =
"^zen$"`, Zen's real `StartupWMClass`; `title = "^Picture-in-Picture$"`,
every Firefox-family browser's fixed PiP window title). Verified
against the real pinned Hyprland binary's `--verify-config` before
deploying, same as the `match:class` fix below.

**Spotify (well, `fastpotify`) started prompting "the login keyring did
not get unlocked" out of nowhere, hours into a session that unlocked it
fine at login.** Traced through the actual journal, not guessed: at the
real login (`sddm-helper[...]: gkr-pam: gnome-keyring-daemon started
properly and unlocked keyring`), everything works. The failing prompt
came from a *second*, later gnome-keyring-daemon - dbus-activated
on-demand when the app touched the Secret Service - logging `Couldn't
get object path: ... No session '2' known` right before the prompt.
`loginctl list-sessions` at the time showed the real active session was
`5`, not `2` - the freshly dbus-activated daemon was working off a
stale `XDG_SESSION_ID` that no longer matched any real session.

Root cause: home-manager's `wayland.windowManager.hyprland` only
refreshes a *fixed, upstream-curated* set of variables in the systemd/
D-Bus activation environment on every Hyprland (re)start - `DISPLAY`,
`HYPRLAND_INSTANCE_SIGNATURE`, `WAYLAND_DISPLAY`, `XDG_CURRENT_DESKTOP`,
`XDG_SESSION_TYPE` (confirmed straight from home-manager's own
`hyprland/default.nix` and `lib.nix`, not assumed) - `XDG_SESSION_ID`
isn't in that list. The systemd *user manager* itself persists across
multiple real login/logout cycles (its own session shows up in
`loginctl list-sessions` as a separate, longer-lived `manager`-class
entry, distinct from each login's own session), so `XDG_SESSION_ID`
stays pinned at whatever it was the *first* time this activation
environment got populated, silently going stale on every subsequent
login that reuses the same persistent user manager - and any
D-Bus-activated service spawned later (gnome-keyring-daemon among
them) inherits that stale value. Fixed with
`wayland.windowManager.hyprland.systemd.variables = [ "--all" ];` - a
real, documented mode of `dbus-update-activation-environment --systemd`
(the option's own upstream example shows exactly this), importing the
whole environment instead of a fixed name list, closing this entire
class of "forgot to list a var" bug rather than just patching this one
instance of it. niri doesn't need the equivalent: it has no manual
`dbus-update-activation-environment` step in this repo at all, relying
on systemd's own PAM-driven environment inheritance instead, which
picks up `XDG_SESSION_ID` correctly from the start.

**DMS's own bar, dock, popouts, and every other panel it draws never
got blurred at all** - `decoration.blur` only affects real application
windows in Hyprland; DMS's own surfaces (bar, dock, launcher, control
center, notifications, tooltips, everything) are layer-shell surfaces,
a completely separate blur path that needs an explicit `layerrule`.
Confirmed the exact namespace every one of them registers under by
grepping DMS's own QML source for `WlrLayershell.namespace` - all of
them are prefixed `dms:` (`dms:bar`, `dms:dock`,
`dms:control-center-widget-library`, `dms:notification-popup`, and
~25 more). One regex-matched `layer_rule` (`match.namespace =
"^dms:.*$"`) covers all of them at once, present and future, rather
than hand-listing each - the same reasoning as niri's own
`app-id = ".*"` window-rule. `xray = true` on both the window and
layer rules stops blur from stacking through overlapping transparent
surfaces (DMS bar over a transparent terminal over the wallpaper, each
compounding its own blur pass into a muddy result) - it blurs against
the desktop directly instead. `blur_popups`/`decoration.blur.popups`
extend the same treatment to native window popups and DMS's own popup
windows. Verified against the real pinned Hyprland binary's
`--verify-config`, same as every other Lua config change in this file.

**DMS's own bar/popouts still show flat black, not blur, no matter
what's changed here - left unresolved, and out of scope for this repo
to fix alone.** Confirmed directly with screenshots (`grim`), not
guessed: at every blur strength tried, and even with global window
opacity pushed low enough to visibly blur real *application* windows,
DMS's bar and its Control Center popout both stayed solid black.
DMS's own compositor-capability probe (`dms blur check`, exactly what
[Dms.nix](desktop-dms.md)'s `BlurService.qml` runs at startup) reports
`supported` - checked both manually and in the running `dms.service`'s
own log - so this isn't a missing protocol advertisement. DMS's
*other* blur mechanism (the self-contained GPU-shader wallpaper blur,
unrelated to this protocol) works fine on Hyprland, confirmed via its
own "froze blur layer" log line. The specific gap is between DMS
successfully binding `ext-background-effect-v1` and Hyprland actually
rendering anything through it for layer-shell surfaces - looks like a
real Hyprland-side implementation gap, not a config problem; nothing
in `decoration.blur`/`layer_rule` moves it either way.

**Regular application windows (terminal, browser, editor) are the
actual thing that blurs well here - `decoration.active_opacity`/
`inactive_opacity` is the wrong tool for that, confirmed by literally
watching it happen.** Screenshotted the same window at `opacity = 1.0`
vs `0.80`: blur appeared, but so did the *entire* window fading,
including its own rendered text - Hyprland's opacity is a single
whole-surface multiplier with no concept of "background" vs "content"
within a client's own buffer, so there's no way to dial it down enough
for a visible blur without also dimming everything the app draws.
Confirmed `window_rule`/`layer_rule` have no per-rule opacity/alpha
field that could target just one surface either (checked the real
`HL.WindowRuleSpec`/`HL.LayerRuleSpec` Lua type stubs, then verified
directly against the live binary with `hyprctl eval` - `window_rule`
secretly accepts `opacity` despite the stub omitting it, `layer_rule`
rejects both `opacity` and `alpha` outright). The actual fix belongs to
the app, not the compositor: kitty's own `background_opacity`
([Terminal.nix](apps-utils-terminal.md)) makes *only* its background
translucent while keeping its own rendered text at full opacity -
Hyprland's blur then fills in behind that transparent portion via the
ordinary `decoration.blur` path, already configured here. Verified
live with real screenshots: a transparent, genuinely blurred background
(soft color bleeding through from whatever's behind it, not a flat
tint) with crisp, fully legible terminal text on top. `active_opacity`/
`inactive_opacity` stayed at their original, mild values - not the
lever for this at all.

**Blurred surfaces (Zen's settings page most visibly, since it's a
plain, mostly-neutral UI) picked up a green tint.** `decoration.blur.
contrast` was at `2` - the literal maximum of Hyprland's valid `0-2`
range, pushed there while chasing a stronger blur. A known Hyprland
artifact, not unique to this setup: contrast at the extreme end clips
color channels in the blur shader, especially visible as a green/
magenta cast over neutral or dark content (which is exactly why plain
UI chrome showed it far more obviously than a colorful wallpaper
would) and especially on Intel iGPUs like this machine's. Dropped to
`1.0`, Hyprland's own default - confirmed live with a screenshot: the
same blur strength, clean neutral colors, no cast.

---

[← Niri.nix](desktop-niri.md) · [Index](CONFIGURATION.md) · [Fonts.nix / Portals.nix →](desktop-portals-fonts.md)
