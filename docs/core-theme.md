[Index](CONFIGURATION.md)

---

One option, read everywhere - the shared schema behind `vayume.theme`, so a single font/cursor/icon choice reaches fontconfig, GTK, kitty, DMS, and SDDM without saying it more than once.

## `modules/vayume/Theme.nix`

`options.vayume.theme` lives here as `flake.nixosModules.Theme`, the same
shared-module pattern as `vayume.users`/`vayume.apps` - a host imports
`self.nixosModules.Theme` in its `Host.nix` `modules` list, then sets
whichever fields it wants under its own `config.vayume.theme`. Ships
with sane defaults (JetBrainsMono Nerd Font, Bibata-Modern-Ice, Adwaita),
so a host only needs to override the fields it actually cares about.

Used to live declared directly inside `Host.nix` itself, back when there
was only one host - moved out once "one place to set theme" stopped
matching "one file that also does everything else a host does." Nothing
about the option itself changed; `config.vayume.theme.*` resolves
exactly the same either way, since the module system merges options by
attribute path, not by which file declared them.

NixOS modules can read `config.vayume.theme.*` directly. Home-manager
modules can't - they run as a totally separate module tree that never
sees the parent config - so [Users.nix](core-users.md) hands it over
explicitly via `extraSpecialArgs`.

Not wired to `vayume.theme`, if you're wondering: the SDDM greeter's
bundled font and GRUB's own theme package. See
[Fonts.nix / Portals.nix](desktop-portals-fonts.md).

---

[← Users.nix](core-users.md) · [Index](CONFIGURATION.md) · [VayumeConfig.nix →](core-vayume-config.md)
