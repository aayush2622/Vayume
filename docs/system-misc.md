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

[Performance.nix](system-performance.md) later raised the priority to
`100` and added the swap-related sysctls (`vm.swappiness = 180` and
friends) that go with zram; the algorithm and size are unchanged.

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

`modules/system/GrubTheme.nix` builds its own GRUB theme
(`_grubTheme.nix`) instead of pulling one in, so the boot menu matches the
login and lock screens: a centred Material 3 surface card over a blurred
copy of `blue-girl-among-flowers.jpg`, the Vayume title and a 夜 mark, menu
entries in Roboto with the selected one on a rounded tonal pill, and the
countdown and key hints at the bottom. It replaced the
`vinceliuice/Elegant-grub2-themes` flake input, which is gone from
`flake.nix` and `flake.lock`.

- **Everything is rendered at build time.** GRUB can't blur, round
  corners or draw CJK text, so ImageMagick bakes the blurred wallpaper,
  the card and the 夜 into `background.png`, and draws the selection pill
  and scrollbar as GRUB's nine-slice pixmaps (`select_*.png`, `item_*.png`,
  `scrollframe_*.png`, `scrollthumb_*.png`). Slices are written as
  `PNG32`: ImageMagick otherwise saves fully transparent corners as
  palette PNGs, which GRUB draws as black squares.
- **Fonts are converted with `grub-mkfont`** from `pkgs.roboto` at the
  sizes the layout uses. GRUB matches `font = "..."` against the name
  stored inside each `.pf2`, so the build reads those names back out of
  the files and substitutes them into `theme.txt` rather than guessing
  them; the medium weight gets its own family name (`-n "Roboto Medium"`)
  because grub-mkfont names every weight "Regular". The build fails if a
  placeholder is left unresolved.
- **Unselected entries use a transparent pixmap the same size as the
  selected one**, so entries don't shift when the selection moves (GRUB
  only pads an item by its pixmap's borders).
- **There is no countdown bar**, only the "Starting the highlighted entry
  in N s" text: GRUB's progress bar ignored the requested height and drew
  a thick block.
- **Checked by booting it**: the theme was put on a `grub-mkrescue` ISO
  with sample NixOS, Windows and firmware entries and booted in QEMU at
  1920x1080, including moving the selection. Not yet seen on the real
  firmware.
- **`gfxmodeEfi` and `gfxmodeBios` are set to `1920x1080,auto`**; the
  background is made at 1920x1080 and GRUB scales it on other modes. The
  `mkForce` on `gfxmodeBios` stays for the reason below.
- **Why `gfxmodeBios` is forced:** `virtualisation.vmVariant` (the
  machinery behind `nixos-rebuild build-vm` and [Vm.nix](core-vm.md)) sets
  its own plain `1024x768` default for the same option, and two
  plain-priority definitions made `config.system.build.vm` fail to
  evaluate.

---

[← Pet.nix](desktop-pet.md) · [Index](CONFIGURATION.md) · [Performance.nix →](system-performance.md)
