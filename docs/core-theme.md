[Index](CONFIGURATION.md)

---

One option, read everywhere - the shared schema behind `vayume.theme`, so a single font/cursor/icon choice reaches fontconfig, GTK, kitty, DMS, and SDDM without saying it more than once.

## `modules/vayume/Theme.nix`

`options.vayume.theme` lives here as `flake.nixosModules.Theme`, the same
shared-module pattern as `vayume.users`/`vayume.apps` - a host imports
`self.nixosModules.Theme` in its `Host.nix` `modules` list, then sets
whichever fields it wants under its own `config.vayume.theme`. Ships
with sane defaults (JetBrains Mono NL, Bibata-Modern-Ice, Adwaita), so a
host only needs to override the fields it actually cares about - from
`_config.nix` like everything else user-facing.

| Field | Default | Read by |
| --- | --- | --- |
| `font` | `"JetBrains Mono NL"` | fontconfig, GTK, kitty, DMS, VS Code, Zed, Android Studio, Zen, Vesktop, Spicetify, Wine |
| `fontPackage` | `pkgs.jetbrains-mono` | Fonts.nix (installs it), Spicetify, `vayume config`'s font list |
| `fontSize` | `11` | GTK, kitty |
| `cursorTheme` | `"Bibata-Modern-Ice"` | GTK, `XCURSOR_THEME`, SDDM, the VM greeter |
| `cursorPackage` | `pkgs.bibata-cursors` | GTK, system packages, `XCURSOR_PATH`, `vayume config`'s cursor list |
| `cursorSize` | `24` | GTK, `XCURSOR_SIZE`, SDDM |
| `iconTheme` | `"Adwaita"` | GTK, qt5ct/qt6ct |
| `iconPackage` | `pkgs.adwaita-icon-theme` | GTK |

Each `*Theme`/`font` name has to be something its matching `*Package`
actually ships - change the package and the name together. Nothing
checks this at evaluation time (it would mean reading inside the
package), which is why Vayume Settings' font and cursor pickers only
ever offer names read out of the current package.

```nix
vayume.theme = {
  font = "Fira Code";
  fontPackage = pkgs.fira-code;   # needs `{ pkgs, ... }:` at the top of _config.nix
  fontSize = 12;
};
```

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

[← Users.nix](core-users.md) · [Index](CONFIGURATION.md) · [Config.nix →](core-vayume-config.md)
