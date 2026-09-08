[Index](CONFIGURATION.md)

---

Docker and Podman, side by side - infrastructure that doesn't care what desktop you're running, which is exactly why it lives outside `desktop/`.

## `modules/system/DevTooling.nix`

Named for what it is: system-level stuff for dev workflows, not tied to
any one app. Used to be called `dev-system.nix`, which read way too much
like [apps/devTools/DevTools.nix](apps-dev-devtools.md)
- a completely different, per-user file (VS Code/git/gh/lazygit/
docker-compose) - so it got a better name.

`virtualisation.docker.enable`/`libvirtd.enable` are the actual daemons
that `docker-compose` and any VM tooling need running. `programs.adb.enable`
got dropped since systemd 258+ handles the adb udev rules on its own now,
and `pkgs.android-tools` (already pulled in by
[AndroidStudio.nix](apps-dev-androidstudio.md))
covers the actual `adb` command. `users.groups.adbusers` sticks around
here purely so it's a valid group to put in `extraGroups` - it doesn't
grant anything on its own anymore, it's basically a fossil.

---

[← SddmTheme.nix](desktop-sddm.md) · [Index](CONFIGURATION.md) · [Zram.nix →](system-zram.md)
