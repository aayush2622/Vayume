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

- **It is laid out relative to the screen centre, at any resolution.**
  The first version baked the card into a 1920x1080 background and placed
  every element in absolute pixels from the top. On this 1920x1200 panel,
  or whenever the firmware picked another mode, the stretched background
  and the menu no longer lined up, and moving the selection could look as
  if the keys did nothing. Now the background is only the blurred wallpaper
  (`desktop-image-scale-method: "crop"`), the card is the boot menu's own
  nine-slice box (`menu_pixmap_style = "card_*.png"`, with tall top and
  bottom slices that reserve room for the title and the hints), and every
  label sits at `50%±offset`. Checked in QEMU with UEFI (OVMF) and the same
  GRUB 2.14 EFI build the host uses, at 1920x1080, 1280x800 and
  1024x768: the card stays centred and whole, the selection moves on every
  key, and Enter/Esc go into and out of the 40-entry "All configurations"
  submenu, which scrolls.
- **Paint order is the reverse of `theme.txt`.** GRUB's canvas inserts
  each component at the front of its list, so the last one in the file is
  painted first. The boot menu, whose card covers the labels, is therefore
  last in the file, and the labels are drawn over it.
- **Everything is rendered at build time.** GRUB can't blur, round
  corners or draw CJK text from a system font, so ImageMagick blurs the
  wallpaper and draws the card, the selection pill, the row boxes and the
  scrollbar as nine-slice pixmaps. Slices are written as `PNG32`:
  ImageMagick otherwise saves fully transparent corners as palette PNGs,
  which GRUB draws as black squares. The card is solid, so redrawing the
  menu never blends a large translucent area.
- **Fonts are converted with `grub-mkfont`** from `pkgs.roboto` at the
  sizes the layout uses, and 夜 alone (`-r 0x591C-0x591C`) from Noto Serif
  CJK. GRUB matches `font = "..."` against the name stored inside each
  `.pf2`, so the build reads those names back out of the files and
  substitutes them into `theme.txt` rather than guessing them; the medium
  weight gets its own family name (`-n "Roboto Medium"`) because
  grub-mkfont names every weight "Regular". The build fails if a
  placeholder is left unresolved. NixOS loads every `.pf2` in the theme
  folder by name, which is also how the QEMU test loads them.
- **Unselected rows use a transparent box with the same 14px borders as
  the selected pill.** GRUB 2.14 offsets each row's text by its own box's
  top border, so without it the selected entry sat 14px lower than the
  rest.
- **The scrollbar is 6px wide with `scrollbar_thumb_overlay = true`.**
  GRUB silently drops the scrollbar when the frame and thumb borders don't
  fit in `scrollbar_width`, which is why the first version never showed
  one.
- **There is no countdown bar**, only the "Starting the highlighted entry
  in N s" text: GRUB's progress bar ignored the requested height and drew
  a thick block.
- **`gfxmodeEfi` is `auto`**, the panel's native mode, since the layout
  no longer depends on the resolution; `gfxmodeBios` stays at
  `1920x1080,auto`.
- **Why `gfxmodeBios` is forced:** `virtualisation.vmVariant` (the
  machinery behind `nixos-rebuild build-vm` and [Vm.nix](core-vm.md)) sets
  its own plain `1024x768` default for the same option, and two
  plain-priority definitions made `config.system.build.vm` fail to
  evaluate.

---

[← Pet.nix](desktop-pet.md) · [Index](CONFIGURATION.md) · [Performance.nix →](system-performance.md)
