[Index](CONFIGURATION.md)

---

One command instead of twenty-odd - every Vayume helper is a subcommand of `vayume`, with a menu for when you don't remember which.

## `modules/vayume/Commands.nix`

```bash
vayume                           # menu: type to filter, Enter to run
vayume help                      # every subcommand, one line each
vayume config apps list          # run one directly
vayume box1 install app.AppImage # "box1 install" and "box1-install" both work
```

Tab completion lists the subcommands with their descriptions.

**Modules register subcommands; nothing puts its own binary on
`PATH`.** A module sets

```nix
vayume.commands.zen-reload = {
  command = lib.getExe zen-reload;       # any executable
  description = "Restart Zen Browser ...";
  usage = "";                            # argument synopsis; "" = no arguments
  confirm = false;                       # true = the menu asks first
};
```

at the NixOS level (system-side helpers: `config`, `rebuild`, `gc`,
`tor`, `waydroid ...`, `check-plugin-updates`) or inside an app's Home
Manager module (`app-state`, `zen-reload`, `box<n> ...`). Each user's
`vayume` is generated from both, so a subcommand exists exactly when
the module (or app) that provides it is enabled - turn Distrobox off and
the `box` commands disappear from the menu and from completion.

Before this, every helper was its own `vayume-<name>` binary: 27 of
them in tab completion on a normal setup, most of them seven copies of
the same Distrobox verbs. The old names are gone rather than aliased -
keeping them would have kept the clutter this exists to remove.

**The menu** (`vayume` with no arguments, in a terminal) is `fzf` over
the same list `vayume help` prints. Picking a command that takes
arguments shows its usage and asks for them on a prompt with normal
line editing (quotes work, so paths with spaces are fine); `confirm`
commands - `gc`, the Waydroid reset - ask before running. Run without a
terminal, it prints the list instead of opening a menu.

**Names with a shared prefix are grouped.** A registered name like
`box1-install` is shown as `box1 install` when `box1` is itself a
command or more than one name shares the prefix, and the dispatcher
accepts either spelling: if `<first>-<second>` is a command it wins,
otherwise `<first>` is run with the rest as arguments.

**`vayume --has <name>`** exits 0 if the subcommand exists. The
keybind launchers use it (see [Hyprland.nix](desktop-hyprland.md)): the
Zen reload key tries `vayume zen-reload` only when Zen is enabled.

Things that call Vayume helpers by name - the Vayume Settings panel,
the Tor widget, the plugin-check zsh hook - call `vayume <subcommand>`
the same way you would. The one exception is Hyprland's type-clipboard
bind, which runs its script by store path: it's a keybind helper, not
something to type.

---

[← Config.nix](core-vayume-config.md) · [Index](CONFIGURATION.md) · [DevLanguages.nix →](core-devlanguages.md)
