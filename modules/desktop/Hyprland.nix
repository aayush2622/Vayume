{
  flake.nixosModules.Hyprland =
    { lib, config, ... }:
    {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      # Backend for vayume-type-clipboard. ydotool injects real evdev key
      # events via /dev/uinput, so they pass through the compositor's own
      # keymap - unlike wtype's virtual-keyboard keymap, which Chromium /
      # Electron apps (NeoColab, exam browsers, ...) garble into random
      # characters. Enabling this adds a hardened `ydotoold` system
      # service and an `ydotool` group; every configured user joins it.
      programs.ydotool.enable = true;
      users.groups.ydotool.members = lib.attrNames config.vayume.users;
    };

  flake.homeModules.Hyprland =
    { lib, pkgs, ... }:
    let
      lua = lib.generators.mkLuaInline;

      # Types out the current clipboard as synthetic keystrokes instead of
      # pasting - for fields that swallow a real paste (some password
      # prompts, SPICE/VNC consoles, remote sessions, exam browsers).
      #
      # Uses ydotool (real evdev events, needs the ydotoold service from
      # the nixos module above) rather than wtype, because apps that read
      # raw key positions turn wtype's output into gibberish. ASCII only -
      # non-ASCII bytes in the clipboard are skipped.
      typeClipboard = pkgs.writeShellScriptBin "vayume-type-clipboard" ''
        set -euo pipefail

        # Per-keystroke delay in ms; override as the first argument.
        delay="''${1:-8}"

        export YDOTOOL_SOCKET="''${YDOTOOL_SOCKET:-/run/ydotoold/socket}"

        # Grace period to refocus / click into the target field before
        # the keystrokes start. Override as the second argument.
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
      home.packages = [ typeClipboard ];

      wayland.windowManager.hyprland = {
        enable = true;

        configType = "lua";

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

              active_opacity = 0.90;
              inactive_opacity = 0.80;
              blur = {
                enabled = true;
                brightness = 0.8;
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
            (bind "E" (spawn "thunar"))
            (bind "C" (spawn "code"))
            (bind "B" (spawn "zen"))
            (bind "SHIFT + B" (spawn "vayume-zen-reload"))
            (bindBare "CTRL + SHIFT + ESCAPE" (spawn "kitty -e btop") { })

            (bind "S" (lua "hl.dsp.workspace.toggle_special()"))
            (bind "A" (dms "spotlight toggle"))
            (bind "V" (dms "clipboard toggle"))
            (bindBare "ALT + V" (spawn "vayume-type-clipboard") { })
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
            (bind "R" (lua "hl.dsp.window.pseudo()"))
            (bind "TAB" (lua "hl.dsp.window.cycle_next()"))

            (bind "SHIFT + P" (spawn "hyprpicker -a"))

            # Only Shift+Print writes a file. The interactive grabs go to
            # the clipboard and nowhere else - hyprshot's --clipboard-only.
            (bindBare "PRINT" (spawn "hyprshot -m region -z --clipboard-only") { })
            (bindBare "SHIFT + PRINT" (spawn "hyprshot -m output") { })
            (bind "PRINT" (spawn "hyprshot -m window -z --clipboard-only"))
            (bind "SHIFT + S" (spawn "hyprshot -m region -z --clipboard-only"))

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
