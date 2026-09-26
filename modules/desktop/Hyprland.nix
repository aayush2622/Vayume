{
  flake.nixosModules.Hyprland =
    { lib, config, ... }:
    {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      programs.ydotool.enable = true;
      users.groups.ydotool.members = lib.attrNames config.vayume.users;
    };

  flake.homeModules.Hyprland =
    {
      lib,
      pkgs,
      self,
      vayumeTheme,
      ...
    }:
    let
      actions = lib.mapAttrs (_: lib.concatStringsSep " ") (self.vayumeLib.mkDesktopActions pkgs);
      lua = lib.generators.mkLuaInline;

      typeClipboard = pkgs.writeShellScriptBin "vayume-type-clipboard" ''
        set -euo pipefail

        pidfile="''${XDG_RUNTIME_DIR:-/tmp}/vayume-type-clipboard.pid"
        if [ -e "$pidfile" ]; then
          running="$(${pkgs.coreutils}/bin/cat "$pidfile")"
          if ${pkgs.coreutils}/bin/kill -0 "$running" 2>/dev/null; then
            ${pkgs.procps}/bin/pkill -P "$running" || true
            ${pkgs.coreutils}/bin/kill "$running" || true
            ${pkgs.coreutils}/bin/rm -f "$pidfile"
            exit 0
          fi
        fi
        echo $$ > "$pidfile"
        trap '${pkgs.coreutils}/bin/rm -f "$pidfile"' EXIT

        delay="''${1:-8}"

        export YDOTOOL_SOCKET="''${YDOTOOL_SOCKET:-/run/ydotoold/socket}"

        ${pkgs.coreutils}/bin/sleep "''${2:-1}"

        ${pkgs.wl-clipboard}/bin/wl-paste --no-newline \
          | ${pkgs.ydotool}/bin/ydotool type --key-delay "$delay" --file -
      '';

      keys = k: lua ''mod .. " + ${k}"'';
      bareKeys = k: k;

      spawn = cmd: lua ''hl.dsp.exec_cmd("${cmd}")'';
      dms = cmd: spawn "dms ipc call ${cmd}";

      bind = k: dispatcher: {
        _args = [
          (keys k)
          dispatcher
        ];
      };
      bindBare = k: dispatcher: opts: {
        _args = [
          (bareKeys k)
          dispatcher
          opts
        ];
      };
      bindOpt = k: dispatcher: opts: {
        _args = [
          (keys k)
          dispatcher
          opts
        ];
      };

      brightness =
        dir:
        spawn ''dms ipc call brightness ${dir} 5 \"$(dms ipc call brightness list | awk '$1 ~ /^backlight:/ {print $1; exit}')\"'';

      directions = {
        Left = "left";
        Right = "right";
        Up = "up";
        Down = "down";
      };

      focusBinds = lib.mapAttrsToList (
        key: dir: bind key (lua ''hl.dsp.focus({ direction = "${dir}" })'')
      ) directions;

      moveBinds = lib.mapAttrsToList (
        key: dir: bind "SHIFT + ${key}" (lua ''hl.dsp.window.move({ direction = "${dir}" })'')
      ) directions;

      silentBinds = lib.concatMap (
        n:
        let
          key = if n == 10 then "0" else toString n;
        in
        [
          (bind "ALT + ${key}" (lua "hl.dsp.window.move({ workspace = ${toString n}, silent = true })"))
        ]
      ) (lib.range 1 10);

      workspaceBinds = lib.concatMap (
        n:
        let
          key = if n == 10 then "0" else toString n;
        in
        [
          (bind key (lua "hl.dsp.focus({ workspace = ${toString n} })"))
          (bind "SHIFT + ${key}" (lua "hl.dsp.window.move({ workspace = ${toString n} })"))
        ]
      ) (lib.range 1 10);
    in
    {

      wayland.windowManager.hyprland = {
        enable = true;

        configType = "lua";

        systemd.variables = [ "--all" ];

        settings = {
          mod = {
            _var = "SUPER";
          };

          env = [
            {
              _args = [
                "QT_QPA_PLATFORMTHEME"
                "qt6ct"
              ];
            }
            {
              _args = [
                "QT_QPA_PLATFORMTHEME_QT6"
                "qt6ct"
              ];
            }
            {
              _args = [
                "WLR_NO_HARDWARE_CURSORS"
                "1"
              ];
            }
          ];

          config = {
            input = {
              kb_layout = "us";
              follow_mouse = 1;

              touchpad = {
                natural_scroll = true;
                tap_to_click = true;
              };
            };

            general = {
              gaps_in = 4;
              gaps_out = 8;
              border_size = 1;
              "col.active_border" = "rgba(ffffff40)";
              "col.inactive_border" = "rgba(ffffff15)";
              layout = "dwindle";
            };

            decoration = {
              rounding = 24;

              active_opacity = 0.85;
              inactive_opacity = 0.80;
              blur = {
                enabled = true;
                brightness = 0.8;
                passes = 3;
                size = 7;
                noise = 0.02;
                vibrancy = 0.35;

                vibrancy_darkness = 0.35;
                contrast = 1.0;
                new_optimizations = true;
                ignore_opacity = true;
                xray = true;
                popups = true;
              };

              shadow = {
                enabled = true;
                range = 30;
                render_power = 4;
              };
            };

            dwindle.preserve_split = true;

            cursor.no_warps = true;

            misc = {
              font_family = vayumeTheme.font;
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
            };
          };

          window_rule = [
            {
              name = "zen-pip-float";
              match = {
                class = "^zen$";
                title = "^Picture-in-Picture$";
              };
              float = true;
              pin = true;
            }
            {
              name = "waydroid-float";
              match.class = "^waydroid\\..*$";
              float = true;
              size = "900 1100";
              center = true;
            }
          ];

          layer_rule = [
            {
              name = "dms-blur";
              match = {
                namespace = "^dms:.*$";
              };
              blur = true;
              blur_popups = true;
              xray = true;
              ignore_alpha = 0.2;
            }
          ];

          bind = [
            (bind "RETURN" (spawn actions.terminal))
            (bind "E" (spawn actions.fileManager))
            (bind "C" (spawn actions.editor))
            (bind "B" (spawn actions.browser))
            (bind "SHIFT + B" (spawn actions.browserReload))
            (bindBare "CTRL + SHIFT + ESCAPE" (spawn actions.systemMonitor) { })

            (bind "S" (lua "hl.dsp.workspace.toggle_special()"))
            (bind "A" (dms "spotlight toggle"))
            (bind "V" (dms "clipboard toggle"))
            (bindBare "ALT + V" (spawn (lib.getExe typeClipboard)) { })
            (bind "COMMA" (dms "settings toggle"))
            (bind "L" (dms "lock lock"))
            (bind "SHIFT + W" (spawn "dms ipc wallpaperCarousel open"))

            (bind "Q" (lua "hl.dsp.window.close()"))
            (bindBare "ALT + F4" (lua "hl.dsp.window.close()") { })
            (bind "W" (lua ''hl.dsp.window.float({ action = "toggle" })''))
            (bind "F" (lua "hl.dsp.window.fullscreen()"))
            (bindBare "SHIFT + F11" (lua "hl.dsp.window.fullscreen()") { })
            (bind "G" (lua "hl.dsp.group.toggle()"))
            (bind "J" (lua ''hl.dsp.layout("togglesplit")''))
            (bind "SHIFT + F" (lua "hl.dsp.window.pin()"))
            (bind "CTRL + H" (lua "hl.dsp.group.prev()"))
            (bind "CTRL + L" (lua "hl.dsp.group.next()"))
            (bind "DELETE" (lua "hl.dsp.exit()"))
            (bind "ESCAPE" (dms "fullscreenPowerMenu toggle"))
            (bind "R" (lua "hl.dsp.window.pseudo()"))
            (bind "TAB" (lua "hl.dsp.window.cycle_next()"))

            (bind "SHIFT + P" (spawn actions.colorPicker))

            (bindBare "PRINT" (dms "screenshotPlus capture") { })
            (bindBare "SHIFT + PRINT" (spawn "hyprshot -m output") { })
            (bind "PRINT" (spawn "hyprshot -m window -z --clipboard-only"))

            (bind "CTRL + Right" (lua ''hl.dsp.focus({ workspace = "e+1" })''))
            (bind "CTRL + Left" (lua ''hl.dsp.focus({ workspace = "e-1" })''))
            (bind "mouse_down" (lua ''hl.dsp.focus({ workspace = "e+1" })''))
            (bind "mouse_up" (lua ''hl.dsp.focus({ workspace = "e-1" })''))
            (bind "CTRL + Down" (lua ''hl.dsp.focus({ workspace = "empty" })''))
            (bind "CTRL + ALT + Right" (lua ''hl.dsp.window.move({ workspace = "r+1" })''))
            (bind "CTRL + ALT + Left" (lua ''hl.dsp.window.move({ workspace = "r-1" })''))
            (bind "ALT + S" (lua ''hl.dsp.window.move({ workspace = "special" })''))

            (bind "ALT + Right" (dms "wallpaper next"))
            (bind "ALT + Left" (dms "wallpaper prev"))

            (bindOpt "mouse:272" (lua "hl.dsp.window.drag()") { mouse = true; })
            (bindOpt "mouse:273" (lua "hl.dsp.window.resize()") { mouse = true; })
            (bindOpt "Z" (lua "hl.dsp.window.drag()") { mouse = true; })
            (bindOpt "X" (lua "hl.dsp.window.resize()") { mouse = true; })

            (bind "SHIFT + CTRL + Right" (lua "hl.dsp.window.resize({ x = 40, y = 0, relative = true })"))
            (bind "SHIFT + CTRL + Left" (lua "hl.dsp.window.resize({ x = -40, y = 0, relative = true })"))
            (bind "SHIFT + CTRL + Up" (lua "hl.dsp.window.resize({ x = 0, y = -40, relative = true })"))
            (bind "SHIFT + CTRL + Down" (lua "hl.dsp.window.resize({ x = 0, y = 40, relative = true })"))

            (bindBare "XF86AudioMute" (dms "audio mute") { locked = true; })
            (bindBare "XF86AudioMicMute" (dms "mic mute") { locked = true; })
            (bindBare "XF86AudioPlay" (spawn "playerctl play-pause") { locked = true; })
            (bindBare "XF86AudioPause" (spawn "playerctl play-pause") { locked = true; })
            (bindBare "XF86AudioNext" (spawn "playerctl next") { locked = true; })
            (bindBare "XF86AudioPrev" (spawn "playerctl previous") { locked = true; })

            (bindBare "XF86AudioRaiseVolume" (dms "audio increment 5") {
              locked = true;
              repeating = true;
            })
            (bindBare "XF86AudioLowerVolume" (dms "audio decrement 5") {
              locked = true;
              repeating = true;
            })
            (bindBare "XF86MonBrightnessUp" (brightness "increment") {
              locked = true;
              repeating = true;
            })
            (bindBare "XF86MonBrightnessDown" (brightness "decrement") {
              locked = true;
              repeating = true;
            })
          ]
          ++ focusBinds
          ++ moveBinds
          ++ workspaceBinds
          ++ silentBinds;
        };
      };
    };
}
