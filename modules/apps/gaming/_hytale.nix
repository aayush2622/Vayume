# Hytale ships only as a proprietary, self-updating launcher fetched
# from launcher.hytale.com - no nixpkgs package, no Steam listing, not
# Flathub-hosted. This wraps the official native Linux binary (a
# webkit2gtk-based launcher, not an AppImage) in a plain derivation
# with autoPatchelf for its shared libraries.
#
# `url` is upstream's permanent "latest" pointer, not a versioned
# release - `hash` pins the exact bytes fetched on 2026-09-17
# (upstream version string: 2026.09.15). Bump both together to pick
# up a newer launcher; a stale hash just makes the build fail loudly
# with a mismatch, never silently serves a stale copy.
#
# The launcher's own self-updater tries to overwrite its binary in
# place, which the read-only Nix store refuses - harmless, but expect
# it to report failing to update itself. Bump the derivation above
# instead of relying on its auto-update.
{ pkgs, ... }:
let
  hytaleLauncher = pkgs.stdenv.mkDerivation {
    pname = "hytale-launcher";
    version = "2026.09.15";

    src = pkgs.fetchurl {
      url = "https://launcher.hytale.com/builds/release/linux/amd64/hytale-launcher-latest.zip";
      hash = "sha256-bH5iVP0ElNRYOoOdG0K/8q4LtDDINDQqVDYuK66Uxf0=";
    };

    nativeBuildInputs = [ pkgs.unzip pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.glib pkgs.gtk3 pkgs.webkitgtk_4_1 pkgs.libsoup_3 pkgs.gdk-pixbuf ];

    unpackPhase = "unzip -q $src";

    installPhase = ''
      install -Dm755 hytale-launcher $out/bin/hytale-launcher
    '';

    meta = {
      description = "Official Hytale game launcher (proprietary)";
      homepage = "https://hytale.com";
      mainProgram = "hytale-launcher";
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  home.packages = [ hytaleLauncher ];

  # Pick this as the install location when the launcher's first-run
  # setup asks where to put the game - keeps it next to every other
  # game under gamesDir instead of the launcher's own default.
  home.file."Games/Hytale/.keep".text = "";

  xdg.desktopEntries.hytale-launcher = {
    name = "Hytale";
    comment = "Hytale game launcher";
    exec = "hytale-launcher";
    categories = [ "Game" ];
  };
}
