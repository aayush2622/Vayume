[Index](CONFIGURATION.md)

---

Who's allowed to log in, and what they're allowed to turn on - the framework the rest of the repo's per-user config all sits on top of.

## `modules/vayume/Users.nix`

The shared framework behind every `vayume.users.<name>` entry - what
fields exist, what they do, and where the whole list actually comes
from now: the same one file as `vayume.apps`.

**`vayume.users` and `vayume.apps` both default to `{ }` here and get
their real values from `_config.nix`** - a plain NixOS module living
next to `Host.nix` (see [_hardware.nix](core-hardware.md) above for the
gitignored/required/`path:` mechanics, shared with `_config.nix`). Both
used to live somewhere else entirely - `vayume.users` directly in
`Host.nix` (real usernames, group memberships, a password hash, all
committed to git - fine for a private repo, genuinely not for a public
one), `vayume.apps` in `Host.nix` too, just tracked (no secrets in it,
but still a second file a person had to find and edit for completely
ordinary configuration). One file now covers both - the actual answer
to "where do I configure Vayume for myself":

```nix
# modules/hosts/<host>/_config.nix
{ pkgs, ... }:
{
  vayume.users = {
    ash = {
      fullName = "Ash";
      extraGroups = [ "networkmanager" "wheel" "video" "input" ];
      hashedPassword = "$6$...";
      secrets = {
        WAKATIME_API_KEY = "...";
        RBW_EMAIL = "...";
      };
    };

    random = {
      fullName = "Random";
      extraGroups = [ "networkmanager" "video" "input" ];
    };
  };

  vayume.apps = {
    Vscode.enable = true;
    Gaming.enable = false;
    # ...one line per module under modules/apps/
  };
}
```

- **No fallback test user any more.** Earlier versions of this repo read
  an out-of-repo `/etc/vayume/config.json` at eval time and fell back to
  a single passwordless account if it didn't exist, so a fresh public
  clone could still evaluate with zero setup. That's gone: the build now
  hard-fails with a clear message (see above) instead of silently
  standing up an account nobody asked for - copy `_config.nix.example`
  and pick a real username before the first rebuild, every time.
- **Read at plain Nix module-evaluation time**, not through
  home-manager activation - it has to be, since NixOS needs to know who
  the users even are before any of their home directories, let alone
  home-manager, exist.
- **`secrets`, per user, optional**: passed to every app module as
  `vayumeSecrets` (see below) - missing keys, or the whole block, fall
  back to `"REPLACE_ME"` placeholders instead of erroring.
- **Plain Nix values, no encryption layer.** Fine, since `_config.nix`
  is gitignored and only ever readable by whoever already has read
  access to this checkout - see below for the one real trade-off this
  makes.
- **DMS's "Vayume Settings" plugin edits both halves of this file**
  through `vayume config` - see
  [core-vayume-config.md](core-vayume-config.md). Accounts themselves
  (add/remove), display name, groups, password, `secrets`, and
  `packages` are all editable from its Users page now; `avatar`,
  `shell`, and `extraPackages` stay hand-edit-only - package/path-typed
  values a text field or a search box can't safely produce.

Field meanings:

