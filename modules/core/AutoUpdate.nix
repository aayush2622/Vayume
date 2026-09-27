{ self, ... }:
{
  flake.nixosModules.AutoUpdate =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.vayume.updates;
      repoDiscovery = self.vayumeLib.repoDiscovery;
      homes = map (name: config.users.users.${name}.home) (builtins.attrNames config.vayume.users);
      candidates =
        lib.concatMap (home: map (d: "${home}/${d}") repoDiscovery.relativeDirs) homes
        ++ repoDiscovery.absoluteDirs;
      statusFile = "/var/lib/vayume-update/status.json";

      updateScript = pkgs.writeShellApplication {
        name = "vayume-update-run";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.util-linux
          pkgs.gnugrep
          pkgs.gnutar
          pkgs.findutils
          pkgs.git
          pkgs.jq
          pkgs.libnotify
          config.nix.package
          config.system.build.nixos-rebuild
        ];
        text = ''
          flake=0 plugins=0 apply=${cfg.apply}
          for arg in "$@"; do
            case "$arg" in
            --flake) flake=1 ;;
            --plugins) plugins=1 ;;
            --boot) apply=boot ;;
            --switch) apply=switch ;;
            *)
              echo "usage: vayume-update-run [--flake] [--plugins] [--boot|--switch]" >&2
              exit 2
              ;;
            esac
          done

          exec 9>/run/vayume-update.lock
          flock -n 9 || { echo "An update is already running" >&2; exit 1; }

          repo=""
          for d in ${lib.escapeShellArgs candidates}; do
            [ -f "$d/flake.nix" ] && repo=$(cd -P "$d" && pwd) && break
          done
          [ -n "$repo" ] || { echo "vayume flake not found" >&2; exit 1; }
          owner=$(stat -c %U "$repo")
          home=$(getent passwd "$owner" | cut -d: -f6)
          uid=$(id -u "$owner")

          as_owner() { runuser -u "$owner" -- env HOME="$home" "$@"; }

          notify() {
            local bus=/run/user/$uid/bus
            [ -S "$bus" ] || return 0
            as_owner env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
              notify-send -a Vayume -i system-software-update "$1" "$2" || true
          }

          record() {
            mkdir -p "$(dirname ${statusFile})"
            jq -n --arg result "$1" --arg summary "$2" --arg time "$(date -Iseconds)" \
              '{time: $time, result: $result, summary: $summary}' >${statusFile}
          }

          backup=$(mktemp -d)
          trap 'rm -rf "$backup"' EXIT
          cd "$repo"
          mapfile -t pinned < <(grep -rl --include='*.nix' 'hash = "sha256-' modules)
          tar -cf "$backup/files.tar" flake.lock "''${pinned[@]}"
          restore() { tar -xf "$backup/files.tar" -C "$repo"; }

          summary=()
          if [ "$flake" = 1 ]; then
            if ! as_owner git -C "$repo" diff --quiet -- flake.lock 2>/dev/null; then
              echo "flake.lock has unsaved edits, leaving the inputs alone"
            elif out=$(as_owner nix flake update --flake "$repo" 2>&1); then
              echo "$out"
              n=$(grep -c "Updated input" <<<"$out" || true)
              [ "$n" -gt 0 ] && summary+=("$n flake inputs")
            else
              echo "$out" >&2
              restore
              record failed "Could not update the flake inputs"
              notify "Update failed" "Could not update the flake inputs. Nothing was changed."
              exit 1
            fi
          fi

          if [ "$plugins" = 1 ]; then
            if out=$(as_owner ${config.vayume.commands.check-plugin-updates.command} --apply "$repo"); then
              [ -n "$out" ] && echo "$out"
              n=$(grep -c . <<<"$out" || true)
              [ "$n" -gt 0 ] && summary+=("$n plugins")
            else
              echo "Plugin check failed, skipping plugins" >&2
            fi
          fi

          if [ "''${#summary[@]}" -eq 0 ]; then
            record current "Everything was already up to date"
            echo "Everything is up to date"
            exit 0
          fi
          text="''${summary[0]}"
          [ "''${#summary[@]}" -gt 1 ] && text="$text and ''${summary[1]}"

          echo "Building the updated system"
          if ! nixos-rebuild "$apply" --flake "path:$repo#${config.networking.hostName}"; then
            restore
            record failed "Updated $text, but the system did not build, so the old versions were kept"
            notify "Update failed" "The updated system did not build. Your current versions were kept."
            exit 1
          fi

          if [ "$apply" = boot ]; then
            record installed "Updated $text. Used from the next restart"
            notify "Updates ready" "Updated $text. Restart to use them."
          else
            record installed "Updated $text"
            notify "System updated" "Updated $text."
          fi
        '';
      };

      runArgs = lib.optional cfg.flake "--flake" ++ lib.optional cfg.plugins "--plugins";

      updateNow = pkgs.writeShellApplication {
        name = "vayume-update";
        text = ''
          [ "$#" -eq 0 ] || { echo "usage: vayume update (updates the flake inputs and pinned plugins, then builds)" >&2; exit 2; }
          exec sudo -n ${lib.getExe updateScript} --flake --plugins
        '';
      };

      updateStatus = pkgs.writeShellApplication {
        name = "vayume-update-status";
        runtimeInputs = [
          pkgs.jq
          pkgs.systemd
        ];
        text = ''
          if [ -f ${statusFile} ]; then
            jq -r '"Last run: \(.time)\n\(.summary)"' ${statusFile}
          else
            echo "No update has run yet"
          fi
          ${
            if runArgs == [ ] then
              ''echo "Automatic updates are off"''
            else
              ''echo "Next automatic run: $(systemctl show vayume-update.timer -p NextElapseUSecRealtime --value)"''
          }
        '';
      };
    in
    {
      options.vayume.updates = {
        flake = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Update the flake inputs (nixpkgs, home-manager, DMS, extension sets...) on a schedule.";
        };
        plugins = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Bump the hand-pinned VS Code and Android Studio plugins to their newest versions on a schedule.";
        };
        frequency = lib.mkOption {
          type = lib.types.enum [
            "daily"
            "weekly"
          ];
          default = "weekly";
          description = "How often the automatic update runs. A run missed while the computer was off happens at the next start.";
        };
        apply = lib.mkOption {
          type = lib.types.enum [
            "boot"
            "switch"
          ];
          default = "boot";
          description = "`boot` makes the updated system the one used from the next restart, `switch` also switches to it straight away.";
        };
      };

      config = {
        vayume.commands.update = {
          command = lib.getExe updateNow;
          description = "Update the flake inputs and pinned plugins now, then build the system";
          panel = {
            label = "Update everything now";
            icon = "system_update_alt";
            page = "updates";
            group = "Update";
          };
        };
        vayume.commands.update-status = {
          command = lib.getExe updateStatus;
          description = "Show when the last update ran, what it did and when the next one is due";
          panel = {
            label = "Last update";
            icon = "history";
            page = "updates";
            group = "Update";
          };
        };

        security.sudo.extraRules =
          map
            (name: {
              users = [ name ];
              commands = [
                {
                  command = "${lib.getExe updateScript} --flake --plugins";
                  options = [ "NOPASSWD" ];
                }
              ];
            })
            (
              builtins.filter (name: builtins.elem "wheel" config.vayume.users.${name}.extraGroups) (
                builtins.attrNames config.vayume.users
              )
            );

        systemd.services.vayume-update = {
          description = "Update the Vayume flake inputs and pinned plugins";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          unitConfig.ConditionACPower = true;
          environment.HOME = "/root";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.escapeShellArgs ([ (lib.getExe updateScript) ] ++ runArgs);
            Nice = 19;
            IOSchedulingClass = "idle";
            CPUSchedulingPolicy = "batch";
          };
        };

        systemd.timers.vayume-update = lib.mkIf (runArgs != [ ]) {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.frequency;
            Persistent = true;
            RandomizedDelaySec = "30min";
          };
        };

        vayume.settingsGroups."Automatic updates" = {
          order = 1;
          icon = "update";
          description = "Keep the system and pinned plugins current. Updates are built in the background and a failed build changes nothing.";
          page = "updates";
        };

        vayume.settingsMeta =
          let
            entry = label: icon: order: {
              group = "Automatic updates";
              inherit label icon order;
            };
          in
          {
            "updates.flake" = entry "Update flake inputs" "deployed_code_update" 1;
            "updates.plugins" = entry "Update pinned plugins" "extension" 2;
            "updates.frequency" = entry "How often" "event_repeat" 3;
            "updates.apply" = entry "When to use updates" "restart_alt" 4;
          };
      };
    };
}
