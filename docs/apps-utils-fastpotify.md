[Index](CONFIGURATION.md)

---

A second Spotify client, next to Spicetify - not a replacement for it, a completely different tradeoff.

## `modules/apps/utils/fastpotify/Fastpotify.nix`

- **Not built from source here - pulled in as its own flake.**
  [Fastpotify](https://fastpotify.rocks/) already ships a working
  `flake.nix` with everything the build needs (Rust, cmake, bindgen for
  the MilkDrop visualizer's C++ bindings, the runtime `LD_LIBRARY_PATH`
  wrapping for its dlopen'd Wayland/X11/GL libraries) - re-deriving that
  by hand would just be a worse copy of what upstream already maintains.
  Added as a flake input the same way `zen-browser` and `spicetify-nix`
  are, and locked the same way (`nix flake lock`, not hand-edited).
- **Pinned to a fork's branch, not upstream.** The input points at
  `github:dim-ghub/fastpotify-theming/astra-redesign` specifically -
  that's the exact ref this was asked for, and updating it later means
  `nix flake lock --update-input fastpotify`, same as any other input.
- **It's genuinely not Spicetify.** Spicetify patches the real, official
  Spotify Electron app to reskin and extend it - you get actual Spotify
  with a theme on top. Fastpotify is a from-scratch native client
  (Rust + egui, playback through librespot) that never runs Electron at
  all, at a fraction of the memory. Trading Spotify's own UI/extension
  ecosystem for speed is the whole point, not a bug - so both are worth
  having on for different moods rather than picking one.
- **`x-scheme-handler/spotify` is explicitly claimed, not left to
  chance.** Fastpotify's own `.desktop` file declares
  `MimeType=x-scheme-handler/spotify`, which only makes it a *candidate*
  handler - without an explicit default, opening a shared Spotify link
  (or the browser handing off an `open.spotify.com` address) has nothing
  to fall back on. `xdg.mimeApps.defaultApplications` sets it as the
  actual default here, the same fix this session applied to
  [Thunar.nix](apps-utils-thunar.md) for `inode/directory` - and the
  same landmine applies: `xdg.mimeApps.enable` defaults to `false` in
  home-manager and has to be set explicitly, or the whole block is
  silently inert.
- **Matugen drives it through a hook Fastpotify already had, not
  through the `~/.config/fastpotify/schemes/` custom-scheme feature
  its README advertises.** That feature (pick a named scheme in
  Settings, reload it with `Ctrl+Shift+R`) is a different subsystem,
  and it's a shakier thing to build on than it looks: the equivalent
  upstream work for it
  ([crmne/fastpotify#171](https://github.com/crmne/fastpotify/pull/171))
  was closed by the maintainer without merging - "we are not ready to
  commit to a theme file format and reload API yet." Instead, this
  targets `~/.local/state/caelestia/scheme.json` - a *different*,
  older mechanism already in this fork, unrelated to that PR. Caelestia
  is a separate wallpaper-theming project this repo doesn't run;
  Fastpotify just reads its file format as a ready-made theming
  interface, and `ThemeChoice::Caelestia` happens to be Fastpotify's
  own default, so nothing needs enabling on its side.
- **Genuinely live, confirmed by reading the source, not assumed.**
  `apply_theme()` re-checks that file's mtime on every UI frame, and
  the app already schedules a repaint every 60-300ms for unrelated
  reasons (toasts, search debounce, remote polling) - so the check
  fires several times a second even at idle. No post_hook, no
  live-reload script, no restart: the window repaints with the new
  palette within a frame of matugen finishing, the same as it would if
  Fastpotify shipped a file-watcher for this on purpose.
- **This is fork-specific behaviour, not a stable public API.** It
  works because this exact fork happens to carry it, not because
  upstream has committed to keeping it - the maintainer's own comments
  on #171 point toward a redesigned, currently-undecided theme format
  for whatever ships officially. Worth knowing before leaning on this
  further, and worth re-checking after any `--update-input fastpotify`.

---

[← Spicetify.nix](apps-utils-spicetify.md) · [Index](CONFIGURATION.md) · [Nautilus.nix →](apps-utils-nautilus.md)
