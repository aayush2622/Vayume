{ inputs, self, pkgs, lib, config, ... }:
let
  h = self.vayumeLib.dmsPluginHelpers { inherit pkgs; };

  origDmsShell = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell;

  inputReplacement = lib.concatStringsSep "\n" [
    "[input]"
    "method=pipewire"
    "source=auto"
    ""
    "[general]"
  ];

  watchdogBlock = lib.concatStringsSep "\n" [
    "property bool playbackActive: false"
    ""
    "    Timer {"
    "        interval: 2000"
    "        running: root.refCount > 0 && root.cavaAvailable"
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
    "            root.playbackActive = exitCode === 0;"
    "        }"
    "    }"
    ""
    "    Process {"
    "        id: cavaProcess"
  ];

  oldRunning = "running: root.cavaAvailable && root.refCount > 0";
  newRunning = "running: root.cavaAvailable && root.refCount > 0 && root.playbackActive";

  dmsShellPatched =
    pkgs.runCommand "${origDmsShell.name}-cava-patched" {
      meta = (origDmsShell.meta or { }) // {
        mainProgram = "dms";
      };
    } ''
      cp -r ${origDmsShell} $out
      chmod -R u+w $out

      substituteInPlace $out/share/quickshell/dms/Services/CavaService.qml \
        --replace-quiet ${lib.escapeShellArg "[general]"} ${lib.escapeShellArg inputReplacement}
      ${h.assertPatched "$out/share/quickshell/dms/Services/CavaService.qml" "source=auto"}

      substituteInPlace $out/share/quickshell/dms/Services/CavaService.qml \
        --replace-quiet ${lib.escapeShellArg "    Process {\n        id: cavaProcess"} ${lib.escapeShellArg watchdogBlock}
      substituteInPlace $out/share/quickshell/dms/Services/CavaService.qml \
        --replace-quiet ${lib.escapeShellArg oldRunning} ${lib.escapeShellArg newRunning}
      ${h.assertPatched "$out/share/quickshell/dms/Services/CavaService.qml" "playbackActive"}

      substituteInPlace $out/share/quickshell/dms/shell.qml \
        --replace-quiet \
          ${lib.escapeShellArg "active: SettingsData.blurredWallpaperLayer && CompositorService.isNiri"} \
          ${lib.escapeShellArg "active: SettingsData.blurredWallpaperLayer && (CompositorService.isNiri || CompositorService.isHyprland)"}
      ${h.assertPatched "$out/share/quickshell/dms/shell.qml" "CompositorService.isHyprland"}

      substituteInPlace $out/bin/dms \
        --replace-quiet "${origDmsShell}/share/quickshell/dms" "$out/share/quickshell/dms"
      if grep -qF ${lib.escapeShellArg "${origDmsShell}/share/quickshell/dms"} "$out/bin/dms"; then
        echo "patch verification failed: bin/dms still references the original share/quickshell/dms path (upstream wrapper script format likely changed - update the patch)" >&2
        exit 1
      fi
    '';
in
{
  home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
    programs.dank-material-shell.package = lib.mkForce dmsShellPatched;
  });
}
