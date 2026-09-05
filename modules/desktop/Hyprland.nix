{
  flake.nixosModules.Hyprland = { ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  flake.homeModules.Hyprland =
  { lib, ... }:
  let
  lua = lib.generators.mkLuaInline;

  keys = k: lua ''mod .. " + ${k}"'';
  bareKeys = k: k;

  spawn = cmd: lua ''hl.dsp.exec_cmd("${cmd}")'';
  dms = cmd: spawn "dms ipc call ${cmd}";

  bind = k: dispatcher: { _args = [ (keys k) dispatcher ]; };
  bindBare = k: dispatcher: opts: { _args = [ (bareKeys k) dispatcher opts ]; };

  brightness = dir:
  spawn ''dms ipc call brightness ${dir} 5 \"$(dms ipc call brightness list | awk '$1 ~ /^backlight:/ {print $1; exit}')\"'';

  directions = {
    Left = "left";
    Right = "right";
    Up = "up";
    Down = "down";
  };

  focusBinds = lib.mapAttrsToList
  (key: dir: bind key (lua ''hl.dsp.focus({ direction = "${dir}" })''))
  directions;

  moveBinds = lib.mapAttrsToList
  (key: dir: bind "SHIFT + ${key}" (lua ''hl.dsp.window.move({ direction = "${dir}" })''))
  directions;

  workspaceBinds = lib.concatMap
  (n:
    let key = if n == 10 then "0" else toString n;
    in [
      (bind key (lua "hl.dsp.focus({ workspace = ${toString n} })"))
      (bind "SHIFT + ${key}" (lua "hl.dsp.window.move({ workspace = ${toString n} })"))
  ])
  (lib.range 1 10);
  in
  {
    wayland.windowManager.hyprland = {
      enable = true;

      configType = "lua";

      settings = {
        mod = { _var = "SUPER"; };

        env = [
          { _args = [ "QT_QPA_PLATFORMTHEME" "qt6ct" ]; }
          { _args = [ "QT_QPA_PLATFORMTHEME_QT6" "qt6ct" ]; }
          { _args = [ "WLR_NO_HARDWARE_CURSORS" "1" ]; }
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
            active_opacity = 1;
            inactive_opacity = 1;

            blur = {
              enabled = true;
              brigheness = 0.8;
              passes = 2;
              size = 4;
              noise = 0.02;
              vibrancy = 0.35;

              vibrancy_darkness = 0.35;
              contrast = 2;
            };

            shadow = {
              enabled = true;
              range = 30;
              render_power = 4;
            };
          };

          dwindle.preserve_split = true;

          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };
        };

        bind = [
          (bind "RETURN" (spawn "kitty"))
          (bind "E" (spawn "nautilus"))
          (bind "C" (spawn "code"))
          (bind "B" (spawn "zen"))
          (bind "SHIFT + B" (spawn "vayori-zen-reload"))
          (bindBare "CTRL + SHIFT + ESCAPE" (spawn "kitty -e btop") { })

          (bind "S" (dms "spotlight toggle"))
          (bind "A" (dms "spotlight toggle"))
          (bind "V" (dms "clipboard toggle"))
          (bind "COMMA" (dms "settings toggle"))
          (bind "L" (dms "lock lock"))
          (bind "SHIFT + W" (spawn "dms ipc wallpaperCarousel open"))

          (bind "Q" (lua "hl.dsp.window.close()"))
          (bindBare "ALT + F4" (lua "hl.dsp.window.close()") { })
          (bind "W" (lua ''hl.dsp.window.float({ action = "toggle" })''))
          (bind "F" (lua "hl.dsp.window.fullscreen()"))
          (bindBare "SHIFT + F11" (lua "hl.dsp.window.fullscreen()") { })
          (bind "J" (lua "hl.dsp.group.toggle()"))
          (bind "R" (lua "hl.dsp.window.pseudo()"))
          (bind "TAB" (lua "hl.dsp.window.cycle_next()"))

          (bind "SHIFT + P" (spawn "hyprpicker -a"))

          (bindBare "PRINT" (spawn "grim - | wl-copy") { })
          (bindBare "SHIFT + PRINT" (spawn "grim - | wl-copy") { })
          (bind "SHIFT + S" (spawn ''grim -g \"$(slurp)\" - | wl-copy''))

          (bind "CTRL + Right" (lua ''hl.dsp.focus({ workspace = "e+1" })''))
          (bind "CTRL + Left" (lua ''hl.dsp.focus({ workspace = "e-1" })''))
          (bind "mouse_down" (lua ''hl.dsp.focus({ workspace = "e+1" })''))
          (bind "mouse_up" (lua ''hl.dsp.focus({ workspace = "e-1" })''))

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

          (bindBare "XF86AudioRaiseVolume" (dms "audio increment 5") { locked = true; repeating = true; })
          (bindBare "XF86AudioLowerVolume" (dms "audio decrement 5") { locked = true; repeating = true; })
          (bindBare "XF86MonBrightnessUp" (brightness "increment") { locked = true; repeating = true; })
          (bindBare "XF86MonBrightnessDown" (brightness "decrement") { locked = true; repeating = true; })
        ] ++ focusBinds ++ moveBinds ++ workspaceBinds;
      };
    };
  };
}
