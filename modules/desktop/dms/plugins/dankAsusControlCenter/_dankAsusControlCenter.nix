{ self, pkgs, lib, config, ... }:
let
  h = self.vayumeLib.dmsPluginHelpers { inherit pkgs; };

  ccWidget = ./CcWidget.qml;

  patched = h.mkPatchedPlugin "dankAsusControlCenter" h.registryPlugins.dankAsusControlCenter ''
    substituteInPlace $out/DankAsusControlCenter.qml \
      --replace-quiet "size: root.showBatteryIcon ? 18 : Theme.iconSize * 0.85" "size: root.showBatteryIcon ? 18 : root.iconSize"
    sed -i '521s/spacing: 4$/spacing: Theme.spacingXS/' $out/DankAsusControlCenter.qml
    ${h.assertPatched "$out/DankAsusControlCenter.qml" "size: root.showBatteryIcon ? 18 : root.iconSize"}
    ${h.assertPatchedLine "$out/DankAsusControlCenter.qml" 521 "Theme.spacingXS"}

    head -n -1 $out/DankAsusControlCenter.qml > $out/DankAsusControlCenter.qml.tmp
    cat ${ccWidget} >> $out/DankAsusControlCenter.qml.tmp
    echo "}" >> $out/DankAsusControlCenter.qml.tmp
    mv $out/DankAsusControlCenter.qml.tmp $out/DankAsusControlCenter.qml
    ${h.assertPatched "$out/DankAsusControlCenter.qml" "ccWidgetIcon:"}

    ${pkgs.jq}/bin/jq '.capabilities = ["dankbar-widget", "control-center"]' $out/plugin.json > $out/plugin.json.tmp
    mv $out/plugin.json.tmp $out/plugin.json
    ${h.assertPatched "$out/plugin.json" "control-center"}
  '';
in
{
  home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
    programs.dank-material-shell.plugins.dankAsusControlCenter = {
      enable = true;
      src = lib.mkForce patched;
      settings = {
        showBatteryIcon = false;
        useThemeColors = true;
      };
    };
  });
}
