{
  lib,
  config,
  pkgs,
  ...
}:
let
  withCommon =
    name: src:
    pkgs.runCommand "dms-${name}-plugin" { } ''
      cp -r ${src} $out
      chmod -R u+w $out
      cp ${./vayumeCommon}/*.qml $out/
    '';
in
lib.mkIf (config.vayume.desktop.shell == "dms") {
  home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
    programs.dank-material-shell.plugins = {
      vayumeClock = {
        enable = true;
        src = ./vayumeClock;
      };
      vayumeMedia = {
        enable = true;
        src = withCommon "media" ./vayumeMedia;
      };
      vayumeWeather = {
        enable = true;
        src = ./vayumeWeather;
      };
      vayumeSystem = {
        enable = true;
        src = withCommon "system" ./vayumeSystem;
      };
    };
  });
}
