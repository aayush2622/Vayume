[Index](CONFIGURATION.md)

---

A third music client, on trial as a possible successor to Spotifast.

## `modules/apps/utils/sonora/Sonora.nix`

[Sonora](https://github.com/sonorahq/sonora) is a native Rust client
drawn with GPUI (Zed's toolkit). It plays Spotify through librespot,
like Spotifast, and also YouTube Music, Apple Music, Deezer,
Subsonic/Navidrome and local files. It exposes MPRIS, so the DMS media
card and the media keys control it.

- **Installed from its own flake**, the `sonora` input, whose `default`
  package is the prebuilt release binary. It follows this flake's
  nixpkgs, so its libraries come from the same set as everything else,
  and the automatic updater ([AutoUpdate.nix](core-autoupdate.md))
  keeps it on the latest release with no hash to bump by hand.
- **Only the package for now.** The project's home-manager module
  (`programs.sonora`) and a matugen theme are left out until the app
  settles. It was two months old and releasing every day or two when it
  was added, so its settings and theme format are still likely to
  change. Its custom themes live in a `themes` folder it reloads on
  change, the same shape as Spotifast's, so a matugen template can
  follow later.
- Spotify sign-in needs a Premium account, the same as Spotifast.

---

[← Spotifast.nix](apps-utils-spotifast.md) · [Index](CONFIGURATION.md) · [Motrix.nix →](apps-utils-motrix.md)
