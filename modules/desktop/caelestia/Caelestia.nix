{ inputs, ... }:
{
  flake.nixosModules.Caelestia =
    { config, lib, ... }:
    {
      config = lib.mkIf (config.vayume.desktop.shell == "caelestia") {
        warnings = [
          "vayume.desktop.shell = \"caelestia\": Caelestia targets Hyprland (its keybinds are Hyprland global shortcuts), so on niri only the bar, drawers and IPC are expected to work."
        ];

        vayume.desktop.shellCommands = {
          bar = null;
          settings = [
            "caelestia"
            "shell"
            "drawers"
            "toggle"
            "dashboard"
          ];
          wallpaper = null;
          wallpaper-next = [
            "caelestia"
            "wallpaper"
            "-r"
          ];
          wallpaper-prev = null;
          wallpaper-get = [
            "sh"
            "-c"
            "cat \"\${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/wallpaper/path.txt\""
          ];
          wallpaper-set = [
            "caelestia"
            "wallpaper"
            "-f"
          ];
          screenshot = [
            "caelestia"
            "shell"
            "picker"
            "open"
          ];
          launcher = [
            "caelestia"
            "shell"
            "drawers"
            "toggle"
            "launcher"
          ];
          clipboard = null;
          powermenu = [
            "caelestia"
            "shell"
            "drawers"
            "toggle"
            "session"
          ];
          lock = [
            "caelestia"
            "shell"
            "lock"
            "lock"
          ];
        };

        home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
          imports = [ inputs.caelestia-shell.homeManagerModules.default ];

          programs.caelestia = {
            enable = true;
            systemd.enable = true;
            cli = {
              enable = true;
              settings.wallpaper.postHook = "${config.vayume.desktop.themeSync} \"$WALLPAPER_PATH\"";
            };
            settings.paths.wallpaperDir = "${config.vayume.desktop.wallpapers}";
          };
        });
      };
    };
}
