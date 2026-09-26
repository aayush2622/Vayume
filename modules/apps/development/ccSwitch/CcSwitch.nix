{
  flake.appDescriptions.CcSwitch = "cc-switch: quick-switch between Claude API provider profiles.";
  flake.appMeta.CcSwitch = {
    label = "CC Switch";
    icon = "cc-switch";
    symbol = "swap_horiz";
    section = "Tools";
  };

  flake.homeModules.apps.CcSwitch =
    { pkgs, lib, ... }:
    let
      ccSwitchSettings = pkgs.writeText "cc-switch-settings.json" (
        builtins.toJSON {
          showInTray = true;
          minimizeToTrayOnClose = true;
          launchOnStartup = true;
          enableClaudePluginIntegration = true;
          preferredTerminal = "kitty";
        }
      );
    in
    {
      home.packages = [ pkgs.cc-switch ];

      home.activation.seedCcSwitchSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dest="$HOME/.cc-switch/settings.json"
        if [ ! -e "$dest" ]; then
          run mkdir -p "$(dirname "$dest")"
          run cp ${ccSwitchSettings} "$dest"
          run chmod u+w "$dest"
        fi
      '';
    };
}
