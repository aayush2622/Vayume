# Core & hosts reference

[← Back to index](CONFIGURATION.md)

---

## `modules/hosts/<name>/Host.nix`

**`vayori.theme`** is a submodule declared right here, not in a shared
file like `vayori.users`/`vayori.apps` - it's a per-host preference, and
there's only one host so far. Comes with sane defaults (JetBrainsMono
Nerd Font, Bibata-Modern-Ice, Tela-circle). Change one field without
touching the rest - `vayori.theme.font = "Fira Code";` and it updates
everywhere at once, since fontconfig, GTK, kitty, and DMS all read the
same option.

NixOS modules can read `config.vayori.theme.*` directly. Home-manager
modules can't - they run as a totally separate module tree that never
sees the parent config - so `Users.nix` hands it over explicitly via
`extraSpecialArgs`.

Not wired to `vayori.theme`, if you're wondering: the SDDM greeter's
bundled font and GRUB's own theme package. See
[Fonts.nix / Portals.nix](desktop.md#modulesdesktopfontsnix--portalsnix).

**Two Nix landmines hit while building this file, worth knowing about:**

1. A module can't mix `options.x = ...` with plain top-level config keys.
   Declare `options.vayori.theme` and suddenly everything else has to
   move under `config = { ... };`, or you get a cryptic `unsupported
   attribute 'boot'` error that gives you no hint why.
2. An inline lambda right after a path in a list doesn't parse the way
   you'd expect - it reads as a function call, not a second list item:

   ```nix
   modules = [
     ./_hardware.nix
     { pkgs, ... }: { ... }   # BROKEN — parses as `./_hardware.nix { pkgs, ... }`
   ];
   ```

   Wrap it in parens and it's fine: `({ pkgs, ... }: { ... })`.

**Store/build housekeeping**: `auto-optimise-store` hardlinks identical
files across store paths so they don't get stored twice.
`documentation.nixos.enable = false` skips building the local NixOS
manual (`man configuration.nix` still works fine, this just skips the
book). Garbage collection runs weekly, clearing anything older than 30
days, so `/nix/store` doesn't just grow forever waiting for someone to
remember `nix-collect-garbage`.

**Getting the login screen's cursor right took three separate fixes**,
none of them guesses - all traced through the actual source:

1. SDDM's Wayland greeter runs as its own systemd service under Weston,
   which never sees `environment.sessionVariables` - those only apply
   post-login, via PAM. Fix: set the same variables directly on the
   `display-manager.service` unit.
2. Even with that, Weston doesn't guarantee the greeter *client* actually
   inherits them. SDDM's own source re-applies a separate
   `GreeterEnvironment` setting on top - a comma-separated string, not
   the usual attrset shape, easy to get wrong the first time.
3. NixOS isn't FHS, so there's no `/usr/share/icons` for Xcursor to fall
   back to - `XCURSOR_PATH` has to be pointed at the actual package
   explicitly, and that package needs to be system-wide since SDDM runs
   before any user session exists to pull it in otherwise.

Small caveat: QEMU's screenshot tool doesn't reliably capture the
hardware cursor, so a screenshot with no visible cursor isn't proof
anything's actually broken.

**Apps** (`vayori.apps`) is the one setting most new machines actually
need to touch - just filenames under `modules/apps/`. Written here
grouped by category for readability, then flattened to a plain list
before anything downstream ever sees it - the option itself has no idea
the grouping exists, it's purely cosmetic at the call site.

**`programs.steam.enable`** lives here, not in
[Gaming.nix](apps-gaming.md#modulesappsgaminggamingnix) - see that page
for why.

**Users** (`vayori.users`) - **not set here any more.** It used to be a
plain block in this file, but that meant real usernames, group
memberships, and a password hash sat in git history the moment the repo
went public. It's set from `_user.nix` instead now - a gitignored sibling
of `_hardware.nix`, never committed, required (the build refuses to
evaluate without it). Full story in [core/Users.nix](#modulescoreusersnix)
below.

---

## `modules/hosts/<name>/_hardware.nix`

The one file in this repo that isn't a proper flake-parts module - no
`flake.nixosModules.X` wrapper, just a plain NixOS module. The leading
underscore keeps import-tree from trying anyway; it only ever gets pulled
in through `Host.nix`'s own `./_hardware.nix` import.

**Gitignored and required**, along with its sibling `_user.nix` (usernames,
groups, password hash, secrets - full shape under
[core/Users.nix](#modulescoreusersnix) below, mechanics shared with this
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
> ([Dms.nix](desktop.md#modulesdesktopdmsnix)'s `vayoriRebuildScript`)
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
[GrubTheme.nix](system.md#modulessystemgrubthemenix) and this module's
own upstream `qemu-vm.nix` machinery. Static config generation checks
don't catch that kind of thing - only an actual build (or boot) does.

---

## `modules/core/Users.nix`

The shared framework behind every `vayori.users.<name>` entry - what
fields exist, what they do, and (new) where the whole list actually
comes from now.

**`vayori.users` defaults to `{ }` here and gets its real value from
`_user.nix`**, a plain NixOS module living next to `Host.nix` (see
[_hardware.nix](#moduleshostsname_hardwarenix) above for the
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
  ([FreeClaudeCode.nix](apps-development.md#modulesappsdevelopmentfreeclaudecodefreeclaudecodenix))
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

---

## `modules/core/DevLanguages.nix`

Declares `flake.devLanguages` - same "publish data at `self`" pattern as
matugen templates and plugin pins - so language modules and editors
never have to know about each other directly. A language module has no
idea which editors exist; an editor has no idea which languages exist.
They just agree on what shape this data comes in.

- **What this actually fixes**: before this existed, `Vscode.nix` just
  hardcoded a Dart extension reference and `AndroidStudio.nix` hardcoded
  a Dart plugin reference, with zero connection to whether Dart tooling
  was even installed. Remove "Dart" as a concept and nothing changes in
  either editor. That mismatch - editors quietly carrying extensions for
  languages you don't even have a compiler for - is exactly what this
  file exists to close.
- **Every language folder sets two things**: a normal app
  (`flake.homeModules.apps.<Lang>`, installs the actual LSP + toolchain,
  toggled through `vayori.apps` like anything else) and pure data
  (`flake.devLanguages.<Lang>`, no packages, just what each editor should
  grab). The data has a loose conventional shape but nothing enforces
  it - an editor reads whichever keys it understands and ignores the
  rest, so adding a new editor, or a new field for one language, never
  requires touching every other file.
- **Editors do their own filtering.** The published data is unfiltered -
  it's flake-level, evaluated once, with no host to filter against yet.
  Each editor works out which languages are actually enabled on its own,
  right where `vayori.apps` is actually available, then folds in
  whatever each enabled language contributed. Turn a language off and
  its extensions disappear from every editor on the next rebuild -
  nothing to go update by hand.
- **Zed merges its settings with a deep merge, VS Code with a shallow
  one** - and that's not arbitrary. Zed nests language-adjacent settings
  under a couple of shared top-level keys, so two languages touching the
  same key need to survive together, not clobber each other. VS Code's
  settings happen to never collide this way today (every language uses
  its own distinct key), so a shallow merge is safe there for now - just
  not guaranteed to stay that way forever if a future language collides.
- **Extension names for VS Code are plain strings**
  (`"rust-lang.rust-analyzer"`), not direct package references - language
  modules don't have `pkgs` in scope at the point they publish this data.
  The string gets resolved inside VS Code's own module instead, and a
  typo throws loudly rather than silently installing nothing. That's
  exactly how a real bug got caught here: `fwcd.kotlin` isn't actually in
  nixpkgs' curated extension set (only a similarly-named one is), and the
  throw caught it during a real build, not during review.
- **Manually-pinned extensions/plugins still funnel through the editor's
  own pin list**, not a separate per-language one - the update-checker
  script only knows to look for `Vscode`/`AndroidStudio` by name, so
  anything else would just get silently skipped. Each editor gathers
  every enabled language's manual pins into its own list instead.
- **Dart and Flutter are one toggle, not two.** `pkgs.flutter` already
  bundles its own Dart SDK, and every real Dart project on this machine
  is a Flutter one anyway - splitting them never bought anything.

---

## `modules/core/PluginUpdateCheck.nix`

A read-only update reporter for VS Code, Android Studio, and Zen
Browser's pinned plugins/extensions - deliberately *not* Zed, which has
nothing to check: its extensions are just names Zed resolves and
installs itself at its own next startup, nothing pinned here to go
stale. This script never touches a pin itself, it just tells you what's
outdated so you can bump it by hand.

- **Where the pins actually come from**: each app file hoists its own
  pinned-plugin list into a shared `flake.pluginPins.<AppName>` spot -
  same pattern as matugen templates. The home-manager module just
  references that same binding, so nothing about what actually gets
  installed changed when this got refactored.
- **VS Code and Android Studio's pins get aggregated now**, not just
  hoisted - once language-specific extensions moved into their own
  files, each editor's pin list has to fold in every enabled language's
  manual pins on top of its own. Has to stay keyed by editor name, not
  split per-language, since the checker script only ever looks for those
  two specific names.
- **Keys match the app's real attribute name exactly** (`Vscode`, not
  `vscode`), so filtering down to "only what's actually enabled on this
  host" needs no translation table, just a straight name comparison.
- The filtered result lands at `/etc/vayori/plugin-pins.json`, system-wide
  rather than per-user, since `vayori.apps` itself is host-wide anyway.
- **Zen Browser's pins have nothing to version-check** - everything
  installs at whatever's currently latest, there's no pinned version to
  compare against. So for Zen this script checks *existence* instead: did
  the extension/mod get renamed or pulled entirely, not "is there a
  newer version."
- **The checker itself is a small, dependency-free Python script**, built
  straight into `$PATH` system-wide. No `requests`, just `urllib` and a
  thread pool so every check runs at once instead of one at a time.
  Right now that's 1 VS Code extension, 2 Android Studio plugins, 17 Zen
  extensions, and 8 Zen mods with anything actually pinned to check -
  everything sourced automatically from the marketplace/plugin-index
  inputs tracks upstream on its own with nothing here to go stale.
  - VS Code: one API call per extension to the Marketplace, comparing
    the pinned version against whatever's currently published.
  - Android Studio: JetBrains' modern REST API flatly rejects the string
    plugin IDs this repo actually stores (confirmed by trying it
    directly, not assumed) - so this uses the older XML-based endpoint
    instead, and picks "latest" by publish timestamp rather than
    comparing version strings, since some plugins mix versioning schemes
    across their history and a naive max would just pick the wrong one.
  - Comparisons are plain string inequality, not semver - these pins mix
    real semver, JetBrains build numbers, and prerelease suffixes, so
    "not equal to what's pinned" is the only honest thing to report.
  - Every network call fails quietly on its own - a timeout or DNS
    hiccup doesn't get reported as "outdated," it just gets skipped. If
    literally everything fails (fully offline), the cache doesn't get
    written at all, so the next run retries properly instead of going
    silent for a full day over a coincidental blip.
  - Results cache for 24 hours, so rebuilding twice in one day doesn't
    mean two rounds of network calls. Force a fresh check by setting
    `VAYORI_PLUGIN_CHECK_FORCE=1`.
  - Silent when there's nothing to report - it only ever speaks up when
    it's actually found something, so it's not noise on every build.
- **Wired in through a zsh hook**, not an alias, since aliases get
  skipped when a command's prefixed with `sudo`. The hook watches for
  rebuild-shaped commands and runs a quick, 10-second-capped check right
  before letting the real command through - so the only thing anyone
  ever has to do is run the normal rebuild command, and a slow or dead
  network adds at most 10 seconds, never more.
