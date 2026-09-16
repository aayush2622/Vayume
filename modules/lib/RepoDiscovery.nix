{ lib, ... }: {
  options.flake.vayumeLib.repoDiscovery = lib.mkOption {
    type = lib.types.unspecified;
    default = {
      relativeDirs = [ "vayume" "dotfiles" ".dotfiles" ];
      absoluteDirs = [ "/etc/nixos" ];
    };
    description = ''
      The candidate locations any Vayume tooling checks to find the
      flake checkout for a given $HOME - see modules/lib/RepoDiscovery.nix
      and docs/core-vayume-config.md. relativeDirs are joined with a
      $HOME-like shell variable; absoluteDirs are checked as-is. A
      directory counts as a match once it has a flake.nix in it.
    '';
  };
}
