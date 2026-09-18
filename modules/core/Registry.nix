{ lib, ... }: {
  config.systems = [
    "x86_64-linux"
    "x86_64-darwin"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = {};
  };

  options.flake.appDescriptions = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.str;
    default = {};
    description = "One-line description per flake.homeModules.apps.<Name>, declared in that app's own file.";
  };

  options.flake.pluginPins = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Pinned plugin/extension specs per app, published so the plugin-update checker can read them without evaluating each app's home module.";
  };
}