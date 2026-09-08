[Index](CONFIGURATION.md)

---

The one file NixOS writes for you, not the other way around - the literal map of the disk this machine actually has.

## `modules/hosts/<name>/_hardware.nix`

The one file in this repo that isn't a proper flake-parts module - no
`flake.nixosModules.X` wrapper, just a plain NixOS module. The leading
underscore keeps import-tree from trying anyway; it only ever gets pulled
in through `Host.nix`'s own `./_hardware.nix` import.

**Gitignored and required**, along with its sibling `_user.nix` (usernames,
groups, password hash, secrets - full shape under
[core/Users.nix](core-users.md) below, mechanics shared with this
file explained here). Both hold exactly the two things that made this repo
unsafe to publish before - real disk UUIDs here, a real password hash
there - so neither is ever committed. `Host.nix` wraps both imports in a
small `requireLocalFile` helper that checks `builtins.pathExists` first
and throws a message pointing at the matching `*.nix.example` template
(also under `modules/hosts/<name>/`, committed as normal) instead of
letting it fail with Nix's generic "path does not exist" - checked for
real: deleting `_hardware.nix` and running `nix flake check` prints the
`cp .../_hardware.nix.example ...` instruction, not a raw Nix trace.

> [!IMPORTANT]
> This only actually works with a `path:` flake ref
> (`nixos-rebuild switch --flake path:.#Diablo`, not bare `.#Diablo`).
> Nix resolves a bare ref for a git-repo directory through git's
> tracked-files-only view of the tree - which is exactly what makes a
> committed `_hardware.nix` disappear the moment `.gitignore` starts
> covering it, "missing" or not. `path:` copies the real directory as-is
> instead, so both files are visible once they actually exist on disk.
> Confirmed directly: `nix eval .#nixosConfigurations.Diablo...` hit the
> `requireLocalFile` throw with real `_hardware.nix`/`_user.nix` sitting
> right there on disk; `nix eval path:$PWD#nixosConfigurations.Diablo...`
> evaluated clean. The rebuild button
> ([Dms.nix](desktop-dms.md)'s `vayumeRebuildScript`)
> and every command in the README already use `path:` - this is only a
> trap if you type a `nixos-rebuild`/`nix build` command by hand and
> forget it.

To make one for a different machine:

```bash
sudo nixos-generate-config --show-hardware-config > modules/hosts/<name>/_hardware.nix
```

Then delete the Nvidia/Optimus block entirely unless you're also on an
Nvidia Optimus laptop - `intelBusId`/`nvidiaBusId` are this specific
machine's PCI addresses, not yours (`lspci` finds your own).

**The Nvidia block, briefly:**
- Power management lets the dGPU actually power down when idle via PRIME
  offload, instead of quietly draining battery doing nothing.
- The open kernel module would work fine on this RTX 3050, but closed is
  still the safer default.
- PRIME offload means the iGPU drives the display and the dGPU only
  wakes up for apps launched through `nvidia-offload`. Want the dGPU
  running everything all the time instead? Swap to `prime.sync.enable`
  and drop the power-management lines.

**`asusd` and `supergfxd` are two separate daemons that like to get
confused for one another.** `asusd` handles keyboard lighting, fan
curves, battery limits - it does *not* touch GPU switching. That's
`supergfxd`'s job, gated behind its own separate enable flag. Turn on
`asusd` alone and GPU mode switching silently does nothing - looks
exactly like a broken driver, isn't one.

- **`services.supergfxd.settings` is deliberately left unset.** It used
  to pin the mode to `"Hybrid"`, which sounded reasonable - declarative
  beats remembering a manual command - except it's a real bug: NixOS
  writes that setting straight to `/etc/supergfxd.conf` as a symlink
  into the read-only Nix store, and re-creates that symlink on *every*
  rebuild, for any reason. So switching GPU modes through asusctl or the
  DankAsusControl widget would appear to work, right up until the next
  rebuild silently reset it back to Hybrid. Leaving `settings` unset
  means NixOS never touches that file at all, so `supergfxd` gets to own
  it as a normal file and mode switches actually stick. Checked this by
  building and confirming the file's just gone from the output.
- `supergfxd` also needs `pciutils` on its `PATH` or it can't find the
  dGPU at all - a known nixpkgs gap, worked around here.
- **`power-profiles-daemon` stays off** once `asusd` is on - they both
  claim the same D-Bus name for power profiles, so running both just
  means whichever starts second silently loses.

**Swap and hibernate now actually use hardware that was already sitting
there.** This machine already has a real 16.8GB swap *partition*
(`nvme0n1p5`) from the original dual-boot install - `swapDevices` just
never referenced it, so NixOS ran with zero swap of its own the whole
time. Checked real numbers before touching anything: 15GiB RAM, that
partition sized comfortably above it, so it's genuinely enough for a
full hibernation image with no new disk space carved out anywhere -
worth being deliberate about on a btrfs partition that's already been
through one real "disk full" incident this project.

- `swapDevices` points at it by UUID, same convention as the filesystem
  entries right above it.
- `boot.resumeDevice` is set explicitly to the same UUID - NixOS would
  actually auto-detect this from `swapDevices` alone since it's a plain
  partition (no swap*file* offset math needed), but spelling it out
  means the hibernate wiring reads as an intentional feature here, not
  an accident of what happened to be declared. Confirmed for real: the
  built system's own `kernel-params` file has `resume=` pointing at the
  exact right UUID, and `hardware.nvidia.powerManagement.enable` (already
  on, a few lines up) is the same setting that makes the proprietary
  driver actually save/restore GPU state across a hibernate cycle - this
  slots into something that was already half set up for it.
- **`compress=zstd` on both btrfs mounts** (`/` and `/home`) - real,
  low-risk win on two fronts at once: less disk I/O for anything
  compressible (most config files, source code, a lot of what's actually
  in `/home`), and some space back on a disk that's been genuinely tight
  more than once. Confirmed in the real built `/etc/fstab`, not just the
  Nix option.

---

[← Host.nix](core-host.md) · [Index](CONFIGURATION.md) · [Vm.nix →](core-vm.md)
