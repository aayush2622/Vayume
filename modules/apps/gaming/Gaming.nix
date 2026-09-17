{
  flake.appDescriptions.Gaming = "Game launchers, Proton/GPU tuning, and shader-cache management.";

  flake.homeModules.apps.Gaming = { config, ... }:
  let
    gamesDir = "${config.home.homeDirectory}/Games";
    shaderCacheDir = "${gamesDir}/.cache/nv-shaders";
  in
  {
    imports = [
      ./_launchers.nix
      ./_proton.nix
      ./_performance.nix
    ];

    _module.args = { inherit gamesDir shaderCacheDir; };
  };
}
