{ inputs, ... }:
{
  flake.homeModules.VayumeSettings =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      qml = pkgs.runCommand "vayume-settings-qml" { } ''
        cp -r ${inputs.dank-qml-common} $out
        chmod -R u+w $out
        rm -f $out/shell.qml
        cp -r ${./qml}/. $out/
      '';

      settings = pkgs.writeShellScriptBin "vayume-settings" ''
        exec ${pkgs.quickshell}/bin/qs --no-duplicate --path ${qml}
      '';

      home = config.home.homeDirectory;
    in
    {
      vayume.commands.settings = {
        command = lib.getExe settings;
        description = "Open Vayume Settings";
      };

      xdg.desktopEntries."org.vayume.Settings" = {
        name = "Vayume Settings";
        comment = "Apps, appearance, users and rebuilds for this machine";
        exec = "vayume settings";
        icon = "preferences-system";
        categories = [
          "Settings"
          "System"
        ];
      };

      home.file.".config/matugen/templates/vayume-colors.json".source = ./matugen/colors.json.template;

      vayume.matugenTemplates.vayumeSettings = ''
        [templates.vayumeSettings]
        input_path = '${home}/.config/matugen/templates/vayume-colors.json'
        output_path = '${home}/.config/vayume/colors.json'
      '';
    };
}
