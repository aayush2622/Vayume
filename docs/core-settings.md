[Index](CONFIGURATION.md)

---

Every option a Vayume module declares shows up in Vayume Settings without anyone maintaining a list. The **All Settings** page and `vayume config settings` read the option declarations straight out of the evaluated system, so adding a setting is adding an option - nothing else.

## `modules/vayume/Settings.nix`, `_settings.nix`, `_setting.awk`

### What appears

Every `lib.mkOption` under `vayume.*` whose type the panel can edit:

| Type | Control | Written as |
| --- | --- | --- |
| `bool` | toggle | `true` / `false` |
| `int` (any of the int types) | number field | `4` |
| `str`, `lines` | text field | `"text"` |
| `enum` | dropdown | `"choice"` |
| `nullOr` of any of those | same control, plus a "Default" entry | `null` is never written; Reset removes the line |
| `listOf str`, `listOf enum` | space-separated text field | `[ "a" "b" ]` |

Left out on purpose: read-only and `internal` options, options with `visible = false`, anything with `settingsMeta.<path>.hidden = true`, types the panel can't edit safely (submodules, `attrsOf`, lists of anything but strings), and the subtrees that already have a page of their own - `apps`, `theme`, `defaultApps`, `users` - plus `commands`, `defaultAppsResolved` and `settingsMeta` themselves. Those stay editable in `_config.nix` by hand.

### Adding a setting

1. Declare the option in your module, with a `description`:

   ```nix
   options.vayume.audio.lowLatency = lib.mkOption {
     type = lib.types.bool;
     default = false;
     description = "Use a smaller PipeWire quantum.";
   };
   ```

2. Use `config.vayume.audio.lowLatency` wherever it's read.
3. Nothing else. It appears under an "Audio" card as "Low latency", with the first paragraph of the description underneath, and `vayume config settings set audio.lowLatency true` works.

Optional presentation overrides go in `vayume.settingsMeta`, keyed by the option path below `vayume.`:

```nix
vayume.settingsMeta = self.vayumeLib.labels {
  "audio.lowLatency" = "Low-latency audio";
};
```

`labels` is shorthand for `{ label = ...; }`. The full form also takes `group` (the card title), `icon` (a Material Symbols name) and `hidden`. A group's own icon and one-line description come from `vayume.settingsGroups.<group name> = { icon = ...; description = ...; };`. With no icon the row uses one for its type. Without an entry the label is the path with camel-case split into words (`network.dns.overTls` becomes "Dns over tls") and the group is the first segment. The labels for the shipped options live in `Settings.nix` itself, so a new module doesn't have to touch it unless it wants a nicer name.

### No Nix evaluation on load or save

Evaluating the option tree takes a few seconds per call, so the panel never does it. Instead:

- **At rebuild time** the `Settings` module writes `/etc/vayume/settings.json`: one record per option with its label, group, icon, type, choices, the value the running system has (`value`), what the option would be without `_config.nix` (`base`), and its declared `default`.
- **`vayume config settings list`** reads that file and overlays the flat `vayume.<path> = ...;` lines currently in `_config.nix` (a small `awk` finds them, `jq` parses the literals). Each record gains `configured` (there is a line), `applied` (what is running), `value` (what will be running after a rebuild) and `pending` (they differ). It takes about 60 ms. If the snapshot doesn't exist yet - before the first rebuild after adding this module - it falls back to evaluating the flake once.
- **`settings set` / `settings reset`** check the value against the record (kind, enum choices, and `min` for positive or unsigned ints), rewrite the file atomically, and run `nix-instantiate --parse` on the result so a syntactically broken file is never written. That is about 100 ms. Nothing is evaluated, so an option that is valid in type but rejected by an assertion or another module is only caught by the rebuild - which evaluates everything - and the rebuild leaves the running system alone if it fails. Reset removes the line again.

The snapshot is the reason a brand-new option appears only after the next rebuild: until then the running system doesn't know about it.

`VAYUME_SETTINGS_SNAPSHOT` overrides the snapshot path; `tests/eval.sh` uses it so a test run never reads the host's real one.

### Where a write goes

`vayume config settings set <path> <value...>` edits `_config.nix` as one flat line, `vayume.<path> = <value>;`, replacing an existing flat line for that path (multi-line ones included) or adding one before the closing brace. `settings reset <path>` deletes that line, so the option returns to its `base`. See [Config.nix](core-vayume-config.md) for the atomic-write and `--if-unmodified-since` details.

Two consequences worth knowing:

- **The option must be overridable.** Anything `Host.nix` sets for one of these options has to use `lib.mkDefault`, otherwise `_config.nix` and `Host.nix` define the same option and the rebuild fails. The `vayume.network` block in `Host.nix` is written that way for this reason.
- **A value set inside a nested block wins.** If you wrote `vayume.network = { tor.enable = true; };` by hand, the flat line the panel adds defines the same option a second time and the rebuild fails with a "defined multiple times" error. The list marks a setting as customized only when it finds a flat `vayume.<path> =` line, and shows a note if that line is a multi-line expression it can't display.

### Distrobox

`vayume.ubuntuBox.*` used to be a home-manager option, which the settings engine can't see. It's now declared at the NixOS level (`flake.nixosModules.DistroboxSettings`, imported by `Host.nix`) and the home-manager module reads it through `osConfig`, so it's set in `_config.nix` like everything else. Nothing changes for the commands; `homeDir` became `nullOr str` (`null` means `~/.local/share/vayume-boxes/<name>`) because its old default depended on a home-manager value that doesn't exist at the NixOS level.

### How the list is built

`_settings.nix` is a function of `lib`, `options` and `config`. The `Settings` module calls it with the system's own, so it runs during the rebuild; the fallback and the tests call it with a host's evaluated options. It walks `options.vayume`, classifies each option's type, and returns one record per option: `path`, `group`, `groupIcon`, `groupDescription`, `label`, `icon`, `description` (first paragraph), `kind`, `nullable`, `choices`, `min`, `value`, `base`, `default`. `vayume config settings list` adds `applied`, `configured`, `pending`. Because it reads the option tree rather than a hand-kept table, it can't drift from the modules. `tests/eval.sh` covers both the edit paths and a throwaway option appearing with no other change.

---

[← Commands.nix](core-commands.md) · [Index](CONFIGURATION.md) · [DevLanguages.nix →](core-devlanguages.md)
