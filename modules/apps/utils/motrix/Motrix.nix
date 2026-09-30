{
  flake.appMeta.Motrix = {
    description = "Motrix, a full-featured download manager.";
    label = "Motrix";
    icon = "motrix";
    symbol = "download";
    section = "Internet";
  };

  flake.homeModules.apps.Motrix =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.vayume.motrix;
    in
    {
      options.vayume.motrix.rpcSecret = lib.mkOption {
        type = lib.types.str;
        default = "vayume";
        description = "RPC secret shared between Motrix and the browser extension.";
      };

      config = {
        home.packages = [ pkgs.motrix ];

        systemd.user.services.motrix = {
          Unit = {
            Description = "Motrix download manager";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${lib.getExe pkgs.motrix}";
            Restart = "on-failure";
            Environment = [
              "ELECTRON_OZONE_PLATFORM_HINT=auto"
            ];
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        home.activation.motrixConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          configFile="$HOME/.config/Motrix/user.json"
          mkdir -p "$(dirname "$configFile")"
          if [ -f "$configFile" ]; then
            run ${lib.getExe pkgs.jq} \
              --arg secret ${lib.escapeShellArg cfg.rpcSecret} \
              '. + {"run-mode": 2, "open-at-login": false, "rpc-secret": $secret}' \
              "$configFile" > "$configFile.tmp" && mv "$configFile.tmp" "$configFile"
          else
            run ${lib.getExe pkgs.jq} -n \
              --arg secret ${lib.escapeShellArg cfg.rpcSecret} \
              '{"run-mode": 2, "open-at-login": false, "rpc-secret": $secret}' \
              > "$configFile"
          fi
        '';
      };
    };
}
