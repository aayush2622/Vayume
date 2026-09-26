{ lib, ... }: {
  config.systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
  };

  options.flake.appMeta = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options = {
          label = lib.mkOption {
            type = lib.types.str;
            description = "Name shown in Vayume Settings.";
          };
          description = lib.mkOption {
            type = lib.types.str;
            description = "One line shown under the app in Vayume Settings.";
          };
          icon = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Freedesktop icon name, looked up in the icon theme; the app's own icon once it is installed.";
          };
          symbol = lib.mkOption {
            type = lib.types.str;
            default = "apps";
            description = "Material Symbols name drawn when the icon theme has no `icon`.";
          };
          section = lib.mkOption {
            type = lib.types.str;
            default = "Other";
            description = "Card the app is listed under in Applications (ignored for development apps).";
          };
        };
      }
    );
    default = { };
    description = "How each flake.homeModules.apps.<Name> is presented in Vayume Settings (name, one-line description, icon, section), declared in that app's own file.";
  };

  options.flake.pluginPins = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Pinned plugin/extension specs per app, published so the plugin-update checker can read them without evaluating each app's home module.";
  };
}
