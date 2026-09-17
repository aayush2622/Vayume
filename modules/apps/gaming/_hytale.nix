# Hytale ships only as a proprietary, self-updating launcher - no
# nixpkgs package, no Steam listing, not Flathub-hosted. JPyke3's
# hytale-launcher-nix flake (github:JPyke3/hytale-launcher-nix, pinned
# in flake.nix) already solves this properly: it extracts the official
# native binary, wraps it in an FHS environment against its
# webkit2gtk/gtk3 deps, and - unlike a plain Nix store install - lets
# the launcher's own self-updater write its update into
# ~/.local/share/Hytale instead of failing against a read-only store.
# Its CI checks upstream hourly and auto-bumps the pinned hash, so a
# routine `nix flake update hytale-launcher` is all a version bump
# needs here.
{ inputs, pkgs, ... }:
{
  home.packages = [ inputs.hytale-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # Pick this as the install location when the launcher's first-run
  # setup asks where to put the game - keeps it next to every other
  # game under gamesDir instead of the launcher's own default.
  home.file."Games/Hytale/.keep".text = "";
}
