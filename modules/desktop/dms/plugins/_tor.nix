{ lib, config, ... }:
lib.mkIf config.vayume.network.tor.enable {
  home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
    programs.dank-material-shell.plugins.tor = {
      enable = true;
      src = ./tor;
    };
  });
}
