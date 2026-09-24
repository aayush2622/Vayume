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
[Misc.nix](system-misc.md) gains
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
`vayume box export` and `vayume box sync` therefore copy new entries and
icons back out to `~/.local/share/{applications,icons}` and refresh the
desktop database, so launcher integration still works exactly as it
would with a shared home. Every box's exported launchers/icons land in
those same two shared host directories rather than per-box ones, so
everything shows up in one launcher regardless of which container it
came from - the only downside is a genuine name collision between two
boxes' exported apps, which is last-export-wins if it ever happens.

**Two dependency lists get installed into the box lazily, on demand
rather than at creation.** `appImageDeps` covers the system libraries an
AppImage runtime (and the Electron app usually inside it) links against
but never bundles itself - `ensureAppImageDeps` checks each one with
`dpkg -s` and only runs `apt-get install` for whatever's still missing,
so adding a package to the list later is picked up on the very next run
rather than requiring a rebuild of the box. `clipboardDeps`
(`wl-clipboard`, `xclip`, `xsel`) is a separate case: `DISPLAY`/
`WAYLAND_DISPLAY` inside the box are the host's own sockets (distrobox
mounts both in by default, confirmed live - same X server and compositor
as everything else, no bridging needed), so a GUI app's native clipboard
already works. What doesn't is anything that shells out to sync it - a
terminal copy/paste, a script calling `wl-copy`/`xclip` directly - since
neither tool exists in a bare Ubuntu image. `ensureClipboardDeps` runs
the same idempotent check from `ensureBox` itself, not just the AppImage
paths, since clipboard sync matters for every box.

**`--unshare-*` flags have to go on the command line directly, not
through `--additional-flags`.** They're distrobox's own flags, not the
underlying container manager's, and podman rejects them if smuggled in
through `--additional-flags` with `unknown flag: --unshare-ipc`.

**`ensureDbus` starts a system bus inside the box by hand.** Chromium-
based apps log a stream of errors and misbehave with no system bus
available, and the box has no init process to start one on its own, so
this checks for the socket and forks `dbus-daemon --system` if it's
missing.

**AppImages need `ensureBinfmt` because of a mismatch between the host's
binfmt registration and the container's mount namespace.** An AppImage
has to be started by its own runtime - many refuse to launch when their
parent process is a shell or a sandbox wrapper like `bwrap`. Normally the
kernel's `binfmt_misc` handles that transparently, but the box inherits
the host's binfmt registrations, and the host's interpreter path
(`/run/binfmt/...`) doesn't exist inside the container's mount namespace,
so `exec` fails with `ENOENT`. Mounting a private, empty `binfmt_misc`
inside the box makes the kernel exec the AppImage directly with its own
runtime as the parent, without touching the host's registration.
`vayume box run` resolves and rewrites the target path on the host side
for the same reason - so the command it finally execs is the AppImage's
own runtime rather than a shell wrapper, keeping that parent chain
intact.

**Flags only apply at creation time.** An existing box does not
retroactively gain an isolated home or new namespaces - `vayume box reset`
destroys and recreates it (prompting first, and keeping the box's home
directory) for when the options change.

**The box is created on demand, never at activation.** Every helper
starts by checking `distrobox list` and creating the container only if
it's missing. That's deliberate: pulling a container image is a slow
network operation, and activation runs before login (see
[Users.nix](core-users.md) on why that ordering is the
whole reason boot used to stall). Nothing here can delay a boot.

Seven commands, all idempotent:

| Command | Does |
| --- | --- |
| `vayume box` | Enter the box; with arguments, run them inside it |
| `vayume box run <cmd\|file.AppImage>` | Run something inside the box - a bare filename resolves against the box's own `~/Applications` |
| `vayume box install <x.deb\|apt-pkg>...` | Install local `.deb` files (apt resolves their dependencies) or plain apt packages |
| `vayume box apps` | List desktop entries the box now provides |
| `vayume box export <app>...` | Export an entry to the host launcher, so it shows up in DMS's spotlight like any native app |
| `vayume box sync` | Re-apply `vayume.ubuntuBox.aptPackages` + `exportApps` declaratively |
| `vayume box reset` | Destroy and recreate the box, picking up changed creation flags |

So the CodeTantra path is `vayume box install ~/Downloads/codetantra.deb`,
then `vayume box apps` to see what it registered, then
`vayume box export <name>`.

**`vayume box run`'s path resolution runs on the host, before anything
crosses into the box.** An unquoted `~` is expanded by the host shell
before the script ever sees it, so `vayume box run ~/x.AppImage` already
points at the *host's* home by the time it arrives - only a quoted
`"~/x.AppImage"` reaches the script's own `~/` handling, which resolves
against the box's home instead. A bare filename with no path separator
is checked against the box's `~/Applications` directory (the same HOST
path `vayume box install` populates, just under the isolated home rather
than the real one) so `vayume box run foo.AppImage` just works after an
install; anything else - `ls`, `apt`, an explicit path - falls through
untouched. `vayume box run` also runs `ensureAppImageDeps` on every
`*.AppImage` target, not only right after install, because a box that
never ran an install (or an AppImage copied in some other way) fails
with `No suitable fusermount binary found` otherwise - the check is
idempotent and cheap once the dependencies are already there, so it's
simpler to just always run it than to rely on install having gone first.

**`vayume.ubuntuBox` makes the result reproducible** once you know the
names: `aptPackages` and `exportApps` are re-applied by
`vayume box sync`, so a rebuilt machine gets the same box without
repeating the discovery. A downloaded `.deb` can't be declared this way -
it isn't in any apt repo and often sits behind a login - so that stays a
one-liner rather than a lie about being declarative. `name`/`image`
default to `ubuntu`/`ubuntu:24.04` and exist for when something needs a
different base.

**`vayume.ubuntuBox.count` turns one box into N independent ones.** The
first box is always the seven commands above, unnumbered, entering
`name`. Set `count` higher - say 3 - and each extra box gets its own
numbered set starting at 2: `vayume box2`, `vayume box3` (and each
one's `run`/`install`/`apps`/`export`/`sync`/`reset`), one real
container per number. Every other
option - `image`, `unshare`, `fuse`, `shmSize`, `aptPackages`,
`exportApps` - is shared across all of them; there's no per-box override
for those, just per-box identity and storage.

The first box never changes: its container name and `homeDir` are
always exactly `name`/`homeDir` as configured, and its commands are
always `vayume box ...`, at any `count`. So raising `count` on a machine
that already has a box never renames, recreates or moves anything - the
existing box keeps its commands and the new ones appear beside it. (It
used to become `box1` the moment `count` went above 1, which silently
broke every script and habit that said `box`.) Only box2..N are genuinely new,
numbered containers (`<name>2`..`<name><count>`), each with its own
auto-derived home under `~/.local/share/vayume-boxes/`.

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
