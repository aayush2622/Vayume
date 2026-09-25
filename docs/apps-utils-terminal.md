[Index](CONFIGURATION.md)

---

kitty, zsh, and fastfetch - the first thing you see every time a shell opens.

## `modules/apps/utils/terminal/Terminal.nix`

Kitty + zsh (set up by [Zsh.nix](core-zsh.md)) + fastfetch + Starship + eza, one toggle. Fastfetch picks a random
logo out of `modules/apps/utils/terminal/images/` when a kitty window opens,
and falls back to its own default if that folder ever ends up empty.

- **zsh is configured by its own module, not here.** Completion, keybindings and the plugin list (with the order and settings that make them work together) live in [Zsh.nix](core-zsh.md); this module only switches it on and registers the two things that are about the terminal - the fastfetch greeting and the plugin-update hook. oh-my-zsh is not used: none of its plugins were, so it, and the git aliases and `sudo` widget that stood in for them for a while, are gone. Startup is about 0.13 s, down from about 0.39 s, mostly because `compinit` used to run three times and `zsh-autosuggestions` was loaded twice.
- **Fastfetch went from about 160 ms to about 20 ms.** The `Packages` module alone cost about 125 ms (it queries the Nix database) and is no longer shown; the window-manager module (66 ms) is replaced by reading `XDG_SESSION_DESKTOP`; and the logo is drawn with `--logo-type kitty-direct` (kitty reads the file itself) instead of `kitten icat`, which starts Python. The layout was also broken: the "boxes" had a top and bottom rule but no sides, keys were not aligned, `Driver` repeated the GPU, `Chassis` printed a junk `1.0` version, and the user line had a stray glyph. Now it is one aligned block (`display.key.width = 13`, wide enough for a Nerd Font icon, a space and the longest key, `Terminal`; built-in icons via `key.type = "both"`), a rule under `user@host`, and `Host`, `Kernel`, `Uptime`, `Shell`, `Terminal`, `WM`, `Display`, then `CPU`, `GPU` (vendor, name, driver), `Memory`, `Swap`, `Disk` (with filesystem), `Battery`. Icons are Nerd Font glyphs: kitty bundles its own symbol fallback so they render there; another terminal needs a Nerd Font.
- **Fastfetch is framed again, with the original key colors.** Two boxes (the system block, then the hardware block) with the `user@host` title and a rule above and the color dots below; the rules are `custom` modules, 64 characters wide, sized to the longest line (the CPU), in the normal text color. There is no right-hand border, since fastfetch can't align one to lines of different length. Only the keys are colored, as in the original config: `red` for OS, Kernel and Disk, `cyan` for Host, `yellow` for Uptime, Shell, Terminal and WM, `green` for Display and Battery, `blue` for CPU and GPU, `magenta` for Memory and Swap. They are ANSI names, which kitty resolves through the matugen-generated `dank-theme.conf`, so they retint with the wallpaper. Coloring the values and the rules too was tried and looked worse; `bright_black` rules were near-invisible against the background. Note that in the current palette `magenta` is a dark blue (`#244f70`); change `keyed "magenta"` in `Terminal.nix` if Memory and Swap are hard to read.
- **The box rules follow the widest row.** fastfetch can't measure its own output, so the greeting does it in two passes (`vayume_fastfetch` in the zsh snippet, about 20 ms extra, once per kitty window): it renders once with colors on and no logo, reads each row's width from the `ESC[13G` column escape (the value starts at column 13, so a row is 12 plus the length of its value), takes the maximum, then copies the config to a temporary `.jsonc` in `$XDG_RUNTIME_DIR` with the rule's dash run replaced by one that long, renders for real, and deletes the copy. The static config has 52 dashes, which is what plain `fastfetch` from a shell uses. If the measurement fails (no runtime dir, unreadable config) it falls back to the static width. The temporary file needs the `.jsonc` suffix or fastfetch reports the config as not found. **The measuring pass must run in its own session** (`setsid -w timeout 3 fastfetch ... </dev/null`): as a background job it otherwise queries the terminal through `/dev/tty`, the kernel stops it with SIGTTIN, and the shell then waits forever on its pipe, leaving an empty kitty window. That only happens under a real terminal emulator - a pseudo-terminal with nothing answering (which is what the tests use) does not trigger it - so the test only checks that the wrapper is present. If the measurement times out it falls back to the static width.
- **The CPU line shows just the model name.** fastfetch's own CPU module prints the marketing name (`13th Gen Intel(R) Core(TM) i5-13500H`) plus core count and clock, which pushed the line past the right edge of the box. `cpuLine` in `Terminal.nix` reads the model from `/proc/cpuinfo` and drops `(R)`, `(TM)`, the generation prefix and trailing `CPU`/`N-Core Processor`: `Intel Core i5-13500H`. It is a `command` module, so it has an explicit icon.
- **GPU lines are shortened the same way.** `gpuLine` in `Terminal.nix` reads the names from `fastfetch --structure gpu --format json` and drops the size, `Laptop GPU` and `Graphics`, so `NVIDIA GeForce RTX 3050 4GB Laptop GPU` becomes `GeForce RTX 3050` and the integrated one `Iris Xe`, on `GPU` and `iGPU` lines. Vendor, driver and discrete/integrated tags are no longer printed.
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
