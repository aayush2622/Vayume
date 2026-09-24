[Index](CONFIGURATION.md)

---

kitty, zsh, and fastfetch - the first thing you see every time a shell opens.

## `modules/apps/utils/terminal/Terminal.nix`

Kitty + zsh (set up by [Zsh.nix](core-zsh.md)) + fastfetch + Starship + eza, one toggle. Fastfetch picks a random
logo out of `modules/apps/utils/terminal/images/` when a kitty window opens,
and falls back to its own default if that folder ever ends up empty.

- **zsh is configured by its own module, not here.** Completion, keybindings and the plugin list (with the order and settings that make them work together) live in [Zsh.nix](core-zsh.md); this module only switches it on and registers the two things that are about the terminal - the fastfetch greeting and the plugin-update hook. oh-my-zsh is not used: none of its plugins were, so it, and the git aliases and `sudo` widget that stood in for them for a while, are gone. Startup is about 0.13 s, down from about 0.39 s, mostly because `compinit` used to run three times and `zsh-autosuggestions` was loaded twice.
- **Fastfetch went from about 160 ms to about 20 ms.** The `Packages` module alone cost about 125 ms (it queries the Nix database) and is no longer shown; the window-manager module (66 ms) is replaced by reading `XDG_SESSION_DESKTOP`; and the logo is drawn with `--logo-type kitty-direct` (kitty reads the file itself) instead of `kitten icat`, which starts Python. The layout was also broken: the "boxes" had a top and bottom rule but no sides, keys were not aligned, `Driver` repeated the GPU, `Chassis` printed a junk `1.0` version, and the user line had a stray glyph. Now it is one aligned block (`display.key.width`, built-in icons via `key.type = "both"`), a rule under `user@host`, and `Host`, `Kernel`, `Uptime`, `Shell`, `Terminal`, `WM`, `Display`, then `CPU`, `GPU` (vendor, name, driver), `Memory`, `Swap`, `Disk` (with filesystem), `Battery`. Icons are Nerd Font glyphs: kitty bundles its own symbol fallback so they render there; another terminal needs a Nerd Font.
- **The logo is 26 columns wide, with the height derived from each image.** It was a fixed 32x16 box, which stretched any image that isn't square (one of the shipped ones is 720x844). The greeting reads the PNG header (width and height, about a millisecond) and sets the rows from the aspect ratio, assuming a cell twice as tall as it is wide, clamped to 6 to 18 rows: square images get 13 rows, the portrait one 15. A file that isn't a PNG gets 13. To change the size, edit `cols` in the greeting in `Terminal.nix`.
- **The greeting runs only in kitty, once per window.** It used to run in every interactive shell, so VS Code's terminal, a plain `zsh` inside a shell, and Distrobox all printed an image escape sequence as garbage. It now requires `KITTY_WINDOW_ID`, and marks the window with `VAYUME_GREETED=<kitty pid>-<window id>` so a child shell in the same window skips it.
- **The plugin-update hook no longer blocks every Nix command.** It ran `vayume check-plugin-updates` for up to 10 s before each `nix build`/`run`/`flake`/`nixos-rebuild`. It now runs at most once every 6 hours (a stamp under `~/.local/state/vayume/`).
- **Starship** got a command timeout (300 ms) and scan timeout (30 ms) so a slow repository can't stall the prompt, a Nix-shell indicator, a branch glyph, a duration glyph, and `…/` truncation.
- **Kitty** now has 20000 lines of scrollback, no audio bell, copy-on-select, smart trailing-space stripping, curly URL underlines, `repaint_delay 8`/`input_delay 1`/`sync_to_monitor` for lower latency, ligatures off under the cursor, remote control off, and a rounded powerline tab bar that only appears with two or more tabs (it was always visible with one). `ctrl+shift+enter` and `ctrl+shift+t` open a window or tab in the current directory.

- **The logo picker used to `find` the images folder fresh on every
  single new shell**, piped through `shuf` - two subprocesses and a real
  filesystem walk paid on every terminal open for a folder that's
  entirely static within the flake. Now it's a plain bash array, baked
  in at build time (`fastfetchImagePaths`, computed once from
  `builtins.readDir`) - same "pick a random one" behavior, same set of
  images, just an array index instead of a filesystem scan. Checked the
  real generated `.zshrc` directly to confirm all the actual image paths
  ended up baked in correctly, not just that the Nix side evaluated.
- **Starship replaced a hand-rolled prompt.** The old one was a manual
  `precmd` hook that could only show the current branch - no dirty/staged/
  ahead-behind state, nothing. Starship fully owns prompt rendering once
  enabled, so the old code got deleted rather than left fighting it for
  the prompt.
- **eza replaces `ls` outright** via zsh integration (`ls`/`la`/`ll`/
  `lla`/`lt` all get aliased automatically) - the goal was a better `ls`,
  not a second tool to remember on top of it.
- **btop gets an actual theme now.** It used to just be an unconfigured
  package. Now it's told to look for a theme literally called `matugen`,
  which gets rewritten to match the wallpaper on every change - through a
  plain file, deliberately *not* home-manager's own theme option, since
  that option writes an immutable file and would just fight matugen for
  control of it. Same class of problem this repo already solved for GTK,
  Qt, and Android Studio.
- **cava** gets the same treatment, minus the "theme vs settings" split
  btop has - it only has the one config file, so matugen just owns it
  outright and cava fills in every other setting with its own built-in
  defaults.
- **Spicetify and Starship were skipped when wiring up matugen
  everywhere else**, on purpose - both are hand-extracted, curated
  configs from the real machine, not generic templates, and there's no
  clean way to splice in a dynamic palette without undoing the actual
  point of extracting them "as they really are." Covering every possible
  app with matugen was never the goal; not clobbering deliberately-tuned
  settings mattered more.

- **`background_opacity`/`dynamic_background_opacity`** are what
  actually make kitty's background blur nicely under Hyprland -
  see [Hyprland.nix](desktop-hyprland.md) for why this, specifically,
  is the right tool (a per-app translucent background with the app's
  own text staying fully opaque) versus Hyprland's own window opacity
  (a single whole-surface multiplier that dims text along with
  everything else).

---

[← StateBackup.nix](apps-utils-statebackup.md) · [Index](CONFIGURATION.md) · [Vesktop.nix →](apps-utils-vesktop.md)
