[Index](CONFIGURATION.md)

---

Who's allowed to log in, and what they're allowed to turn on - the framework the rest of the repo's per-user config all sits on top of.

## `modules/core/Users.nix`

The shared framework behind every `vayori.users.<name>` entry - what
fields exist, what they do, and (new) where the whole list actually
comes from now.

**`vayori.users` defaults to `{ }` here and gets its real value from
`_user.nix`**, a plain NixOS module living next to `Host.nix` (see
[_hardware.nix](core-hardware.md) above for the
gitignored/required/`path:` mechanics, shared with `_user.nix`). This used
to live directly in `Host.nix` - real usernames, group memberships, a
password hash, all committed to git. That's fine for a private repo,
genuinely not fine for a public one, so it moved out to its own file
that's never committed:

```nix
# modules/hosts/Diablo/_user.nix
{
  vayori.users = {
    ash = {
      fullName = "Ash";
      extraGroups = [ "networkmanager" "wheel" "video" "input" ];
      hashedPassword = "$6$...";
      secrets = {
        WAKATIME_API_KEY = "...";
        RBW_EMAIL = "...";
        PROVIDERS = { OPENROUTER_API_KEY = "..."; };
      };
    };

    random = {
      fullName = "Random";
      extraGroups = [ "networkmanager" "video" "input" ];
    };
  };
}
```

- **No fallback test user any more.** Earlier versions of this repo read
  an out-of-repo `/etc/vayori/config.json` at eval time and fell back to
  a single passwordless account if it didn't exist, so a fresh public
  clone could still evaluate with zero setup. That's gone: the build now
  hard-fails with a clear message (see above) instead of silently
  standing up an account nobody asked for - copy `_user.nix.example` and
  pick a real username before the first rebuild, every time.
- **Read at plain Nix module-evaluation time**, not through
  home-manager activation - it has to be, since NixOS needs to know who
  the users even are before any of their home directories, let alone
  home-manager, exist.
- **`secrets`, per user, optional**: passed to every app module as
  `vayoriSecrets` (see below) - missing keys, or the whole block, fall
  back to `"REPLACE_ME"` placeholders instead of erroring.
- **Plain Nix values, no encryption layer.** Fine, since `_user.nix` is
  gitignored and only ever readable by whoever already has read access
  to this checkout - see below for the one real trade-off this makes.

Field meanings:

- `hashedPassword`: generate with `mkpasswd -m sha-512`. Leave it unset
  (`null`) in `_user.nix` and you get `changeme` as a fallback initial
  password instead.
- `extraGroups`: `"wheel"` for sudo, `"adbusers"` for Android debugging.
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
more, straight from `_user.nix`.** `home-manager.users`'s per-user module
sets `_module.args.vayoriSecrets = lib.recursiveUpdate defaultUserSecrets
u.secrets;` - a plain module argument, the exact same mechanism
`vayoriTheme`/`vayoriApps` already use via `extraSpecialArgs`, just
per-user instead of shared. Any app module that needs a secret just adds
`vayoriSecrets` to its own function signature and reads
`vayoriSecrets.WAKATIME_API_KEY` (etc.) directly - no file, no `jq`
lookup, no activation-ordering dance.

- **`lib.recursiveUpdate defaultUserSecrets u.secrets`, not a plain
  fallback swap.** Merges key-by-key, so setting only
  `secrets.WAKATIME_API_KEY` in `_user.nix` still leaves `RBW_EMAIL` and
  `PROVIDERS.NVIDIA_NIM_API_KEY` resolving to their `"REPLACE_ME"`
  defaults instead of erroring on a missing attribute - every consumer
  can access `vayoriSecrets.<key>` unconditionally, always. This repo
  previously ran these through
  [sops-nix](https://github.com/Mic92/sops-nix) (age-encrypted at rest),
  then through a hand-rolled JSON file seeded once and edited by hand;
  both added a moving part (a keypair, or a second file to keep in
  sync) for values that aren't actually that sensitive (a proxy token, a
  time-tracking key, an email address) and already live in a file
  (`_user.nix`) that's gitignored and required on its own.
  ```nix
  # in _user.nix, per user
  secrets = {
    WAKATIME_API_KEY = "...";
    RBW_EMAIL = "...";
    PROVIDERS = {
      NVIDIA_NIM_API_KEY = "...";
    };
  };
  ```
