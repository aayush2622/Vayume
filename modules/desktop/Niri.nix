{ self, inputs, ... }:
{
  flake.nixosModules.Niri = { pkgs, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.MyNiri;
    };
  };

  perSystem = { pkgs, lib, ... }:
  let
    niriBinds = {
      "Mod+Return".spawn = [ "kitty" ];
      "Mod+E".spawn = [ "nautilus" ];
      "Mod+C".spawn = [ "code" ];
      "Mod+B".spawn = [ "zen" ];
      "Control+Shift+Escape".spawn = [ "kitty" "-e" "btop" ];

      "Mod+S".spawn = [ "dms" "ipc" "call" "spotlight" "toggle" ];
      "Mod+V".spawn = [ "dms" "ipc" "call" "clipboard" "toggle" ];
      "Mod+Comma".spawn = [ "dms" "ipc" "call" "settings" "toggle" ];
      "Mod+Tab".toggle-overview = _: { };

      "Mod+Q".close-window = _: { };
      "Alt+F4".close-window = _: { };
      "Mod+Delete".quit = _: { };
      "Mod+W".toggle-window-floating = _: { };
      "Mod+F".fullscreen-window = _: { };
      "Shift+F11".fullscreen-window = _: { };
      "Mod+J".toggle-column-tabbed-display = _: { };
      "Mod+G".consume-window-into-column = _: { };
      "Mod+Shift+G".expel-window-from-column = _: { };
      "Mod+K".switch-layout = "next";
      "Mod+L".spawn = [ "dms" "ipc" "call" "lock" "lock" ];

      "Mod+Shift+W".spawn = [ "dms" "ipc" "wallpaperCarousel" "open" ];
      "Mod+A".spawn = [ "dms" "ipc" "call" "spotlight" "toggle" ];

      "Mod+Left".focus-column-left = _: { };
      "Mod+Right".focus-column-right = _: { };
      "Mod+Up".focus-window-up = _: { };
      "Mod+Down".focus-window-down = _: { };

      "Mod+Shift+Left".move-column-left = _: { };
      "Mod+Shift+Right".move-column-right = _: { };
      "Mod+Shift+Up".move-window-up = _: { };
      "Mod+Shift+Down".move-window-down = _: { };

      "Mod+Shift+Ctrl+Right".set-column-width = "+10%";
      "Mod+Shift+Ctrl+Left".set-column-width = "-10%";
      "Mod+Shift+Ctrl+Up".set-window-height = "-10%";
      "Mod+Shift+Ctrl+Down".set-window-height = "+10%";
      "Mod+R".switch-preset-column-width = _: { };

      "Mod+Shift+P".spawn = [ "hyprpicker" "-a" ];
      "Print".screenshot = _: { };
      "Shift+Print".screenshot-screen = _: { };
      "Mod+Shift+S".spawn = [ "dms" "ipc" "call" "niri" "screenshot" ];

      "XF86AudioMute".spawn = [ "dms" "ipc" "call" "audio" "mute" ];
      "XF86AudioLowerVolume".spawn = [ "dms" "ipc" "call" "audio" "decrement" "5" ];
      "XF86AudioRaiseVolume".spawn = [ "dms" "ipc" "call" "audio" "increment" "5" ];
      "XF86AudioMicMute".spawn = [ "dms" "ipc" "call" "mic" "mute" ];
      "XF86AudioPlay".spawn = [ "playerctl" "play-pause" ];
      "XF86AudioPause".spawn = [ "playerctl" "play-pause" ];
      "XF86AudioNext".spawn = [ "playerctl" "next" ];
      "XF86AudioPrev".spawn = [ "playerctl" "previous" ];
      "XF86MonBrightnessUp".spawn-sh =
        ''dms ipc call brightness increment 5 "$(dms ipc call brightness list | awk '$1 ~ /^backlight:/ {print $1; exit}')" '';
      "XF86MonBrightnessDown".spawn-sh =
        ''dms ipc call brightness decrement 5 "$(dms ipc call brightness list | awk '$1 ~ /^backlight:/ {print $1; exit}')" '';
      "Mod+1".focus-workspace = 1;
      "Mod+2".focus-workspace = 2;
      "Mod+3".focus-workspace = 3;
      "Mod+4".focus-workspace = 4;
      "Mod+5".focus-workspace = 5;
      "Mod+6".focus-workspace = 6;
      "Mod+7".focus-workspace = 7;
      "Mod+8".focus-workspace = 8;
      "Mod+9".focus-workspace = 9;
      "Mod+0".focus-workspace = 10;

      "Mod+Shift+1".move-window-to-workspace = 1;
      "Mod+Shift+2".move-window-to-workspace = 2;
      "Mod+Shift+3".move-window-to-workspace = 3;
      "Mod+Shift+4".move-window-to-workspace = 4;
      "Mod+Shift+5".move-window-to-workspace = 5;
      "Mod+Shift+6".move-window-to-workspace = 6;
      "Mod+Shift+7".move-window-to-workspace = 7;
      "Mod+Shift+8".move-window-to-workspace = 8;
      "Mod+Shift+9".move-window-to-workspace = 9;
      "Mod+Shift+0".move-window-to-workspace = 10;

      "Mod+Ctrl+Right".focus-workspace-down = _: { };
      "Mod+Ctrl+Left".focus-workspace-up = _: { };
      "Mod+WheelScrollDown".focus-workspace-down = _: { };
      "Mod+WheelScrollUp".focus-workspace-up = _: { };
    };
  in
  {
    packages.MyNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;

      extraSettings = [
        { include = [ { optional = true; } "~/.config/niri/dms/colors.kdl" ]; }
        {
          include = "${pkgs.writeText "niri-border-override.kdl" ''
            layout {
                border {
                    active-color "#ffffff40"
                    inactive-color "#ffffff15"
                }
            }
          ''}";
        }
      ];

      settings = {
        prefer-no-csd = true;

        environment = {
          QT_QPA_PLATFORMTHEME = "qt6ct";
          QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
        };

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
        input = {
          keyboard.xkb.layout = "us";
          focus-follows-mouse = _: { };

          touchpad = {
            tap = _: { };
            natural-scroll = _: { };
          };
        };

        layout = {
          gaps = 8;
          center-focused-column = "never";
          default-column-width.proportion = 0.5;
          focus-ring.off = _: { };
          border = {
            width = 1;
            active-color = "#ffffff40";
            inactive-color = "#ffffff15";
          };
          shadow = {
            softness = 30;
            spread = 4;
          };
        };

        window-rules = [
          {
            matches = [ { app-id = ".*"; } ];

            opacity = 0.90;

            geometry-corner-radius = [ 14 14 14 14 ];
            clip-to-geometry = true;

            background-effect = {
              blur = true;
              saturation = 1.15;
            };
          }
        ];

        blur = {
          passes = 2;
          offset = 4.0;
          noise = 0.02;
          saturation = 1.15;
        };
        binds = niriBinds;
      };
    };
  };
}
