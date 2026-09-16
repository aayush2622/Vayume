{
  flake.nixosModules.DmsPluginDankAsusControlCenter = { self, pkgs, lib, config, ... }:
    let
      h = self.vayumeLib.dmsPluginHelpers { inherit pkgs; };

      # Upstream (shazzaam7/DankAsusControl) only implements the DankBar
      # widget interface (horizontalBarPill / popoutContent) - no
      # "capabilities" field in its plugin.json at all, and nothing in its
      # QML for the control center. DMS's control center looks for a
      # separate ccWidget*/ccDetailContent interface instead (see
      # DankMaterialShell's own PLUGINS/ControlCenterDetailExample) -
      # CcWidget.qml is a second copy of popoutContent's body against
      # that interface, since QML Components aren't values the two could
      # share. Tapping the pill cycles the power profile, the same
      # one-tap-cycle convention DMS's own built-in toggle pills use.
      ccWidget = ./CcWidget.qml;

      patched = h.mkPatchedPlugin "dankAsusControlCenter" h.registryPlugins.dankAsusControlCenter ''
        substituteInPlace $out/DankAsusControlCenter.qml \
          --replace-quiet "size: root.showBatteryIcon ? 18 : Theme.iconSize * 0.85" "size: root.showBatteryIcon ? 18 : root.iconSize"
        sed -i '521s/spacing: 4$/spacing: Theme.spacingXS/' $out/DankAsusControlCenter.qml
        ${h.assertPatched "$out/DankAsusControlCenter.qml" "size: root.showBatteryIcon ? 18 : root.iconSize"}
        ${h.assertPatchedLine "$out/DankAsusControlCenter.qml" 521 "Theme.spacingXS"}

        # Insert the ccWidget*/ccDetailContent block right before the
        # file's final closing brace, and declare the capability DMS's
        # own example plugin uses for this - upstream's plugin.json has
        # no "capabilities" field at all, so this adds it fresh rather
        # than merging into an existing array.
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
    };
}
