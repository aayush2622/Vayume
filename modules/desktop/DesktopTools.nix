# Launcher, lock screen, clipboard history and power menu, independent of
# DMS. Themed through the same matugen pipeline as everything else in
# modules/desktop/matugen (see Theming.nix for the pattern this follows).
{ self, ... }:
{
  flake.homeModules.DesktopTools =
    {
      pkgs,
      lib,
      config,
      vayumeTheme,
      ...
    }:
    let
      rofi = lib.getExe pkgs.rofi;
      cliphist = lib.getExe' pkgs.cliphist "cliphist";
      pkill = "${pkgs.procps}/bin/pkill";
      rofiDir = "${config.xdg.configHome}/rofi";

      launcher = pkgs.writeShellScriptBin "vayume-launcher" ''
        ${pkill} -x rofi && exit 0
        exec ${rofi} -show combi
      '';

      # DMS's own lock screen - swaylock was tried and dropped.
      lock = pkgs.writeShellScriptBin "vayume-lock" ''
        exec dms ipc call lock lock
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
    in
    {
      home.packages = [
        pkgs.rofi
        pkgs.cliphist
        pkgs.wlogout
        pkgs.wl-clipboard
        launcher
        lock
        powerMenu
        logout
        clipboardPicker
      ];

      home.file = {
        ".config/matugen/templates/rofi.rasi".text = self.matugenTemplates.rofi {
          font = vayumeTheme.font;
          iconTheme = vayumeTheme.iconTheme;
        };
        ".config/rofi/clipboard.rasi".text =
          builtins.replaceStrings [ "VAYUME_BASE_TOKEN" ] [ "${rofiDir}/config.rasi" ]
            (builtins.readFile ./matugen/rofi/clipboard.rasi);
        ".config/matugen/templates/wlogout-style.css".text = self.matugenTemplates.wlogout;

        ".config/wlogout/layout".source = ./matugen/wlogout/layout.json;
      };

      vayume.matugenTemplates.desktopTools = ''
        [templates.rofi]
        input_path = '${config.home.homeDirectory}/.config/matugen/templates/rofi.rasi'
        output_path = '${rofiDir}/config.rasi'

        [templates.wlogout]
        input_path = '${config.home.homeDirectory}/.config/matugen/templates/wlogout-style.css'
        output_path = '${config.home.homeDirectory}/.config/wlogout/style.css'
      '';

      systemd.user.services.vayume-cliphist = {
        Unit.Description = "Clipboard history watcher (cliphist)";
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${lib.getExe' pkgs.cliphist "cliphist"} store & ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${lib.getExe' pkgs.cliphist "cliphist"} store & wait'";
          Restart = "on-failure";
        };
      };
    };
}
