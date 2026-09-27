[Index](CONFIGURATION.md)

---

Keeps the flake inputs and the hand-pinned plugins current on a schedule, and never leaves the machine half-updated.

## `modules/core/AutoUpdate.nix`

### Settings

Everything is under **Updates → Automatic updates** in Vayume Settings,
from the `vayume.updates` options:

| Option | Default | What it does |
|---|---|---|
| `flake` | `true` | `nix flake update`: nixpkgs, home-manager, DMS, the VS Code and JetBrains plugin sets, and every other input |
| `plugins` | `true` | Bumps the VS Code and Android Studio plugins pinned by version and hash (`vayume check-plugin-updates --apply`) |
| `frequency` | `weekly` | `daily` or `weekly` |
| `apply` | `boot` | `boot` uses the new system from the next restart; `switch` also switches to it straight away |

The two parts cover different things. Most editor extensions and the
Zen add-ons come from flake inputs (nix-vscode-extensions,
nix-jetbrains-plugins) or install at their latest version, so `flake`
updates them. `plugins` only covers what a module pins by hand, such
as the WakaTime and Copilot plugins for Android Studio.

With both switched off the timer is removed. **Update everything now**
on the same page, or `vayume update` in a terminal, runs both parts
straight away whatever the switches say. **Last update**
(`vayume update status`) shows when the last run happened, what it
changed and when the next one is due.

### What a run does

The timer starts `vayume-update.service`:

1. It finds the checkout the same way `vayume rebuild` does, through
   `repoDiscovery`. Every edit runs as the user who owns the checkout,
   so `flake.lock` and the module files never end up owned by root.
2. It saves `flake.lock` and every module file that pins a hash.
3. It updates the flake inputs. If `flake.lock` already has edits that
   aren't in git, it skips this step, so a lock you are working on is
   never overwritten.
4. It bumps the pinned plugins.
5. If nothing changed it stops, without building.
6. It runs `nixos-rebuild boot` (or `switch`). If the build fails, it
   puts the saved files back, so the repo and the running system stay
   as they were.
7. It sends a desktop notification with the result and writes it to
   `/var/lib/vayume-update/status.json`.

Nothing is committed. The changes show up in `git status`, to be
committed with the next commit or thrown away with `git checkout`.

### Keeping it out of the way

- `ConditionACPower`: on battery the run is skipped. `Persistent=true`
  runs it at the next chance instead.
- `Nice=19`, idle IO class and the batch CPU policy: the build only uses
  time the desktop isn't using.
- `RandomizedDelaySec=30min`: runs don't land exactly at midnight, when
  the machine was probably just woken.
- `network-online.target` plus a lock in `/run`: a manual run and a
  timer run can't overlap.

`vayume update` goes through a sudo rule. The rule covers only the
exact update command with `--flake --plugins`, for wheel users and
without a password, the same pattern `vayume rebuild` uses.

---

[← PluginUpdateCheck.nix](core-pluginupdatecheck.md) · [Index](CONFIGURATION.md) · [Dms.nix →](desktop-dms.md)
