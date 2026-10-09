{ inputs, ... }:
{
  flake.nixosModules.Noctalia =
    { config, lib, ... }:
    {
      config = lib.mkIf (config.vayume.desktop.shell == "noctalia") {
        vayume.desktop.shellCommands = {
          bar = [
            "noctalia"
            "msg"
            "bar-toggle"
          ];
          settings = [
            "noctalia"
            "msg"
            "settings-toggle"
          ];
          wallpaper = [
            "noctalia"
            "msg"
            "panel-toggle"
            "wallpaper"
          ];
          wallpaper-next = [
            "noctalia"
            "msg"
            "wallpaper-next"
          ];
          wallpaper-prev = [
            "noctalia"
            "msg"
            "wallpaper-previous"
          ];
          wallpaper-get = [
            "noctalia"
            "msg"
            "wallpaper-get"
          ];
          wallpaper-set = [
            "noctalia"
            "msg"
            "wallpaper-set"
          ];
          screenshot = [
            "noctalia"
            "msg"
            "screenshot-region"
          ];
          launcher = [
            "noctalia"
            "msg"
            "panel-toggle"
            "launcher"
          ];
          clipboard = [
            "noctalia"
            "msg"
            "panel-toggle"
            "clipboard"
          ];
          powermenu = [
            "noctalia"
            "msg"
            "panel-toggle"
            "session"
          ];
          lock = [
            "noctalia"
            "msg"
            "session"
            "lock"
          ];
        };

        vayume.desktop.shellWidgets = {
          show = [
            "noctalia"
            "msg"
            "desktop-widgets-show"
          ];
          hide = [
            "noctalia"
            "msg"
            "desktop-widgets-hide"
          ];
        };

        home-manager.users = lib.genAttrs (builtins.attrNames config.vayume.users) (name: {
          imports = [ inputs.noctalia-shell.homeModules.default ];

          programs.noctalia = {
            enable = true;
            systemd.enable = true;
            settings = {
              shell.font = config.vayume.theme.font;
              wallpaper.directory = "${config.vayume.desktop.wallpapers}";
              hooks = {
                wallpaper_changed = config.vayume.desktop.themeSync;
                theme_mode_changed = config.vayume.desktop.themeSync;
              };
            };
          };
        });
      };
    };
}