- **`PROVIDERS` is open-ended, on purpose - this is the actual answer to
  "where do I put a second/third/Nth API key."** Free Claude Code
  ([FreeClaudeCode.nix](apps-dev-freeclaudecode.md))
  proxies to whichever provider `MODEL` names, and each provider it
  supports (17+, per its own docs) just needs its own correctly-named
  key - `OPENROUTER_API_KEY`, `DEEPSEEK_API_KEY`, `GROQ_API_KEY`,
  whatever matches the provider prefix in `MODEL`, straight from
  upstream's own naming, not something this repo invents. Add as many
  as you want directly to `PROVIDERS` in `_user.nix` - `FreeClaudeCode.nix`
  filters out any entry still equal to `"REPLACE_ME"`
  (`lib.filterAttrs`), builds a flat `KEY=value` file from whatever's
  left at eval time, and merges it into `.fcc/.env` on every activation,
  replacing only matching keys - so it's genuinely N real keys, not
  three hardcoded ones, and a provider nobody's set a key for never gets
  written at all.
- **Read at build time, not activation time - the trade this made.**
  Every consumer (`crudini` for VS Code/Android Studio's WakaTime key,
  `jq`-merged JSON for Zed/rbw, the `PROVIDERS` loop above for Free
  Claude Code) gets its value baked in as a literal by Nix, since
  there's no runtime file left to read from. That means every value in
  `secrets` ends up sitting somewhere in `/nix/store` - world-readable
  on this machine, same as any other Nix-built config - which the old
  `secrets.json` design deliberately avoided. Acceptable for what's
  actually in here (see above); genuinely not the place for anything
  higher-stakes.
- **A missing secret disables the thing that needed it, instead of
  configuring it with a useless placeholder.** Every consumer checks
  `vayoriSecrets.<key> != "REPLACE_ME"` before doing anything: no real
  `WAKATIME_API_KEY` means the `wakatime` extension/plugin is left out
  of Zed's `extensions`, VS Code's `nixpkgsExtensions`, and Android
  Studio's `allManualPluginsSpec` entirely (not installed with a broken
  key - not installed at all), and the WakaTime-config activation script
  for whichever editor becomes a no-op (`lib.optionalString`). Same
  pattern for `RBW_EMAIL` (the `rbwEmail` activation script no-ops, so
  `rbw`'s config file is left alone rather than seeded with
  `"REPLACE_ME"` as an email) and each `PROVIDERS` entry individually
  (filtered out above, so a provider `MODEL` never actually points at
  doesn't clutter `.fcc/.env` with a key that would just fail auth).
  Checked directly: with no `secrets` block set at all, the built
  activation script has zero `WAKATIME_KEY=`/rbw-config lines and
  `fcc-providers.env` comes out as an empty file, and VS Code's
  extensions manifest has no `wakatime` entry. Fill the value in in
  `_user.nix` and rebuild to turn it back on - takes effect immediately,
  no first-run-only seeding step to work around.

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
  "could not reach the mods index, skipping" and moves on. Free Claude
  Code's `git clone` looks like a counterexample but isn't - it lives in
  `fccBootstrapScript`, run by `free-claude-code-bootstrap.service`,
  which carries its own `After=network-online.target`. That's the right
  place for a network dependency: a real service that can take its time,
  not the activation the login prompt is queued behind.

  `TimeoutStartSec` stays at 180s deliberately. A *fresh* account still
  runs Zen's one-time `timeout 120s ... -CreateProfile`, so trimming the
  timeout would kill activation partway through a first login rather
  than speed anything up.

---

[← Vm.nix](core-vm.md) · [Index](CONFIGURATION.md) · [DevLanguages.nix →](core-devlanguages.md)
