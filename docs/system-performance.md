[Index](CONFIGURATION.md)

---

System-level tuning that isn't about any one app: memory and swap, disk, network stack, shutdown speed, the Nix daemon, and (only when the Gaming app is on) the gaming knobs. It is one module, `modules/system/Performance.nix`, with three options; everything it sets is a default that `_config.nix` or `Host.nix` can override with a normal assignment.

## `modules/system/Performance.nix`

```nix
vayume.performance = {
  enable = true;
  gaming = false;
  kernel = "zen";
};
```

- **`enable`** (default `true`) turns the whole page off.
- **`gaming`** defaults to `vayume.apps.Gaming.enable`, so the gaming block follows the app toggle.
- **`kernel`** is `null` (the NixOS default, unchanged), `"lts"`, `"latest"` or `"zen"`.

**Priority.** Every value is set with `lib.mkOverride 900`. That is stronger than the NixOS module defaults (priority 1000, which would otherwise clash: `vm.max_map_count` is one) and weaker than an ordinary assignment (100), so your own setting, and the network hardening in [Network.nix](system-network.md), always win. Keys NixOS already sets to the same useful value (`fs.inotify.max_user_watches`) or that another module owns (`fs.inotify.max_user_instances`) are left out.

### Memory and swap

| Setting | Value | Why |
| --- | --- | --- |
| `zramSwap` | zstd, 50% of RAM, priority 100 | zstd compresses best; a fixed high priority makes zram always used before any disk swap |
| `vm.swappiness` | 180 | With zram, swapping is cheaper than dropping file cache, so the kernel should prefer it (values above 100 are valid since kernel 5.8) |
| `vm.page-cluster` | 0 | No read-ahead of swap pages - pointless on RAM-backed swap |
| `vm.watermark_boost_factor` | 0 | Stops the kernel reclaiming extra memory after fragmentation, which shows up as stutter |
| `vm.watermark_scale_factor` | 125 | Wakes kswapd earlier, so allocations stall less |
| `vm.vfs_cache_pressure` | 50 | Keeps directory and inode caches longer |
| `vm.dirty_bytes` / `vm.dirty_background_bytes` | 256 MiB / 64 MiB | Caps write-back bursts in absolute terms; the default ratio scales with RAM and can stall the desktop on a big copy |
| `vm.max_map_count` | 2147483642 | SteamOS's value; Proton games and some JVM tools exhaust the 1048576 default |
| `systemd.oomd` | on, root and user slices | Kills the runaway cgroup on memory *pressure* before the machine freezes |

### Disk

- `services.fstrim` runs weekly TRIM.
- A udev rule sets the I/O scheduler: `none` for NVMe (the device queue is already deep), `mq-deadline` for SATA/eMMC SSDs, `bfq` for spinning disks. The rule silently does nothing where the scheduler isn't available.
- `boot.tmp.cleanOnBoot` empties `/tmp` at boot; `boot.loader.grub.configurationLimit = 10` keeps the GRUB menu and `/boot` from growing without bound.

### Network stack

BBR congestion control with the `fq` qdisc (the module is loaded explicitly), TCP Fast Open both ways, no slow-start after idle, MTU probing, a 5 s FIN timeout, and larger backlogs (`netdev_max_backlog` 16384, `somaxconn` 8192). BBR and `fq` are also set by the hardening block in Network.nix; the plain value there wins, and they agree.

### Boot, shutdown and services

- `kernel.nmi_watchdog = 0`, the `nowatchdog` kernel parameter and the `iTCO_wdt` / `sp5100_tco` blacklist remove the hardware watchdog wakeups - a small power and latency win on a desktop with no watchdog daemon.
- Stop timeouts of 15 s (system) and 10 s (user) instead of 90 s, so one stuck unit doesn't hold up shutdown.
- `DefaultLimitNOFILE = 1024:1048576`: the soft limit stays at 1024 for compatibility, the hard limit is high enough for esync (Wine/Proton) and big IDE indexers.
- The journal is capped at 500 MB and one month.

### Nix daemon

The daemon runs with the `batch` CPU policy and `idle` I/O class, so a rebuild in the background doesn't make the desktop stutter. `download-buffer-size` is 256 MiB (avoids the "download buffer is full" stall on fast links), `connect-timeout` is 5 s, and `min-free` / `max-free` (5 GiB / 20 GiB) make a build collect garbage itself rather than fail on a full disk. `documentation.man.cache.enable = false` skips regenerating the man-page index on every rebuild, which is a noticeable share of activation time; `apropos` and `man -k` no longer work.

