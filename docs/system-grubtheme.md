[Index](CONFIGURATION.md)

---

The first thing this machine shows you, before Linux itself has even loaded.

## `modules/system/GrubTheme.nix`

`elegant-grub2-themes` ([vinceliuice/Elegant-grub2-themes](https://github.com/vinceliuice/Elegant-grub2-themes))
is the one flake input here that does its own homework - it ships a real
NixOS module (`nixosModules.default`, `boot.loader.elegant-grub2-theme.*`),
so this file is just an `imports` line plus a handful of options. No
hand-rolled packaging like the old theme needed.

- **`theme = "wave"`** is the exact design from
  [gnome-look.org/p/2206122](https://www.gnome-look.org/p/2206122)
  ("Elegant-wave-grub-themes") - that listing turns out to just be a
  re-upload of this same repo. Confirmed by cloning it directly, since
  gnome-look.org blocks bots behind an "are you human" wall and wouldn't
  load. `type`/`side`/`color`/`screen` are the other knobs (window/float/
  sharp/blur, left/right, dark/light, 1080p/2k/4k) if you want to tweak
  the look.
- **The theme gets built, not downloaded pre-made.** Upstream's module
  runs its own `generate.sh` against the source art with whatever options
  are set, using imagemagick, and points GRUB at the result. Checked this
  by actually building the system and pulling the real theme folder out
  of the store - background image, fonts, icons, all there.
- **The flake input uses `git+https://` instead of the usual `github:`
  shorthand.** GitHub's API was rate-limiting this repo mid-setup (`403`,
  cheers), and `git+https://` talks to git directly instead of going
  through that API, so it just works regardless. Had to override
  upstream's own nested source input the same way for the same reason.
- **`gfxmodeBios` is force-set to match `screen = "1080p"` explicitly**,
  duplicating a value the theme module already derives internally - not
  cosmetic. `screen` sets `boot.loader.grub.gfxmodeBios` to
  `1920x1080,auto` under the hood, but `virtualisation.vmVariant` (the
  machinery behind `nixos-rebuild build-vm` and
  [Vm.nix](core-vm.md)) sets its own plain `1024x768`
  default for the *same* option - two plain-priority definitions,
  genuinely conflicting, and `config.system.build.vm` flat out failed to
  evaluate because of it. Not a hypothetical: hit this for real trying
  to build a VM to verify a different fix, confirmed it had nothing to
  do with that fix, and confirmed the `mkForce` here resolves it cleanly
  via the real option's resolved value. Harmless inside a VM too - QEMU's
  virtual display has no trouble with 1920x1080.

---

[← Zram.nix](system-zram.md) · [Index](CONFIGURATION.md) · [AndroidStudio.nix →](apps-dev-androidstudio.md)
