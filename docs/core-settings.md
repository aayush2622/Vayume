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

`labels` is shorthand for `{ label = ...; }`. The full form also takes `group` (the card title) and `hidden`. Without an entry the label is the path with camel-case split into words (`network.dns.overTls` becomes "Dns over tls") and the group is the first segment. The labels for the shipped options live in `Settings.nix` itself, so a new module doesn't have to touch it unless it wants a nicer name.

### Where a write goes

`vayume config settings set <path> <value...>` edits `_config.nix` as one flat line, `vayume.<path> = <value>;`, replacing an existing flat line for that path or adding one before the closing brace. `settings reset <path>` deletes that line, so the option returns to its default. Then the same checks as every other edit apply: the file is evaluated, the option's own value is forced (so a wrong type or `ubuntuBox.count = 0` is rejected), and anything that fails is reverted - see [Config.nix](core-vayume-config.md) for the atomic-write and `--if-unmodified-since` details.

Two consequences worth knowing:

- **The option must be overridable.** Anything `Host.nix` sets for one of these options has to use `lib.mkDefault`, otherwise `_config.nix` and `Host.nix` define the same option and evaluation fails. The `vayume.network` block in `Host.nix` is written that way for this reason.
- **A value set inside a nested block wins the edit.** If you wrote `vayume.network = { tor.enable = true; };` by hand, the flat line the panel adds defines the same option a second time and evaluation fails; the edit is reverted and the error says so. The list marks a setting as "Set in _config.nix" only when it finds a flat `vayume.<path> =` line.

### Distrobox

`vayume.ubuntuBox.*` used to be a home-manager option, which the settings engine can't see. It's now declared at the NixOS level (`flake.nixosModules.DistroboxSettings`, imported by `Host.nix`) and the home-manager module reads it through `osConfig`, so it's set in `_config.nix` like everything else. Nothing changes for the commands; `homeDir` became `nullOr str` (`null` means `~/.local/share/vayume-boxes/<name>`) because its old default depended on a home-manager value that doesn't exist at the NixOS level.

### How the list is built

`_settings.nix` takes the evaluated flake and a host name, walks `nixosConfigurations.<host>.options.vayume`, classifies each option's type, and returns one record per option: `path`, `group`, `label`, `description` (first paragraph), `kind`, `nullable`, `choices`, `value`, `default`. `vayume config settings list` adds `configured`. Because it reads the option tree rather than a hand-kept table, it can't drift from the modules. `tests/eval.sh` covers both the edit paths and a throwaway option appearing with no other change.

---

[← Commands.nix](core-commands.md) · [Index](CONFIGURATION.md) · [DevLanguages.nix →](core-devlanguages.md)
