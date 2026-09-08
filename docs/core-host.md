[Index](CONFIGURATION.md)

---

Every machine starts here. `Host.nix` is the one file that says what this particular computer is - its name, its apps, its bootloader - and everything else in this repo exists to serve what gets decided in it.

## `modules/hosts/<name>/Host.nix`

**`vayori.theme`** is a submodule declared right here, not in a shared
file like `vayori.users`/`vayori.apps` - it's a per-host preference, and
there's only one host so far. Comes with sane defaults (JetBrainsMono
Nerd Font, Bibata-Modern-Ice, Tela-circle). Change one field without
touching the rest - `vayori.theme.font = "Fira Code";` and it updates
everywhere at once, since fontconfig, GTK, kitty, and DMS all read the
same option.

NixOS modules can read `config.vayori.theme.*` directly. Home-manager
modules can't - they run as a totally separate module tree that never
sees the parent config - so `Users.nix` hands it over explicitly via
`extraSpecialArgs`.

Not wired to `vayori.theme`, if you're wondering: the SDDM greeter's
bundled font and GRUB's own theme package. See
[Fonts.nix / Portals.nix](desktop-portals-fonts.md).

**Two Nix landmines hit while building this file, worth knowing about:**

1. A module can't mix `options.x = ...` with plain top-level config keys.
   Declare `options.vayori.theme` and suddenly everything else has to
   move under `config = { ... };`, or you get a cryptic `unsupported
   attribute 'boot'` error that gives you no hint why.
2. An inline lambda right after a path in a list doesn't parse the way
   you'd expect - it reads as a function call, not a second list item:

   ```nix
   modules = [
     ./_hardware.nix
     { pkgs, ... }: { ... }   # BROKEN — parses as `./_hardware.nix { pkgs, ... }`
   ];
   ```

   Wrap it in parens and it's fine: `({ pkgs, ... }: { ... })`.

**Store/build housekeeping**: `auto-optimise-store` hardlinks identical
files across store paths so they don't get stored twice.
`documentation.nixos.enable = false` skips building the local NixOS
manual (`man configuration.nix` still works fine, this just skips the
book). Garbage collection runs weekly, clearing anything older than 30
days, so `/nix/store` doesn't just grow forever waiting for someone to
remember `nix-collect-garbage`.

**Getting the login screen's cursor right took three separate fixes**,
none of them guesses - all traced through the actual source:

1. SDDM's Wayland greeter runs as its own systemd service under Weston,
   which never sees `environment.sessionVariables` - those only apply
   post-login, via PAM. Fix: set the same variables directly on the
   `display-manager.service` unit.
2. Even with that, Weston doesn't guarantee the greeter *client* actually
   inherits them. SDDM's own source re-applies a separate
   `GreeterEnvironment` setting on top - a comma-separated string, not
   the usual attrset shape, easy to get wrong the first time.
3. NixOS isn't FHS, so there's no `/usr/share/icons` for Xcursor to fall
   back to - `XCURSOR_PATH` has to be pointed at the actual package
   explicitly, and that package needs to be system-wide since SDDM runs
   before any user session exists to pull it in otherwise.

Small caveat: QEMU's screenshot tool doesn't reliably capture the
hardware cursor, so a screenshot with no visible cursor isn't proof
anything's actually broken - which is exactly why the next bullet was
hard to be sure about without a real machine.

**...and it still wasn't enough.** On real hardware the greeter really
did have no cursor. Traced through weston's own C source
(`frontend/main.c`, `kiosk-shell/kiosk-shell.c`) before touching
anything: Wayland cursor rendering is 100% client-side (a
`wl_pointer.set_cursor` call) - the compositor never draws a fallback
cursor of its own. Weston's `[shell] cursor-theme`/`cursor-size` config
keys only apply to its *nested* "wayland backend" (weston-inside-a-
compositor, for testing); the real DRM-backend path SDDM actually uses
has no cursor-theme option of any kind, and `kiosk-shell.c` - the shell
plugin SDDM selects - has zero cursor-handling code at all. So the whole
chain came down to whether the greeter's own Qt/QML process reliably
resolves `XCURSOR_THEME`/`XCURSOR_SIZE` into an actual `set_cursor` call
over Wayland specifically - the three fixes above get the env vars to
the process, but that resolution step turned out not to be reliable
enough to depend on.

Fix: stop depending on it. [`Theme/Main.qml`](../modules/desktop/sddm/Theme/Main.qml) now
draws its own cursor - a `HoverHandler` on the root item tracks the
pointer position (observe-only, doesn't grab clicks, so it can't break
the password field or the session/reboot/power buttons underneath it),
and a `Canvas` paints a simple arrow at that position every frame. Every
`MouseArea` in the file that used to request a native `cursorShape`
(`Qt.ArrowCursor`/`Qt.PointingHandCursor`) now requests `Qt.BlankCursor`
instead, so there's nothing left trying to use the uncertain
resolve-and-set_cursor path at all - the custom-drawn one is the only
cursor, everywhere, unconditionally. This renders exactly like the rest
of the greeter's own visible UI, so it doesn't depend on Xcursor
resolution, Wayland's cursor-surface protocol, or a hardware cursor
plane existing at all.

