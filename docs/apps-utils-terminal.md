[Index](CONFIGURATION.md)

---

kitty, zsh, and fastfetch - the first thing you see every time a shell opens.

## `modules/apps/utils/terminal/Terminal.nix`

Kitty + zsh (oh-my-zsh) + fastfetch + Starship + eza, one toggle. Fastfetch
picks a random logo out of `modules/apps/utils/terminal/images/` every
time you open a shell, and falls back to its own default if that folder
ever ends up empty.

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

---

[← StateBackup.nix](apps-utils-statebackup.md) · [Index](CONFIGURATION.md) · [Vesktop.nix →](apps-utils-vesktop.md)