### Gaming block

Applied when `vayume.performance.gaming` is true:

- `kernel.split_lock_mitigate = 0`: split-lock detection throttles a few games badly, and gamemode disables it anyway.
- `kernel.sched_cfs_bandwidth_slice_us = 3000`: shorter CFS bandwidth slices, moved here from `Host.nix`.
- `programs.gamemode.settings.general.renice = 10`: a stronger priority boost than gamemode's default of 4.
- `programs.gamescope` with `capSysNice`, and Steam's gamescope session.

The `ntsync` module and its udev rule stay in `Host.nix`, since Wine uses them outside Steam too.

### Kernel choice

`vayume.performance.kernel` swaps `boot.kernelPackages`. Leave it `null` unless you want the change: `zen` ships desktop and gaming patches, `latest` gets new hardware support sooner, `lts` trades both for stability. The Nvidia module rebuilds against whichever you pick, but the first rebuild after switching compiles a kernel, and [Waydroid](apps-utils-waydroid.md) needs a kernel with binder support, so check it after switching.

### Boot time

Measured with `systemd-analyze` on this machine before changing anything: 26.1 s in total - firmware 5.4 s, loader (GRUB) 6.6 s, kernel 1.0 s, initrd 2.4 s, userspace 10.8 s. What was worth fixing:

- **Home Manager activation blocked the login screen.** `home-manager-<user>.service` is ordered before `systemd-user-sessions.service`, and the display manager waits for that, so anything slow in an activation script is slow login. The activation itself took about 1 s; the rest was the Zen Browser script downloading its mod index on every activation, including at boot before DNS works, with `curl --retry 2` sleeping 1 s and then 2 s between attempts (`journalctl -b -u home-manager-<user>` showed three "Could not resolve host" lines). It now downloads the index only when it is missing or the set of mods changed (a stamp file in the profile), and curl no longer retries with back-off. No other activation script touches the network. See [ZenBrowser.nix](apps-utils-zenbrowser.md).
- **GRUB waited 5 s.** `boot.loader.timeout` is 2 s, still enough to hold a key and pick Windows.
- **`quiet`** on the kernel command line: less console output during boot.
- **Docker starts on first use** (`virtualisation.docker.enableOnBoot = false`, socket-activated) instead of at boot. A container with a `--restart always` policy won't come back until something first talks to Docker.
- **Boot time report** (`vayume boot-time`, or the Performance page in Vayume Settings) prints `systemd-analyze`, the slowest units and the critical chain to the display manager, so you can measure the effect after a reboot.

Expected saving is roughly 6 s (about 3 s of GRUB menu and about 3 s of curl waiting), but that is an estimate from the logs, not a measurement - reboot and run the report.

Looked at and left alone:

- **`NetworkManager-wait-online` (4.6 s)** is the classic thing to disable, but here it is not on the critical path to the login screen (the chain goes through home-manager), so disabling it would save nothing you'd see and could reorder network-dependent services such as Tor.
- **Firmware (5.4 s)** is UEFI: enable "Fast Boot" and disable unused boot devices in the firmware setup; nothing in NixOS controls it.
- **systemd-boot instead of GRUB** loads in tens of milliseconds where GRUB takes seconds, but this host relies on a fixed GRUB chainload entry for Windows and a GRUB theme, so switching is a change of bootloader, not a tweak.
- **`boot.initrd.systemd.enable`** parallelises the initrd and is often faster, but this root is Btrfs with a `resume=` swap device, and I can't test hibernation here; it is a one-line experiment if you want to try it.
- **`mitigations=off`** speeds boot slightly and weakens CPU vulnerability protections.

### Left out on purpose

- **`mitigations=off`**: measurable speed, but it disables CPU vulnerability protections.
- **Preempt/threadirqs kernel parameters and out-of-tree kernels (CachyOS)**: the gain is small and the parameters interact with the Nvidia driver.
- **`ananicy`**: overlaps gamemode's renice and adds a second thing adjusting priorities.

## Sources

- [NixOS Wiki: Gaming](https://wiki.nixos.org/wiki/Gaming) - `vm.max_map_count`, split-lock mitigation, gamemode, zen kernel.
- [Kernel and performance notes](https://wiki.infernalcode.com/architecture/kernel/) - zram-tier sysctls, network sysctls, stop timeouts.
- The r/NixOS thread that prompted this page could not be fetched; its values were cross-checked against the two pages above.

---

[← Misc.nix](system-misc.md) · [Index](CONFIGURATION.md) · [Storage.nix →](system-storage.md)
