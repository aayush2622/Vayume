[Index](CONFIGURATION.md)

---

A second, disposable copy of the whole machine that boots in a window - how every change in this repo got tested before it touched real hardware.

## `modules/system/Vm.nix`

### Running it

```bash
nix run path:.#vm              # Diablo
nix run path:.#vm-<host>       # any host under modules/hosts/
nix run path:.#vm -- --fresh   # throw the disk image away first
```

The disk image lives at `~/.cache/vayume/<host>.qcow2` (override with
`VAYUME_VM_IMAGE=/some/path.qcow2`). It persists between runs, so state
you create inside the VM survives a reboot of it; `--fresh` (or `-f`)
deletes it for a clean first boot. If `virtualisation.diskSize` grows
past the existing image's size, the runner recreates the image instead
of booting a disk that's too small - it never resizes one in place.
Root has no password inside the VM (see item 4 below), so a console
login always works even if your own user's password doesn't.

**One shared module, not one per host.** `flake.nixosModules.VmTesting`
used to live in `modules/hosts/Diablo/Vm.nix`, and `install.sh` copied
it into every new host. Two copies of the same module both set
`virtualisation.qemu.package` (a unique option), so the moment a second
host existed, *every* host's VM failed to evaluate - and the list-typed
QEMU flags were doubled. Nothing in it was ever Diablo-specific, so it
lives in `system/` now and generates a `vm-<host>` app for each entry
in `nixosConfigurations`; `vm` stays as an alias for Diablo. A host
created by an older `install.sh` still has its own `Vm.nix` - delete it
(`install.sh` warns about it on a re-run).

### Why each override exists

Everything the VM build (`nixos-rebuild build-vm`) needs that the real
machine doesn't lives here, in one file, instead of scattered wherever
someone felt like disabling hardware. Three separate fixes, all VM-only -
the real deployed system never sees any of this:

1. QEMU has no Nvidia GPU and no ASUS hardware, so the real Nvidia driver
   stack gets cleared for the VM build in favor of QEMU's own virtual
   GPU. `asusd`/`supergfxd` get force-disabled the same way.
2. That alone still left the VM stuck on a black screen after boot.
   Turns out QEMU's virtual GPU has no real hardware-accelerated
   rendering path, so the greeter's Wayland client couldn't get a
   graphics context and its software fallback also failed. Fix: force
   software rendering in the VM's greeter environment specifically -
   real hardware has a working Intel iGPU and shouldn't pay that cost.
3. Past the greeter, niri itself still couldn't find a GPU allocator with
   a plain virtual display device - needed a GL-enabled virtio display
   backed by the *host's* real GPU instead. The wrinkle: the dev machine
   this was first built on wasn't NixOS, so the Nix-built QEMU couldn't
   find that host's mesa drivers in the paths it expected. The QEMU
   wrapper points it at `/usr/lib/{dri,gbm}` and the glvnd vendor dir -
   but only at run time, and only when the machine running the VM has
   no `/run/opengl-driver` and does have `/usr/lib/dri` (a non-NixOS
   distro). On a NixOS host those paths don't exist, and forcing them
   would hide the real drivers from QEMU, so the wrapper does nothing
   there.
4. **`users.users.root.hashedPassword = lib.mkForce ""` - passwordless
   root, VM-only.** Added while actually using this VM to verify a
   different fix (a portal misconfiguration) for real instead of trusting
   generated config alone - `mutableUsers = false` plus no explicit root
   password left the console `sulogin`-locked with no way in at all,
   real or synthetic. Same reasoning as everything else in this file:
   pure testing convenience, scoped to `virtualisation.vmVariant` only,
   the real machine's root account is completely untouched by it.

Worth knowing if you use this VM for its own sake: it genuinely boots to
a real login and a working shell this way, and that's how a real,
previously-unknown bug got caught here too - `config.system.build.vm`
flat out failed to evaluate before this session's fixes, over an
unrelated `gfxmodeBios` conflict between
[Misc.nix](system-misc.md) and this module's
own upstream `qemu-vm.nix` machinery. Static config generation checks
don't catch that kind of thing - only an actual build (or boot) does.

---

[← _hardware.nix](core-hardware.md) · [Index](CONFIGURATION.md) · [Users.nix →](core-users.md)
