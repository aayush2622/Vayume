{
  lib,
  config,
  ...
}:
{
  home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
    programs.dank-material-shell.plugins = {
      vayumeClock = {
        enable = true;
        src = ./vayumeClock;
      };
      vayumeMedia = {
        enable = true;
        src = ./vayumeMedia;
      };
    };
  });
}
