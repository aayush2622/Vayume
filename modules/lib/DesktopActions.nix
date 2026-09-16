{ lib, ... }: {
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
