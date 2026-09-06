[Index](CONFIGURATION.md)

---

A second, disposable copy of the whole machine that boots in a window - how every change in this repo got tested before it touched real hardware.

## `modules/hosts/<name>/Vm.nix`

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
   this was built on isn't NixOS, so the Nix-built QEMU couldn't find
   that host's mesa drivers in the paths it expected. Fixed with a
   wrapper that points QEMU at this specific host's actual driver paths -
   which means it's genuinely tied to this one dev machine's distro
   layout, and would need swapping back to plain `qemu_kvm` on an actual
   NixOS host, where the problem doesn't exist in the first place.
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
[GrubTheme.nix](system-grubtheme.md) and this module's
own upstream `qemu-vm.nix` machinery. Static config generation checks
don't catch that kind of thing - only an actual build (or boot) does.

---

[← _hardware.nix](core-hardware.md) · [Index](CONFIGURATION.md) · [Users.nix →](core-users.md)
