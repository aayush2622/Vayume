{ ... }:
{
  flake.nixosModules.PowerProfile =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      effects = import ../desktop/_effects.nix;
      dms = config.vayume.desktop.shell == "dms";

      dmsSaver = effects.dmsSaver;
      dmsKeys = builtins.attrNames dmsSaver ++ [ "desktopWidgetInstances" ];

      hyprland = enabled: {
        animations.enabled = enabled;
        decoration = {
          rounding = if enabled then effects.rounding else 0;
          active_opacity = if enabled then effects.activeOpacity else 1.0;
          inactive_opacity = if enabled then effects.inactiveOpacity else 1.0;
          blur.enabled = enabled;
          shadow.enabled = enabled;
        };
      };

      toLua =
        v:
        if builtins.isAttrs v then
          "{" + lib.concatStringsSep "," (lib.mapAttrsToList (k: x: "${k}=${toLua x}") v) + "}"
        else if builtins.isBool v then
          lib.boolToString v
        else
          toString v;

      power = pkgs.writeShellApplication {
        name = "vayume-power";
        excludeShellChecks = [ "SC2016" ];
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.jq
          pkgs.systemd
        ];
        text = ''
          export PATH="$PATH:/run/current-system/sw/bin"
          state="''${XDG_STATE_HOME:-$HOME/.local/state}/vayume"
          dms_settings="$HOME/.config/DankMaterialShell/settings.json"
          dms_shell=${lib.boolToString dms}
          shell_units="dms noctalia caelestia"

          have() { command -v "$1" >/dev/null 2>&1; }

          backend() {
            if have asusctl && asusctl profile get >/dev/null 2>&1; then echo asus
            elif have powerprofilesctl && powerprofilesctl get >/dev/null 2>&1; then echo ppd
            else echo none
            fi
          }

          profile_get() {
            case "$(backend)" in
              asus) asusctl profile get 2>/dev/null | sed -n 's/^Active profile: *//p' | head -n 1 ;;
              ppd) powerprofilesctl get ;;
            esac
          }

          profile_list() {
            case "$(backend)" in
              asus) asusctl profile list 2>/dev/null | grep -E '^[A-Za-z]+$' || true ;;
              ppd) powerprofilesctl list | sed -n 's/^[ *]*\([a-z-]*\):$/\1/p' ;;
            esac
          }

          profile_set() {
            case "$(backend)" in
              asus) asusctl profile set "$1" ;;
              ppd) powerprofilesctl set "$1" ;;
              *) echo "vayume-power: no power profile service (asusd or power-profiles-daemon) is running" >&2; exit 1 ;;
            esac
          }

          profile_lowest() {
            case "$(backend)" in
              asus) echo Quiet ;;
              ppd) echo power-saver ;;
            esac
          }

          armoury_get() {
            asusctl armoury get "$1" 2>/dev/null | sed -n 's/.*current:.*(\s*\([0-9]*\)\s*).*/\1/p' | head -n 1
          }

          json_bool() { if [ "$1" = 1 ]; then echo true; elif [ "$1" = 0 ]; then echo false; else echo null; fi; }

          status() {
            local limit gpu gpus overdrive brightness
            limit=""
            gpu=""
            gpus="[]"
            overdrive=""
            brightness=""
            if have asusctl; then
              limit=$(asusctl battery info 2>/dev/null | sed -n 's/.*charge limit: *\([0-9]*\)%.*/\1/p' | head -n 1)
              overdrive=$(armoury_get panel_overdrive)
              brightness=$(armoury_get screen_auto_brightness)
            fi
            if have supergfxctl; then
              gpu=$(supergfxctl -g 2>/dev/null | head -n 1 || true)
              gpus=$(supergfxctl -s 2>/dev/null | tr -d "[]' " | tr ',' '\n' | grep -v '^$' | jq -R . | jq -s . || echo '[]')
            fi
            jq -n \
              --arg backend "$(backend)" \
              --arg profile "$(profile_get)" \
              --argjson profiles "$(profile_list | jq -R . | jq -s .)" \
              --arg limit "$limit" \
              --arg gpu "$gpu" \
              --argjson gpus "$gpus" \
              --argjson overdrive "$(json_bool "$overdrive")" \
              --argjson brightness "$(json_bool "$brightness")" \
              '{
                backend: $backend,
                profile: $profile,
                profiles: $profiles,
                batteryLimit: (if $limit == "" then null else ($limit | tonumber) end),
                gpu: (if $gpu == "" then null else $gpu end),
                gpuModes: $gpus,
                panelOverdrive: $overdrive,
                autoBrightness: $brightness
              }'
          }

          dms_edit() {
            local tmp
            [ "$dms_shell" = true ] && [ -e "$dms_settings" ] || return 0
            if [ -L "$dms_settings" ]; then
              cp --remove-destination "$(readlink -f "$dms_settings")" "$dms_settings"
              chmod u+w "$dms_settings"
            fi
            tmp=$(mktemp "$dms_settings.XXXXXX")
            jq "$@" "$dms_settings" > "$tmp"
            chmod 644 "$tmp"
            mv "$tmp" "$dms_settings"
          }

          hypr_eval() {
            [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && have hyprctl || return 0
            hyprctl eval "hl.config($1)" >/dev/null
          }

          saver_on() {
            local lowest
            mkdir -p "$state"
            touch "$state/saver-active"
            lowest=$(profile_lowest)
            if [ -n "$lowest" ] && [ ! -f "$state/saver-profile" ]; then
              profile_get > "$state/saver-profile"
              profile_set "$lowest"
            fi
            hypr_eval '${toLua (hyprland false)}'
            if [ ! -f "$state/saver-dms.json" ] && [ "$dms_shell" = true ] && [ -e "$dms_settings" ]; then
              jq --argjson keys '${builtins.toJSON dmsKeys}' \
                '. as $s | $keys | map({key: ., value: $s[.]}) | from_entries' "$dms_settings" > "$state/saver-dms.json"
            fi
            dms_edit --argjson set '${builtins.toJSON dmsSaver}' '. + $set | if has("desktopWidgetInstances") then .desktopWidgetInstances |= map(.enabled = false) else . end'
            if systemctl --user is-active --quiet vayume-pet.service; then
              systemctl --user stop vayume-pet.service
              touch "$state/saver-pet"
            fi
            for unit in $shell_units; do
              systemctl --user set-property --runtime "$unit.service" CPUWeight=20 IOWeight=20 2>/dev/null || true
            done
          }

          saver_off() {
            mkdir -p "$state"
            rm -f "$state/saver-active"
            if [ -f "$state/saver-profile" ]; then
              [ -z "$(cat "$state/saver-profile")" ] || profile_set "$(cat "$state/saver-profile")"
              rm -f "$state/saver-profile"
            fi
            hypr_eval '${toLua (hyprland true)}'
            if [ -f "$state/saver-dms.json" ]; then
              dms_edit --slurpfile prev "$state/saver-dms.json" \
                '. as $s | ($prev[0] | to_entries) as $p | reduce $p[] as $e ($s; if $e.value == null then del(.[$e.key]) else .[$e.key] = $e.value end)'
              rm -f "$state/saver-dms.json"
            fi
            if [ -f "$state/saver-pet" ]; then
              systemctl --user start vayume-pet.service || true
              rm -f "$state/saver-pet"
            fi
            for unit in $shell_units; do
              systemctl --user set-property --runtime "$unit.service" CPUWeight=100 IOWeight=100 2>/dev/null || true
            done
          }

          onoff() {
            case "$1" in
              true | on | 1) echo 1 ;;
              false | off | 0) echo 0 ;;
              *) echo "vayume-power: expected on or off, got '$1'" >&2; exit 2 ;;
            esac
          }

          case "''${1:-status}" in
            status) status ;;
            profile) profile_set "''${2:?profile name required}" ;;
            battery-limit)
              [[ ''${2:-} =~ ^[0-9]+$ ]] && [ "$2" -ge 20 ] && [ "$2" -le 100 ] || { echo "vayume-power: battery limit must be 20-100" >&2; exit 2; }
              asusctl battery limit "$2"
              ;;
            gpu) supergfxctl -m "''${2:?gpu mode required}" ;;
            overdrive) asusctl armoury set panel_overdrive "$(onoff "''${2:-}")" ;;
            auto-brightness) asusctl armoury set screen_auto_brightness "$(onoff "''${2:-}")" ;;
            saver)
              if [ "$(onoff "''${2:-}")" = 1 ]; then saver_on; else saver_off; fi
              ;;
            pet)
              systemctl --user cat vayume-pet.service >/dev/null 2>&1 || { echo "vayume-power: the pet service isn't built yet - rebuild to add it" >&2; exit 1; }
              if [ "$(onoff "''${2:-}")" = 1 ]; then
                [ -f "$state/saver-pet" ] || systemctl --user start vayume-pet.service
              else
                systemctl --user stop vayume-pet.service
              fi
              ;;
            *)
              echo "usage: vayume power [status|profile NAME|battery-limit N|gpu MODE|overdrive on|off|auto-brightness on|off|saver on|off|pet on|off]" >&2
              exit 2
              ;;
          esac
        '';
      };

      hook =
        sub: "${pkgs.writeShellScript "vayume-live-${sub}" ''exec ${power}/bin/vayume-power ${sub} "$1"''}";
    in
    {
      config = {
        home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (
          _:
          { lib, ... }:
          {
            home.activation.vayumeSaverState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              state="''${XDG_STATE_HOME:-$HOME/.local/state}/vayume"
              run mkdir -p "$state"
              ${
                if config.vayume.power.ultraSaver then
                  ''run touch "$state/saver-active"''
                else
                  ''run rm -f "$state/saver-active"''
              }
            '';
          }
        );

        vayume.commands.power = {
          command = "${power}/bin/vayume-power";
          description = "Power profile, battery limit, GPU mode and the ultra power saver";
          usage = "[status|profile NAME|battery-limit N|gpu MODE|saver on|off]";
        };

        vayume.settingsLive = {
          "power.ultraSaver" = hook "saver";
          "desktop.pet.enable" = hook "pet";
        };
      };
    };
}