**Still `vayori.theme`-driven, not hardcoded**: the arrow's *size* comes
from `config.vayori.theme.cursorSize`, threaded through via a
`cursorSize=` key [`SddmTheme.nix`](../modules/desktop/sddm/SddmTheme.nix) now writes into
`theme.conf` (SDDM's own QML API exposes every `[General]` key as
`config.<key>` - the same mechanism the theme could already use for
`background`/`font`/`themeMode`, just not exercised for anything
Nix-driven until now). The shape itself is a plain drawn arrow, not a
pixel-accurate reproduction of Bibata-Modern-Ice - the cursor package
only ships compiled Xcursor binaries, no plain image assets, so
matching it exactly would mean decoding that binary format at build
time. Given the actual goal (a visible, theme-sized cursor that works
regardless of the Wayland-cursor-protocol uncertainty above), that
trade felt like the wrong place to spend more risk.

**`GSETTINGS_SCHEMA_DIR`, found by actually booting the VM.** `programs.dconf.enable = true;` only installs the `dconf` binary - it
never installs `gsettings-desktop-schemas`, the package that actually
owns `org.gnome.desktop.interface` and every other GNOME-namespaced
schema. Without it, `gsettings get/set` against those keys fails
outright, silently if the caller doesn't check (DMS's own portal-based
dark/light sync, and this repo's own GTK matugen reload hook in
[Baseline.nix](desktop-baseline.md), both call
`gsettings` this way). A plain `nix flake check`/`nix build` never
catches this - schema lookup is a pure runtime thing, invisible to
evaluation. Only booting the real VM and running `gsettings get` by hand
surfaced it (`"No schemas installed"`).

The fix isn't just adding the package to `environment.systemPackages` -
modern nixpkgs ships schema files under a namespaced
`share/gsettings-schemas/<pname>/glib-2.0/schemas`, not the classic
`share/glib-2.0/schemas` NixOS's own profile builder auto-compiles into
`/run/current-system/sw`, so simply installing the package changes
nothing a plain shell can see. Confirmed empty-handed - genuinely no
`gschemas.compiled` anywhere in the filesystem - before adding this.
The real GNOME/Budgie/Pantheon desktop-manager modules
(`nixos/modules/services/desktop-managers/gnome.nix` et al.) point
straight at that namespaced path via `XDG_DATA_DIRS`, additive across
however many schema-providing packages a full desktop environment pulls
in. This repo only needs the one package, so `GSETTINGS_SCHEMA_DIR` -
narrower, but exactly enough for `gsettings-desktop-schemas` alone -
gets pointed at it directly via `environment.sessionVariables` instead.
Verified live: `gsettings get org.gnome.desktop.interface gtk-theme`
failed before this, returned the real `adw-gtk3` value after.

**Apps** (`vayori.apps`) is the one setting most new machines actually
need to touch - one real, individually-named boolean option per module
under `modules/apps/`, e.g. `vayori.apps.Vscode.enable = true;`. Each
name comes straight from `builtins.attrNames self.homeModules.apps`
([core/Users.nix](core-users.md)), so it's discoverable by typing
`vayori.apps.` in an editor with Nix LSP support instead of needing to
already know the exact string a plain `listOf` would've required - and a
typo'd app name is a real evaluation error (unknown option) rather than
a silently-ignored list entry. `false` entries are written explicitly
rather than deleted, so it's visible at a glance which apps exist on
this machine but are off, not just missing. Internally,
`config.vayori.apps` is filtered down to the flat list of enabled names
(`enabledAppNames`) before anything downstream - the home-manager
imports, `vayoriApps` passed to app modules, `PluginUpdateCheck.nix`'s
pin filtering - ever sees it; those consumers are unaware the option
itself changed shape.

**`programs.steam.enable`** lives here, not in
[Gaming.nix](apps-gaming.md) - see that page
for why.

**Users** (`vayori.users`) - **not set here any more.** It used to be a
plain block in this file, but that meant real usernames, group
memberships, and a password hash sat in git history the moment the repo
went public. It's set from `_user.nix` instead now - a gitignored sibling
of `_hardware.nix`, never committed, required (the build refuses to
evaluate without it). Full story in [core/Users.nix](core-users.md)
below.

---

[← Getting started](getting-started.md) · [Index](CONFIGURATION.md) · [_hardware.nix →](core-hardware.md)