- `hashedPassword`: generate with `mkpasswd -m sha-512`. Leave it unset
  (`null`) in `_config.nix` and you get `changeme` as a fallback
  password instead. Because `users.mutableUsers = false`, that fallback
  is re-applied on every rebuild - `passwd` can't change it for good,
  only a real hash here (or Vayume Settings' password field) can. A
  value starting with `REPLACE` (the old example's placeholder) is a
  hard evaluation error, since NixOS itself only *warns* about an
  invalid hash and then locks the account.
- **Home Manager backups overwrite the previous backup.** When a
  managed file collides with an unmanaged one, Home Manager moves the
  old one to `<file>.backup` - but if that `.backup` already exists
  (the second time an app rewrites the same file), activation *fails*,
  and with it the whole user generation, at boot as well as on
  rebuild. `overwriteBackup = true` keeps the newest displaced copy
  instead.
- **No user in `wheel` is a warning.** With immutable users and no root
  password, that machine has no way to sudo - including to fix it.
- `extraGroups`: `"wheel"` for sudo, `"adbusers"` for Android debugging.
- `packages`: `attrsOf bool`, keyed by a plain nixpkgs attribute path
  string (`"blender"`, `"nodePackages.pnpm"`) - what Vayume
  Settings' package search adds to, each entry individually
  toggleable. Deliberately narrower than `extraPackages` below (a
  string key instead of an actual package value) precisely so it *can*
  be driven by a search box - see
  [core-vayume-config.md](core-vayume-config.md) for why that
  distinction is what makes it safe to expose there at all. `false`
  disables an entry without forgetting it, unlike removing it from a
  plain list would. Resolved by splitting the string on `.` and walking
  `pkgs` with it (`resolvePackagePath`) - the same mechanism that lets a
  single flat key like `"nodePackages.pnpm"` reach a nested attribute
  the way writing `pkgs.nodePackages.pnpm` by hand would.
- `extraPackages`: a plain `listOf package` (`[ pkgs.gparted ]`) for
  anything a name-based search can't express - a package with build
  overrides, `pkgs.python3.withPackages (...)`, and the like. Nix-only,
  same reasoning as `avatar`/`shell` for staying out of the CLI/UI.
- The list of valid app names auto-discovers from every `.nix` file under
  `modules/apps/`, at any depth - add an app by dropping a folder in,
  nothing here needs to change.
- Every user's activation service waits for the network to come up
  first, generically - some app's activation script (ZenBrowser's mod/
  profile fetch, currently) needs it, and without this it can race the
  network interface coming up during boot.
- **`TimeoutStartSec = "180sec"`** - was `30sec`, found genuinely too
  tight by actually booting a VM from this config rather than trusting
  it would be fine: a full first-time activation (every app's `home.
  activation` script running for real - session-state symlinking,
  secrets syncing, matugen templates, DMS theme install, all of it,
  across two users) hit the old 30-second wall and both
  `home-manager-ash`/`home-manager-random` services were killed mid-run
  and marked failed, confirmed by checking what had and hadn't been
  written yet (`secrets.env` existed, `session/` symlinking hadn't even
  started). 180s gives real headroom for a heavy first run or a slow
  disk without weakening the point of having a timeout at all - a
  genuinely hung activation still gets caught, just not one that's
  simply taking a while.

**Also where secrets reach the apps that need them - no runtime file any
more, straight from `_config.nix`.** `home-manager.users`'s per-user module
sets `_module.args.vayumeSecrets = lib.recursiveUpdate defaultUserSecrets
u.secrets;` - a plain module argument, the exact same mechanism
`vayumeTheme`/`vayumeApps` already use via `extraSpecialArgs`, just
per-user instead of shared. Any app module that needs a secret just adds
`vayumeSecrets` to its own function signature and reads
`vayumeSecrets.WAKATIME_API_KEY` (etc.) directly - no file, no `jq`
lookup, no activation-ordering dance.

- **`lib.recursiveUpdate defaultUserSecrets u.secrets`, not a plain
  fallback swap.** Merges key-by-key, so setting only
  `secrets.WAKATIME_API_KEY` in `_config.nix` still leaves `RBW_EMAIL`
  resolving to its `"REPLACE_ME"` default instead of erroring on a
  missing attribute - every consumer can access `vayumeSecrets.<key>`
  unconditionally, always. This repo previously ran these through
  [sops-nix](https://github.com/Mic92/sops-nix) (age-encrypted at rest),
  then through a hand-rolled JSON file seeded once and edited by hand;
  both added a moving part (a keypair, or a second file to keep in
  sync) for values that aren't actually that sensitive (a time-tracking
  key, an email address) and already live in a file (`_config.nix`)
  that's gitignored and required on its own.
  ```nix
  # in _config.nix, per user
  secrets = {
    WAKATIME_API_KEY = "...";
    RBW_EMAIL = "...";
  };
  ```
  There used to be a third, open-ended `PROVIDERS` bag here too - API
  keys for the old Free Claude Code module's 17+ supported model
  providers. Gone along with that module: [cc-switch](apps-dev-ccswitch.md),
  its replacement, manages providers through its own UI and its own
  on-disk state, not through anything Nix-declared.
- **Read at build time, not activation time - the trade this made.**
  Every consumer (`crudini` for VS Code/Android Studio's WakaTime key,
  `jq`-merged JSON for Zed/rbw) gets its value baked in as a literal by
  Nix, since there's no runtime file left to read from. That means
  every value in `secrets` ends up sitting somewhere in `/nix/store` -
  world-readable on this machine, same as any other Nix-built config -
  which the old `secrets.json` design deliberately avoided. Acceptable
  for what's actually in here (see above); genuinely not the place for
  anything higher-stakes.
- **A missing secret disables the thing that needed it, instead of
  configuring it with a useless placeholder.** Every consumer checks
  `vayumeSecrets.<key> != "REPLACE_ME"` before doing anything: no real
  `WAKATIME_API_KEY` means the `wakatime` extension/plugin is left out
  of Zed's `extensions`, VS Code's `nixpkgsExtensions`, and Android
  Studio's `allManualPluginsSpec` entirely (not installed with a broken
  key - not installed at all), and the WakaTime-config activation script
  for whichever editor becomes a no-op (`lib.optionalString`). Same
  pattern for `RBW_EMAIL` - the `rbwEmail` activation script no-ops, so
  `rbw`'s config file is left alone rather than seeded with
  `"REPLACE_ME"` as an email. Checked directly: with no `secrets` block
  set at all, the built activation script has zero `WAKATIME_KEY=`/rbw-
  config lines, and VS Code's extensions manifest has no `wakatime`
  entry. Fill the value in in `_config.nix` and rebuild to turn it back
  on - takes effect immediately, no first-run-only seeding step to work
  around.

- **The 1-2 minute stall on the boot screen was this file's own
  `network-online.target` dependency.** `home-manager-<user>.service`
  had `after`/`wants` on `network-online.target` added here, with no
  note saying why. Home Manager's own NixOS module separately sets
  `before = [ "systemd-user-sessions.service" ]` (read straight from its
  `nixos/default.nix`), which is what gates login on activation
  finishing. Chain those together and login waits on
  `NetworkManager-wait-online` - routinely 30s to well over a minute on
  WiFi - before the greeter is even allowed to appear. Confirmed against
  the real generated unit, not inferred.

  Removed, after checking every network call activation actually makes:
  the only two are Zen's mods-index fetch and its per-mod downloads
  ([ZenBrowser.nix](apps-utils-zenbrowser.md)),
  both already `--max-time`-bounded and guarded so a failure prints
  "could not reach the mods index, skipping" and moves on. (The old Free
  Claude Code module's `git clone` used to be a real counterexample -
  handled by giving its own one-shot service its own
  `After=network-online.target` rather than letting activation wait on
  it - but that whole module is gone now along with the clone.)

  `TimeoutStartSec` stays at 180s deliberately. A *fresh* account still
  runs Zen's one-time `timeout 120s ... -CreateProfile`, so trimming the
  timeout would kill activation partway through a first login rather
  than speed anything up.

---

[← Vm.nix](core-vm.md) · [Index](CONFIGURATION.md) · [Theme.nix →](core-theme.md)
