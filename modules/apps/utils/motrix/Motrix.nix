{
  flake.appMeta.Motrix = {
    description = "Motrix, a full-featured download manager.";
    label = "Motrix";
    icon = "motrix";
    symbol = "download";
    section = "Internet";
  };

  flake.homeModules.apps.Motrix =
    { pkgs, lib, ... }:
    {
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
        cfg="$HOME/.config/Motrix/user.json"
        if [ -f "$cfg" ]; then
          run ${lib.getExe pkgs.jq} '. + {"run-mode": 2, "open-at-login": false}' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
        fi
      '';
    };
}
