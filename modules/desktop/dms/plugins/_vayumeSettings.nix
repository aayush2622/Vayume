{ lib, config, ... }:
lib.mkIf (config.vayume.desktop.shell == "dms") {
  home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
    programs.dank-material-shell.plugins.vayumeSettings = {
      enable = true;
      src = ./vayumeSettings;
    };
  });
}
