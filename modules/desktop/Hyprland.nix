{
  flake.nixosModules.Hyprland = { ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  flake.homeModules.Hyprland =
    { pkgs, lib, ... }:
    let
      dms = cmd: "dms ipc call ${cmd}";

      workspaceBinds = lib.concatMap
        (n:
          let key = if n == 10 then "0" else toString n;
          in [
            "$mod, ${key}, workspace, ${toString n}"
            "$mod SHIFT, ${key}, movetoworkspace, ${toString n}"
          ])
        (lib.range 1 10);
    in
    {
      wayland.windowManager.hyprland = {
        enable = true;

        settings = {
          "$mod" = "SUPER";

          env = [
            "QT_QPA_PLATFORMTHEME,qt6ct"
            "QT_QPA_PLATFORMTHEME_QT6,qt6ct"
            "WLR_NO_HARDWARE_CURSORS,1"
          ];

          input = {
            kb_layout = "us";
            follow_mouse = 1;

            touchpad = {
              natural_scroll = true;
              tap-to-click = true;
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
            rounding = 14;
            active_opacity = 0.90;
            inactive_opacity = 0.90;

            blur = {
              enabled = true;
              passes = 2;
              size = 4;
              noise = 0.02;
              vibrancy = 0.15;
            };

            shadow = {
              enabled = true;
              range = 30;
              render_power = 4;
            };
          };

          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          bind = [
            "$mod, Return, exec, kitty"
            "$mod, E, exec, nautilus"
            "$mod, C, exec, code"
            "$mod, B, exec, zen"
            "$mod SHIFT, B, exec, vayori-zen-reload"
            "CTRL SHIFT, Escape, exec, kitty -e btop"

            "$mod, S, exec, ${dms "spotlight toggle"}"
            "$mod, A, exec, ${dms "spotlight toggle"}"
            "$mod, V, exec, ${dms "clipboard toggle"}"
            "$mod, comma, exec, ${dms "settings toggle"}"
            "$mod, L, exec, ${dms "lock lock"}"
            "$mod SHIFT, W, exec, dms ipc wallpaperCarousel open"

            "$mod, Q, killactive"
            "ALT, F4, killactive"
            "$mod, W, togglefloating"
            "$mod, F, fullscreen"
            "SHIFT, F11, fullscreen"
            "$mod, J, togglegroup"
            "$mod, R, pseudo"
            "$mod, Tab, cyclenext"

            "$mod SHIFT, P, exec, hyprpicker -a"

            # niri has screenshotting built in; hyprland does not, so these
            # use the grim/slurp pair already in environment.systemPackages.
            ", Print, exec, grim - | wl-copy"
            "SHIFT, Print, exec, grim - | wl-copy"
            "$mod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"

            "$mod, Left, movefocus, l"
            "$mod, Right, movefocus, r"
            "$mod, Up, movefocus, u"
            "$mod, Down, movefocus, d"

            "$mod SHIFT, Left, movewindow, l"
            "$mod SHIFT, Right, movewindow, r"
            "$mod SHIFT, Up, movewindow, u"
            "$mod SHIFT, Down, movewindow, d"

            "$mod CTRL, Right, workspace, e+1"
            "$mod CTRL, Left, workspace, e-1"
            "$mod, mouse_down, workspace, e+1"
            "$mod, mouse_up, workspace, e-1"
          ] ++ workspaceBinds;

          binde = [
            "$mod SHIFT CTRL, Right, resizeactive, 40 0"
            "$mod SHIFT CTRL, Left, resizeactive, -40 0"
            "$mod SHIFT CTRL, Up, resizeactive, 0 -40"
            "$mod SHIFT CTRL, Down, resizeactive, 0 40"
          ];

          # bindl fires even with the screen locked; bindel also repeats.
          bindl = [
            ", XF86AudioMute, exec, ${dms "audio mute"}"
            ", XF86AudioMicMute, exec, ${dms "mic mute"}"
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPrev, exec, playerctl previous"
          ];

          bindel = [
            ", XF86AudioRaiseVolume, exec, ${dms "audio increment 5"}"
            ", XF86AudioLowerVolume, exec, ${dms "audio decrement 5"}"
            ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5"
            ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5"
          ];

          windowrulev2 = [
            "opacity 0.90 0.90, class:.*"
          ];
        };
      };
    };
}
