[Index](CONFIGURATION.md)

---

A second Spotify client, next to Spicetify - not a replacement for it, a completely different tradeoff.

## `modules/apps/utils/spotifast/Spotifast.nix`

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
  matugen hook and the settings seed both check for an existing profile
  first instead of creating one. MPRIS is now
  `org.mpris.MediaPlayer2.spotifast`, so `playerctl --player=fastpotify`
  bindings need updating.
- **It's genuinely not Spicetify.** Spicetify patches the real, official
  Spotify Electron app to reskin and extend it - you get actual Spotify
  with a theme on top. Spotifast (formerly Fastpotify) is a from-scratch native client
  (Rust + egui, playback through librespot) that never runs Electron at
  all, at a fraction of the memory. Trading Spotify's own UI/extension
  ecosystem for speed is the whole point, not a bug - so both are worth
  having on for different moods rather than picking one.
- **`x-scheme-handler/spotify` is explicitly claimed, not left to
  chance.** Spotifast's own `.desktop` file declares
  `MimeType=x-scheme-handler/spotify`, which only makes it a *candidate*
  handler - without an explicit default, opening a shared Spotify link
  (or the browser handing off an `open.spotify.com` address) has nothing
  to fall back on. `xdg.mimeApps.defaultApplications` sets it as the
  actual default here, the same fix this session applied to
  [Thunar.nix](apps-utils-thunar.md) for `inode/directory` - and the
  same landmine applies: `xdg.mimeApps.enable` defaults to `false` in
  home-manager and has to be set explicitly, or the whole block is
  silently inert.
- **Matugen writes a palette, a `post_hook` installs and reloads it.**
  Official Spotifast reads custom JSON palettes from a `themes` folder beside
  `settings.json` and only re-reads them when told to
  (`spotifast reload-themes`, or Ctrl+Shift+R) - the fork this module used to
  target re-checked a file's mtime every frame, and that behaviour is gone.
  So the template renders to `~/.config/matugen/spotifast-dankmatugen.json`
  and its `post_hook` (`spotifast-theme-hook`) copies that into
  `<profile>/themes/dankmatugen.json`, then runs `spotifast reload-themes`,
  which only contacts an already-running instance and leaves a stopped app
  stopped, without interrupting playback. The hook copies only into a profile
  folder that already exists (`~/.config/spotifast`, or
  `~/.config/fastpotify` before the 0.9.1 migration) and never creates one,
  so it can't block the migration described above; on a fresh install with
  no profile yet, it does nothing until the app has been run once.
- **A custom theme still needs one manual selection, seeded settings or
  not.** Spotifast only actually picks up a theme once it's chosen under
  Settings > Appearance > Theme - there's no env var or CLI flag for it,
  just the `custom_theme` field in `settings.json`.
  `seedSpotifastSettings` writes that field ahead of time, but only once, and
  only when there is no unmigrated `~/.config/fastpotify` profile waiting
  (creating `~/.config/spotifast` first would block the migration), the same seed-once pattern as `thunar.xml` in
  [Thunar.nix](apps-utils-thunar.md) - the app owns this file completely
  once it exists (bitrate, sidebar order, sign-in state, ...), so either
  a symlink or an unconditional overwrite would fail every write or blow
  away real settings on the next rebuild. This only helps a fresh install
  that's never been launched before; an existing `settings.json` still
  needs that one manual theme selection, matching upstream's own
  documented flow exactly.

- **Album-art theming comes from the DMS Music Theme plugin, not from
  Spotifast.** [dms-music-theme](https://github.com/felipeadeildo/dms-music-theme)
  retints the whole desktop palette from the cover art of whatever is
  playing and goes back to the wallpaper colors when playback stops. It
  reads DMS's own MPRIS state, so it works with any player; Spotifast
  qualifies because it publishes `org.mpris.MediaPlayer2.spotifast` with
  `mpris:artUrl` (the binary contains the property; it was not
  run-tested here). Spotifast is themed by the matugen template and hook
  above, and the plugin drives the same matugen pipeline, so each retint
  re-renders the palette, the hook installs it and runs
  `spotifast reload-themes` - nothing Spotifast-specific had to be
  added. It replaces the older `spotifyMatugen` plugin, which only
  followed a player whose MPRIS name contains "spotify" and so never
  matched Spotifast. It is one line, `musicTheme.enable = true;`, in the
  `plugins` block of `modules/desktop/dms/Dms.nix` (where `spotifyMatugen`
  was); remove it for wallpaper-only colors. The plugin comes from the
  DMS plugin registry, which pins upstream commit `b7314c0`, so there is
  no extra pin to maintain - it moves with the `dms-plugin-registry` flake
  input. Its own settings (update delay, palette) are in DMS Settings >
  Plugins.

---

[← Spicetify.nix](apps-utils-spicetify.md) · [Index](CONFIGURATION.md) · [Nautilus.nix →](apps-utils-nautilus.md)
