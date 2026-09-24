[Index](CONFIGURATION.md)

---

One place that owns how zsh is set up: completion, keybindings, and the plugins with the order and settings that make them work together. The Terminal app turns it on; other modules can add to it. oh-my-zsh is not used - none of its plugins were.

## `modules/vayume/Zsh.nix`

`vayume.zsh.enable` (set by the Terminal app) makes the module generate one ordered `.zshrc` fragment from three things: the built-in core configuration, `vayume.zsh.plugins`, and `vayume.zsh.snippets`. Plugins and snippets share one stream sorted by `order`, lowest first:

| Order | What |
| --- | --- |
| 50 | core: options, completion styles, keybindings |
| 100-499 | early plugins (`zsh-256color`, 100) |
| 500-899 | normal plugins (`zsh-autosuggestions` 500, `you-should-use` 600) |
| 1000 | `zsh-syntax-highlighting` - must be last of the plugins |
| 1500 | hooks that need the plugins loaded (the plugin-update check) |
| 2000+ | things that run last (the fastfetch greeting) |

### Why the order matters

- **`zsh-syntax-highlighting` wraps the widgets that exist when it loads**, so anything loaded after it is not highlighted. The module refuses to build if any plugin has a higher order than it: `vayume.zsh: zsh-syntax-highlighting must have the highest order of all plugins`. `tests/eval.sh` checks that this fires.
- **The core keybindings load before every plugin**, so autosuggestions and highlighting wrap the final widgets rather than ones that get replaced later.
- **The greeting runs after everything**, so the prompt and hooks are ready when it prints.

### How the plugins are configured to work together

- **Autosuggestions** use history then completion, are dimmed with `fg=8` (the terminal's bright black, which the matugen palette themes), skip buffers longer than 40 characters, and accept with `End`, `Right`, or `Ctrl+Space`. `forward-word` is registered as a partial-accept widget, so `Ctrl+Right` takes one word of the suggestion - the same key that moves by word elsewhere.
- **Syntax highlighting** uses the `main` and `brackets` highlighters only, stops highlighting after 300 characters (a large paste otherwise stalls the line), and dims comments.
- **`you-should-use`** prints its reminder after the command's output (`YSU_MESSAGE_POSITION="after"`) instead of before it, so it doesn't push output around or fight the autosuggestion for the same line.
- **`zsh-256color`** loads first; it only rewrites `$TERM` for terminals that report a plain `xterm`/`screen`, so it does nothing under kitty.

### Core configuration

- **Completion:** one `compinit`, cached with `-C`, with the dump in `~/.cache/zsh/` rebuilt when it is more than a day old. Menu selection, case-insensitive and partial-word matching, `LS_COLORS` in the list, grouped and titled results, and a completion cache. NixOS's global `compinit` is switched off (`programs.zsh.enableGlobalCompInit`, in [Users.nix](core-users.md)) because it ran uncached in every shell; `/etc/zshenv` still sets up the completion paths. A completion for a package installed less than a day ago can be missing until the dump is rebuilt - delete `~/.cache/zsh/zcompdump-*`.
- **Keybindings** come from the terminfo entry: Home, End, Insert, Delete, PageUp/Down, Shift+Tab (back through menu completion), Up/Down search history by the text already typed, `Ctrl+Left/Right` move by word, `Ctrl+Backspace` and `Ctrl+Delete` delete by word. Application mode is switched on while the line editor is active so the terminfo codes match. The plain `^[[A`-style arrow sequences are also bound, so history search works when the terminal isn't in application mode.
- **History:** 50000 entries, no duplicates, shared between shells, with timestamps.
- **Options:** interactive comments, complete in word, cursor to end after completion, no bell, no flow control.

### Adding a plugin

```nix
vayume.zsh.plugins.zsh-completions = {
  src = inputs.zsh-completions;
  order = 300;
  completions = "src";
};
```

`file` defaults to `<name>.plugin.zsh`; `init` runs before the plugin is sourced (configuration variables), `post` after (bindings that need its widgets). The plugin is sourced straight from the Nix store - there is no copy under `~/.zsh`. Give it an order below 1000 so the highlighting assertion holds. To change a shipped plugin's settings, assign its `init` or `post` from another module; they are ordinary options.

### Adding a fragment

```nix
vayume.zsh.snippets.my-hook = {
  order = 1500;
  text = ''
    add-zsh-hook precmd my_function
  '';
};
```

The Terminal app registers two this way: the plugin-update check (1500) and the greeting (2000).

## Measured

Interactive `zsh -i -c exit`, warm, on this machine: about 0.13 s, against about 0.39 s before the rewrite (three `compinit` calls, oh-my-zsh, and autosuggestions loaded twice). Checked in a real interactive shell: all four plugins load, the keybindings and plugin options above are set, git completion works, and the completion dump is created once. Not checked: behaviour inside a live kitty window.

---

[← Settings.nix](core-settings.md) · [Index](CONFIGURATION.md) · [DevLanguages.nix →](core-devlanguages.md)
