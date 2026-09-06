[Index](CONFIGURATION.md)

---

The shortest file in the repo, and proof that not everything needs an essay.

## `modules/system/Zram.nix`

One line - `zramSwap.enable = true;` - and the upstream module's own
defaults (50% of RAM, `zstd`, priority `5`) already do the right thing,
confirmed by actually reading that module's source rather than assuming:
`zstd` is both fast and well-compressed, and priority `5` beats a plain
disk swap entry's default, so the RAM-backed swap gets used first and
[Diablo's real disk swap partition](core-hardware.md)
only picks up genuine overflow. Split out into its own file under
`system/`, not folded into `_hardware.nix`, since nothing about it is
actually hardware-specific - any host with enough RAM benefits the same
way, and a second host defined later gets it for free instead of needing
this copied in.

---

[← DevTooling.nix](system-devtooling.md) · [Index](CONFIGURATION.md) · [GrubTheme.nix →](system-grubtheme.md)
