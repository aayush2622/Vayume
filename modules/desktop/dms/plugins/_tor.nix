{ lib, config, ... }:
lib.mkIf (config.vayume.network.tor.enable && config.vayume.desktop.shell == "dms") {
  home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
    programs.dank-material-shell.plugins.tor = {
      enable = true;
      src = ./tor;
    };
  });
}
