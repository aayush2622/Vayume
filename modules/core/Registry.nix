{ lib, ... }: {
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = {};
  };

  options.flake.appDescriptions = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.str;
    default = {};
    description = "One-line description per flake.homeModules.apps.<Name>, declared in that app's own file.";
  };
}