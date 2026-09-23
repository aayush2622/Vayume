[Index](CONFIGURATION.md)

---

A second Spotify client, next to Spicetify - not a replacement for it, a completely different tradeoff.

## `modules/apps/utils/fastpotify/Fastpotify.nix`

- **Installed from the upstream release binary, not built from source.**
  [Spotifast](https://spotifast.rocks/) (formerly Fastpotify) publishes a
  prebuilt `x86_64-unknown-linux-gnu` tarball with every release, so the
  module fetches that (`fetchurl` with a pinned hash) and lets
  `autoPatchelfHook` fix up the ELF, instead of compiling the Rust + C++
  (MilkDrop) tree. The linked libraries (`alsa-lib`, `libpulseaudio`,
  libstdc++) are build inputs; the GUI `dlopen`s dbus, Wayland, xkbcommon,
  X11 and GL at run time, so those go in `runtimeDependencies`, with dbus
  taken from its `lib` output (the default output has no `libdbus`). The
  tarball's `spotifast-portable.txt` marker is deliberately not installed -
  it would switch the app to portable storage. `fastpotify` stays as a
  symlink for old scripts. Updating means bumping `version` and the hash.
  It used to be a flake input; that input and its `rust-overlay` are gone.
- **The 0.9.1 rename moves your profile, and it must be allowed to.** On its
  first normal launch Spotifast renames `~/.config/fastpotify`,
  `~/.local/share/fastpotify` and `~/.cache/fastpotify` to `spotifast` and
  moves saved sign-ins to a new credential-store entry. It never merges
  into or overwrites a destination that already exists, so **nothing may
  create `~/.config/spotifast` before that first launch** - which is why the
  matugen theme output and the settings seed still point at the old
  `fastpotify` folder until the app has migrated once. After that first
  launch, switch both to `spotifast`. MPRIS is now
  `org.mpris.MediaPlayer2.spotifast`, so `playerctl --player=fastpotify`
  bindings need updating.
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
- **A custom theme still needs one manual selection, seeded settings or
  not.** Spotifast only actually picks up a theme once it's chosen under
  Settings > Appearance > Theme - there's no env var or CLI flag for it,
  just the `custom_theme` field in `settings.json` (still under the old
  `fastpotify` config dir; upstream kept that path on purpose when
  renaming the project). `seedSpotifastSettings` writes that field ahead
  of time, but only once, the same seed-once pattern as `thunar.xml` in
  [Thunar.nix](apps-utils-thunar.md) - the app owns this file completely
  once it exists (bitrate, sidebar order, sign-in state, ...), so either
  a symlink or an unconditional overwrite would fail every write or blow
  away real settings on the next rebuild. This only helps a fresh install
  that's never been launched before; an existing `settings.json` still
  needs that one manual theme selection, matching upstream's own
  documented flow exactly.

---

[← Spicetify.nix](apps-utils-spicetify.md) · [Index](CONFIGURATION.md) · [Nautilus.nix →](apps-utils-nautilus.md)
