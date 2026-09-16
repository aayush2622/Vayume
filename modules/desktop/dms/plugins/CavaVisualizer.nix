{
  flake.nixosModules.DmsPluginCavaVisualizer = { self, pkgs, lib, config, ... }:
    let
      h = self.vayumeLib.dmsPluginHelpers { inherit pkgs; };

      watchdogProps = lib.concatStringsSep "\n" [
        "readonly property int maxRetries: 3"
        ""
        "    property bool playbackActive: false"
        ""
        "    Timer {"
        "        interval: 2000"
        "        running: true"
        "        repeat: true"
        "        triggeredOnStart: true"
        "        onTriggered: playbackCheck.running = true"
        "    }"
        ""
        "    Process {"
        "        id: playbackCheck"
        ("        command: [\"" + "${h.audioIsPlayingScript}" + "\"]")
        "        running: false"
        "        onExited: exitCode => {"
        "            root.playbackActive = exitCode === 0"
        "            if (root.playbackActive) {"
        "                if (!configWriter.running && !cavaProcess.running)"
        "                    configWriter.running = true"
        "            } else if (cavaProcess.running) {"
        "                cavaProcess.running = false"
        "            }"
        "        }"
        "    }"
      ];

      oldRetryGuard = "if (!running && !configWriter.running) {";
      newRetryGuard = "if (!running && !configWriter.running && root.playbackActive) {";

      patched = h.mkPatchedPlugin "cavaVisualizer" h.registryPlugins.cavaVisualizer ''
        substituteInPlace $out/CavaVisualizerTab.qml \
          --replace-quiet ${lib.escapeShellArg "readonly property int maxRetries: 3"} ${lib.escapeShellArg watchdogProps}
        ${h.assertPatched "$out/CavaVisualizerTab.qml" "playbackActive"}

        substituteInPlace $out/CavaVisualizerTab.qml \
          --replace-quiet \
            '"[general]\n" +' \
            '"[input]\n" + "method = pipewire\n" + "source = auto\n" + "\n" + "[general]\n" +'
        ${h.assertPatched "$out/CavaVisualizerTab.qml" "source = auto"}

        substituteInPlace $out/CavaVisualizerTab.qml \
          --replace-quiet ${lib.escapeShellArg oldRetryGuard} ${lib.escapeShellArg newRetryGuard}
        ${h.assertPatched "$out/CavaVisualizerTab.qml" "playbackActive) {"}
      '';
    in
    {
      home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
        programs.dank-material-shell.plugins.cavaVisualizer = {
          enable = true;
          src = lib.mkForce patched;
        };
      });
    };
}
