[Index](CONFIGURATION.md)

---

Three small, unrelated system-level toggles, kept in one file because none of them is big enough to earn its own - swap, dev-tooling daemons, and the boot theme.

## `modules/system/Misc.nix`

### Zram

The shortest thing in this file, and proof that not everything needs an
essay: `zramSwap.enable = true;`, and the upstream module's own defaults
(50% of RAM, `zstd`, priority `5`) already do the right thing, confirmed
by actually reading that module's source rather than assuming: `zstd` is
both fast and well-compressed, and priority `5` beats a plain disk swap
entry's default, so the RAM-backed swap gets used first and
[Diablo's real disk swap partition](core-hardware.md) only picks up
genuine overflow. Not hardware-specific, so it isn't in `_hardware.nix` -
any host with enough RAM benefits the same way, and a second host
defined later gets it for free instead of needing this copied in.

### DevTooling

Docker and Podman, side by side - infrastructure that doesn't care what
desktop you're running, which is exactly why it's not in `desktop/`.
Named for what it is: system-level stuff for dev workflows, not tied to
any one app - it used to be called `dev-system.nix`, which read way too
much like [apps/development/devTools/DevTools.nix](apps-dev-devtools.md)
(a completely different, per-user file: VS Code/git/gh/lazygit/
docker-compose), so it got a better name.

`virtualisation.docker.enable`/`libvirtd.enable` are the actual daemons
that `docker-compose` and any VM tooling need running. `programs.adb.enable`
got dropped since systemd 258+ handles the adb udev rules on its own now,
and `pkgs.android-tools` (already pulled in by
[AndroidStudio.nix](apps-dev-androidstudio.md)) covers the actual `adb`
command. `users.groups.adbusers` sticks around purely so it's a valid
group to put in `extraGroups` - it doesn't grant anything on its own
anymore, it's basically a fossil.

### GrubTheme

The first thing this machine shows you, before Linux itself has even
loaded. `elegant-grub2-themes`
([vinceliuice/Elegant-grub2-themes](https://github.com/vinceliuice/Elegant-grub2-themes))
is the one flake input here that does its own homework - it ships a real
NixOS module (`nixosModules.default`, `boot.loader.elegant-grub2-theme.*`),
so this is just an `imports` line plus a handful of options. No
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
  [Vm.nix](core-vm.md)) sets its own plain `1024x768` default for the
  *same* option - two plain-priority definitions, genuinely conflicting,
  and `config.system.build.vm` flat out failed to evaluate because of
  it. Not a hypothetical: hit this for real trying to build a VM to
  verify a different fix, confirmed it had nothing to do with that fix,
  and confirmed the `mkForce` here resolves it cleanly via the real
  option's resolved value. Harmless inside a VM too - QEMU's virtual
  display has no trouble with 1920x1080.

---

[← SddmTheme.nix](desktop-sddm.md) · [Index](CONFIGURATION.md) · [Network.nix →](system-network.md)
