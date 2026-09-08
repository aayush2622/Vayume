[Index](CONFIGURATION.md)

---

The escape hatch - for the handful of Ubuntu-only apps that were never going to run on NixOS any other way.

## `modules/apps/utils/distrobox/Distrobox.nix`

The escape hatch for software that only ever ships a `.deb` - CodeTantra
and NeoColab being the reason this exists. Neither is in nixpkgs, neither
publishes anything but an Ubuntu package, and `nix-ld`/FHS wrappers don't
help when the vendor expects a real apt dependency graph. A distrobox
container is the honest answer; this module just stops it from being a
pile of remembered shell commands.

**Backend is rootless podman, not the Docker that's already enabled.**
[DevTooling.nix](system-devtooling.md) gains
`virtualisation.podman` alongside the existing Docker, with
`dockerCompat = false` so nothing fights over the `docker` binary.
Distrobox prefers podman when both exist, and rootless podman is what
makes a GUI app in the box write files into `$HOME` as *you* rather than
as root. No user wiring was needed - nixpkgs already defaults
`autoSubUidGidRange = true` for normal users with no explicit ranges
(checked against `users-groups.nix`, not assumed), which is exactly what
rootless podman needs.

**The box does not share your home directory.** This is the one place
this module deliberately departs from distrobox's defaults. Distrobox
mounts all of `$HOME` into the container on purpose - tight host
integration is its whole design - but that means anything installed in
the box can read every file you own, which is the wrong default for
vendor software you don't control and can't audit. `isolateHome`
(on by default) gives the box its own home under
`~/.local/share/vayume-boxes/<name>` instead, and `unshare` defaults to
`[ "ipc" "process" ]` for namespace separation on top.

`netns` and `devsys` are deliberately *not* in that default. Unsharing
the network namespace cuts the box off the internet, and hiding host
devices takes the GPU with it - either one breaks a networked GUI app,
which is the entire use case. They're available in the option's enum if
a given box genuinely wants them.

Isolation has one consequence worth knowing: `distrobox-export` writes
its `.desktop` entry into the *box's* home, which is no longer the
host's, so an exported app would never reach the launcher. Both
`vayume-box-export` and `vayume-box-sync` therefore copy new entries and
icons back out to `~/.local/share/{applications,icons}` and refresh the
desktop database, so launcher integration still works exactly as it
would with a shared home.

**Flags only apply at creation time.** An existing box does not
retroactively gain an isolated home or new namespaces - `vayume-box-reset`
destroys and recreates it (prompting first, and keeping the box's home
directory) for when the options change.

**The box is created on demand, never at activation.** Every helper
starts by checking `distrobox list` and creating the container only if
it's missing. That's deliberate: pulling a container image is a slow
network operation, and activation runs before login (see
[Users.nix](core-users.md) on why that ordering is the
whole reason boot used to stall). Nothing here can delay a boot.

Six commands, all idempotent:

| Command | Does |
| --- | --- |
| `vayume-box` | Enter the box; with arguments, run them inside it |
| `vayume-box-install <x.deb\|apt-pkg>...` | Install local `.deb` files (apt resolves their dependencies) or plain apt packages |
| `vayume-box-apps` | List desktop entries the box now provides |
| `vayume-box-export <app>...` | Export an entry to the host launcher, so it shows up in DMS's spotlight like any native app |
| `vayume-box-sync` | Re-apply `vayume.ubuntuBox.aptPackages` + `exportApps` declaratively |
| `vayume-box-reset` | Destroy and recreate the box, picking up changed creation flags |

So the CodeTantra path is `vayume-box-install ~/Downloads/codetantra.deb`,
then `vayume-box-apps` to see what it registered, then
`vayume-box-export <name>`.

**`vayume.ubuntuBox` makes the result reproducible** once you know the
names: `aptPackages` and `exportApps` are re-applied by
`vayume-box-sync`, so a rebuilt machine gets the same box without
repeating the discovery. A downloaded `.deb` can't be declared this way -
it isn't in any apt repo and often sits behind a login - so that stays a
one-liner rather than a lie about being declarative. `name`/`image`
default to `ubuntu`/`ubuntu:24.04` and exist for when something needs a
different base.

**A container is not a VM, and it can't pretend to be a bare-metal
host.** Distrobox shares the host kernel, so `/proc`, cgroups,
`/run/.containerenv` and `systemd-detect-virt` all identify it from the
inside; there is no configuration here that hides that, and none is
planned. Software whose *licensing or proctoring* checks refuse a
container is refusing on purpose. If something fails to launch for an
ordinary reason instead - a missing shared library, a systemd or sandbox
error - that's a normal packaging problem worth debugging on its own
terms.

Anything with a nixpkgs equivalent belongs in `home.packages`. This is
for the genuinely Ubuntu-only tail.

---

[← Vesktop.nix](apps-utils-vesktop.md) · [Index](CONFIGURATION.md)
