{ ... }:
{
  flake.nixosModules.Shell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      shell = config.vayume.desktop.shell;
      cmds = config.vayume.desktop.shellCommands;
      widgets = config.vayume.desktop.shellWidgets;
      power = config.vayume.power;

      labels = {
        dms = "DMS";
        noctalia = "Noctalia";
        caelestia = "Caelestia";
      };

      actions = [
        "bar"
        "settings"
        "wallpaper"
        "wallpaper-next"
        "wallpaper-prev"
        "screenshot"
      ];

      arm =
        action:
        let
          argv = cmds.${action} or null;
        in
        if argv == null then
          ''
            ${action})
              exec ${pkgs.libnotify}/bin/notify-send -a Vayume ${lib.escapeShellArg "Not available on ${labels.${shell}}"} ${lib.escapeShellArg "The ${action} action has no equivalent in this shell."}
              ;;''
        else
          ''
            ${action})
              exec ${lib.escapeShellArgs argv}
              ;;'';

      vayumeShell = pkgs.writeShellScriptBin "vayume-shell" ''
        case "''${1:-}" in
        ${lib.concatMapStringsSep "\n" arm actions}
        *)
          echo "usage: vayume shell <${lib.concatStringsSep "|" actions}>" >&2
          exit 2
          ;;
        esac
      '';

      run = argv: if argv == null then ":" else lib.escapeShellArgs argv;

      widgetsScript = pkgs.writeShellApplication {
        name = "vayume-widgets";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.systemd
        ];
        text = ''
          state="''${XDG_RUNTIME_DIR:-/tmp}/vayume-hidden-widgets"

          hide() {
            : >"$state"
            ${run widgets.hide} || true
            if systemctl --user is-active --quiet vayume-pet; then
              systemctl --user stop vayume-pet
              echo pet >>"$state"
            fi
            echo "Desktop widgets hidden"
          }

          show() {
            if [ -f "$state" ]; then
              ${run widgets.show} || true
              if grep -qx pet "$state"; then
                systemctl --user start vayume-pet
              fi
              rm -f "$state"
            fi
            echo "Desktop widgets shown"
          }

          case "''${1:-toggle}" in
          hide) [ -f "$state" ] || hide ;;
          show) show ;;
          toggle) if [ -f "$state" ]; then show; else hide; fi ;;
          status) if [ -f "$state" ]; then echo hidden; else echo shown; fi ;;
          *)
            echo "usage: vayume widgets [toggle|show|hide|status]" >&2
            exit 2
            ;;
          esac
        '';
      };

      themeScript = pkgs.writeShellScriptBin "vayume-theme" ''
        if [ -e "''${XDG_STATE_HOME:-$HOME/.local/state}/vayume/saver-active" ] && [ "''${VAYUME_THEME_FORCE:-}" != 1 ]; then
          echo "the ultra power saver is on - theme left as it is (VAYUME_THEME_FORCE=1 overrides)" >&2
          exit 0
        fi
        wall="''${1:-}"
        if [ -z "$wall" ]; then
          wall="$(${run cmds."wallpaper-get" or null} 2>/dev/null || true)"
        fi
        if [ -z "$wall" ] || [ ! -f "$wall" ]; then
          echo "no wallpaper to theme from" >&2
          exit 1
        fi
        mode="''${SCHEME_MODE:-''${NOCTALIA_THEME_MODE:-dark}}"
        case "$mode" in light) ;; *) mode=dark ;; esac
        exec ${pkgs.matugen}/bin/matugen image "$wall" --type scheme-content --mode "$mode"
      '';

      wallpapers = config.vayume.desktop.wallpapers;
      defaultWallpaper = "${wallpapers}/wallhaven-w5xdzx.jpg";

      initScript = pkgs.writeShellScript "vayume-shell-init" ''
        get() { ${run cmds."wallpaper-get" or null}; }
        for _ in $(seq 1 40); do
          if get >/dev/null 2>&1; then break; fi
          sleep 1
        done
        current="$(get 2>/dev/null || true)"
        if [ -z "$current" ] || [ ! -f "$current" ]; then
          ${
            run (
              if (cmds."wallpaper-set" or null) == null then
                null
              else
                cmds."wallpaper-set" ++ [ defaultWallpaper ]
            )
          } || true
          sleep 2
        fi
        ${themeScript}/bin/vayume-theme || true
      '';

      lockCmd =
        if (cmds.lock or null) != null then
          lib.escapeShellArgs cmds.lock
        else
          "${pkgs.swaylock}/bin/swaylock -f";
    in
    {
      options.vayume.desktop = {
        shell = lib.mkOption {
          type = lib.types.enum [
            "dms"
            "noctalia"
            "caelestia"
          ];
          default = "dms";
          description = ''
            The desktop shell: bar, notifications, OSD and control center.
            Only the selected shell is built, so changing this needs a
            rebuild.
          '';
        };

        shellCommands = lib.mkOption {
          type = lib.types.attrsOf (lib.types.nullOr (lib.types.listOf lib.types.str));
          default = { };
          internal = true;
          description = ''
            What `vayume shell <action>` runs, set by the selected shell's
            module, plus the launcher, clipboard, powermenu and lock
            commands. A null or missing entry means the shell has no
            equivalent: the four fallback-capable ones then use Vayume's own
            tool (rofi, cliphist, wlogout, swaylock), the rest notify.
          '';
        };

        themeSync = lib.mkOption {
          type = lib.types.str;
          default = lib.getExe themeScript;
          readOnly = true;
          internal = true;
          description = "Command that re-renders the matugen templates from the current wallpaper, for shells that run a hook when it changes.";
        };

        wallpapers = lib.mkOption {
          type = lib.types.path;
          default = ../assets/wallpapers;
          internal = true;
          description = "Folder of wallpapers every shell is pointed at.";
        };

        shellWidgets = lib.mkOption {
          type = lib.types.submodule {
            options = {
              show = lib.mkOption {
                type = lib.types.nullOr (lib.types.listOf lib.types.str);
                default = null;
              };
              hide = lib.mkOption {
                type = lib.types.nullOr (lib.types.listOf lib.types.str);
                default = null;
              };
            };
          };
          default = { };
          internal = true;
          description = "Show/hide commands for the shell's own desktop widgets, used by `vayume widgets` on shells other than DMS.";
        };
      };

      config = {
        vayume.settingsGroups."Desktop shell" = {
          icon = "dashboard";
          description = "Which shell draws the bar, notifications and OSD. Only the selected one is built.";
          page = "appearance";
        };

        vayume.settingsMeta."desktop.shell" = {
          label = "Shell";
          icon = "dashboard";
          group = "Desktop shell";
          order = 1;
        };

        vayume.commands.shell = {
          command = lib.getExe vayumeShell;
          description = "Run a desktop shell action (bar, settings, wallpaper, screenshot)";
          usage = "<${lib.concatStringsSep "|" actions}>";
        };

        vayume.commands.theme = {
          command = lib.getExe themeScript;
          description = "Re-theme GTK, Qt and the other matugen apps from a wallpaper";
          usage = "[wallpaper]";
        };

        security.pam.services.swaylock = lib.mkIf ((cmds.lock or null) == null) { };

        vayume.commands.widgets = lib.mkIf (shell != "dms") {
          command = lib.getExe widgetsScript;
          description = "Hide or show every desktop widget and the desktop pet";
          usage = "[toggle|show|hide|status]";
          panel = {
            label = "Show or hide desktop widgets";
            icon = "visibility_off";
            args = [ "toggle" ];
            page = "appearance";
            group = "Desktop";
          };
        };

        home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
          systemd.user.services.vayume-idle-lock =
            let
              niri = "${pkgs.niri}/bin/niri";
              systemctl = "${pkgs.systemd}/bin/systemctl";
              lockArgs = lib.optionals (power.idleLock > 0) [
                "timeout"
                (toString power.idleLock)
                lockCmd
                "before-sleep"
                lockCmd
              ];
              screenOffArgs = lib.optionals (power.idleScreenOff > 0) [
                "timeout"
                (toString power.idleScreenOff)
                "${niri} msg action power-off-monitors"
                "resume"
                "${niri} msg action power-on-monitors"
              ];
              suspendArgs = lib.optionals (power.idleSuspend > 0) [
                "timeout"
                (toString power.idleSuspend)
                "${systemctl} suspend"
              ];
              args = lockArgs ++ screenOffArgs ++ suspendArgs;
              enabled = args != [ ];
            in
            lib.mkIf enabled {
              Unit = {
                Description = "Lock screen and manage display power on idle";
                After = [ "graphical-session.target" ];
                PartOf = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = lib.escapeShellArgs (
                  [
                    "${pkgs.swayidle}/bin/swayidle"
                    "-w"
                  ]
                  ++ args
                );
                Restart = "on-failure";
                Environment = [ "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin" ];
              };
              Install.WantedBy = [ "graphical-session.target" ];
            };

          systemd.user.services.vayume-shell-init = lib.mkIf (shell != "dms") {
            Unit = {
              Description = "Give the shell a wallpaper and theme the apps from it";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${initScript}";
              Environment = [ "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin" ];
            };
            Install.WantedBy = [ "graphical-session.target" ];
          };

          systemd.user.services.vayume-media-inhibit = {
            Unit = {
              Description = "Hold an idle inhibitor while audio or video is playing";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${pkgs.wayland-pipewire-idle-inhibit}/bin/wayland-pipewire-idle-inhibit";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "graphical-session.target" ];
          };
        });
      };
    };
}
