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

      tidy = pkgs.writeShellApplication {
        name = "vayume-motrix-tidy";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
        ];
        text = ''
          dir="''${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
          [ -d "$dir" ] || exit 0
          now=$(date +%s)
          settled() { [ $((now - $(stat -c %Y "$1"))) -ge 120 ]; }

          while IFS= read -r -d "" part; do
            name=$(basename "$part")
            if [[ $name =~ ^(.*)\.([A-Za-z0-9]{8})\.(.+)\.part$ ]]; then
              target="$dir/''${BASH_REMATCH[1]}.''${BASH_REMATCH[3]}"
              if [ -f "$target" ] && settled "$part"; then
                echo "removing Zen's leftover $name (Motrix has $(basename "$target"))"
                rm -f -- "$part"
              fi
            fi
          done < <(find "$dir" -maxdepth 1 -type f -name '*.part' -print0)

          while IFS= read -r -d "" copy; do
            name=$(basename "$copy")
            if [[ $name =~ ^(.+)\.([0-9]+)\.([^.]+)$ ]]; then
              original="$dir/''${BASH_REMATCH[1]}.''${BASH_REMATCH[3]}"
              [ -f "$original" ] || continue
              [ ! -e "$copy.aria2" ] || continue
              settled "$copy" || continue
              delta=$(($(stat -c %Y "$copy") - $(stat -c %Y "$original")))
              [ "''${delta#-}" -le 120 ] || continue
              if [ "$(stat -c %s "$copy")" = "$(stat -c %s "$original")" ] && cmp -s -- "$copy" "$original"; then
                echo "removing duplicate $name (identical to $(basename "$original"))"
                rm -f -- "$copy"
              fi
            fi
          done < <(find "$dir" -maxdepth 1 -type f -name '*.*.*' -print0)
        '';
      };
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
            ExecStart = "${lib.getExe pkgs.motrix} --opened-at-login=1";
            Restart = "on-failure";
            Environment = [
              "ELECTRON_OZONE_PLATFORM_HINT=auto"
            ];
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        systemd.user.services.motrix-tidy = {
          Unit.Description = "Remove the second copy Zen and Motrix both download";
          Service = {
            Type = "oneshot";
            ExecStart = "${lib.getExe tidy}";
            Nice = 19;
            IOSchedulingClass = "idle";
          };
        };

        systemd.user.timers.motrix-tidy = {
          Unit.Description = "Tidy Zen and Motrix duplicate downloads";
          Timer = {
            OnBootSec = "3min";
            OnUnitActiveSec = "2min";
          };
          Install.WantedBy = [ "timers.target" ];
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
