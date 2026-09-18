{ lib, ... }: {
  options.flake.vayumeLib.repoDiscovery = lib.mkOption {
    type = lib.types.unspecified;
    default = {
      relativeDirs = [ "vayume" "dotfiles" ".dotfiles" ];
      absoluteDirs = [ "/etc/nixos" ];
    };
    description = ''
      The candidate locations any Vayume tooling checks to find the
      flake checkout for a given $HOME - see modules/lib/VayumeLib.nix
      and docs/core-vayume-config.md. relativeDirs are joined with a
      $HOME-like shell variable; absoluteDirs are checked as-is. A
      directory counts as a match once it has a flake.nix in it.
    '';
  };

  options.flake.vayumeLib.desktopActions = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    default = {
      terminal = [ "kitty" ];
      fileManager = [ "thunar" ];
      editor = [ "code" ];
      browser = [ "zen" ];
      browserReload = [ "vayume-zen-reload" ];
      systemMonitor = [ "kitty" "-e" "btop" ];
      colorPicker = [ "hyprpicker" "-a" ];
    };
    description = ''
      argv for the handful of external app launches Hyprland.nix and
      Niri.nix both bind - one place instead of each compositor's own
      copy of the same command. See docs/desktop-hyprland.md.
    '';
  };
}
