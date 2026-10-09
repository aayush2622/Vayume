{ self, ... }:
{
  flake.homeModules.DesktopTools =
    {
      pkgs,
      lib,
      config,
      vayumeTheme,
      vayumeShellCommands,
      ...
    }:
    let
      native = name: vayumeShellCommands.${name} or null;
      falls = name: native name == null;
      fallsAny = names: lib.any falls names;

      rofi = lib.getExe pkgs.rofi;
      cliphist = lib.getExe' pkgs.cliphist "cliphist";
      pkill = "${pkgs.procps}/bin/pkill";
      rofiDir = "${config.xdg.configHome}/rofi";

      nativeScript =
        name:
        pkgs.writeShellScript "vayume-${name}-native" ''
          exec ${lib.escapeShellArgs (native name)}
        '';

      pick = name: fallback: if falls name then lib.getExe fallback else "${nativeScript name}";

      launcher = pkgs.writeShellScriptBin "vayume-launcher" ''
        ${pkill} -x rofi && exit 0
        exec ${rofi} -show combi
      '';

      lock = pkgs.writeShellScriptBin "vayume-lock" ''
        exec ${pkgs.swaylock}/bin/swaylock -f
      '';

      powerMenu = pkgs.writeShellScriptBin "vayume-powermenu" ''
        exec ${lib.getExe pkgs.wlogout}
      '';

      logout = pkgs.writeShellScriptBin "vayume-logout" ''
        if command -v niri >/dev/null 2>&1 && niri msg action quit --skip-confirmation 2>/dev/null; then
          exit 0
        fi
        exec ${pkgs.hyprland}/bin/hyprctl dispatch exit
      '';

      clipboardPicker = pkgs.writeShellScriptBin "vayume-clipboard" ''
        set -eu
        ${pkill} -x rofi && exit 0

        thumbs="''${XDG_CACHE_HOME:-$HOME/.cache}/vayume/cliphist-thumbs"
        mkdir -p "$thumbs"
        ${pkgs.findutils}/bin/find "$thumbs" -type f -mtime +7 -delete

        entries() {
          ${cliphist} list | while IFS= read -r line; do
            id=''${line%%$'\t'*}
            if [[ $line =~ \[\[\ binary\ data\ .*\ (png|jpe?g|bmp|webp|gif)\  ]]; then
              thumb="$thumbs/$id.''${BASH_REMATCH[1]}"
              [ -s "$thumb" ] || printf '%s\t\n' "$id" | ${cliphist} decode > "$thumb" || true
              printf '%s\0icon\x1f%s\n' "$line" "$thumb"
            else
              printf '%s\0icon\x1ftext-x-generic\n' "$line"
            fi
          done
        }

        theme=()
        [ -f ${rofiDir}/config.rasi ] && theme=(-theme ${rofiDir}/clipboard.rasi)

        sel="$(entries | ${rofi} -dmenu -i -show-icons -display-columns 2 "''${theme[@]}")" || exit 0
        [ -n "$sel" ] || exit 0
        printf '%s' "$sel" | ${cliphist} decode | ${pkgs.wl-clipboard}/bin/wl-copy
      '';

      home = config.home.homeDirectory;

      templateBlocks =
        lib.optional
          (fallsAny [
            "launcher"
            "clipboard"
          ])
          ''
            [templates.rofi]
            input_path = '${home}/.config/matugen/templates/rofi.rasi'
            output_path = '${rofiDir}/config.rasi'
          ''
        ++ lib.optional (falls "lock") ''
          [templates.swaylock]
          input_path = '${home}/.config/matugen/templates/swaylock.conf'
          output_path = '${home}/.config/swaylock/config'
        ''
        ++ lib.optional (falls "powermenu") ''
          [templates.wlogout]
          input_path = '${home}/.config/matugen/templates/wlogout-style.css'
          output_path = '${home}/.config/wlogout/style.css'
        '';
    in
    {
      home.packages =
        lib.optional (fallsAny [
          "launcher"
          "clipboard"
        ]) pkgs.rofi
        ++ lib.optionals (falls "clipboard") [
          pkgs.cliphist
          pkgs.wl-clipboard
        ]
        ++ lib.optional (falls "powermenu") pkgs.wlogout
        ++ lib.optional (falls "lock") pkgs.swaylock;

      vayume.commands = {
        launcher = {
          command = pick "launcher" launcher;
          description = "Open the app launcher";
        };
        clipboard = {
          command = pick "clipboard" clipboardPicker;
          description = "Open the clipboard history";
        };
        powermenu = {
          command = pick "powermenu" powerMenu;
          description = "Open the power menu";
        };
        lock = {
          command = pick "lock" lock;
          description = "Lock the screen";
        };
      }
      // lib.optionalAttrs (falls "powermenu") {
        logout = {
          command = lib.getExe logout;
          description = "End the session";
          confirm = true;
        };
      };

      home.file =
        lib.optionalAttrs
          (fallsAny [
            "launcher"
            "clipboard"
          ])
          {
            ".config/matugen/templates/rofi.rasi".text = self.matugenTemplates.rofi {
              font = vayumeTheme.font;
              iconTheme = vayumeTheme.iconTheme;
            };
          }
        // lib.optionalAttrs (falls "clipboard") {
          ".config/rofi/clipboard.rasi".text =
            builtins.replaceStrings [ "VAYUME_BASE_TOKEN" ] [ "${rofiDir}/config.rasi" ]
              (builtins.readFile ./matugen/rofi/clipboard.rasi);
        }
        // lib.optionalAttrs (falls "lock") {
          ".config/matugen/templates/swaylock.conf".text = self.matugenTemplates.swaylock;
        }
        // lib.optionalAttrs (falls "powermenu") {
          ".config/matugen/templates/wlogout-style.css".text = self.matugenTemplates.wlogout;
          ".config/wlogout/layout".source = ./matugen/wlogout/layout.json;
        };

      vayume.matugenTemplates.desktopTools = lib.mkIf (templateBlocks != [ ]) (
        lib.concatStringsSep "\n" templateBlocks
      );

      systemd.user.services.vayume-cliphist = lib.mkIf (falls "clipboard") {
        Unit.Description = "Clipboard history watcher (cliphist)";
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${cliphist} store & ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${cliphist} store & wait'";
          Restart = "on-failure";
        };
      };
    };
}
