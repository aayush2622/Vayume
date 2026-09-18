{ lib, config, ... }:
{
  home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
    programs.dank-material-shell.plugins.vayumeSettings = {
      enable = true;
      src = ./vayumeSettings;
    };
  });
}
