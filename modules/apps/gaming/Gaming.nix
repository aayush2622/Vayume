{
  flake.appDescriptions.Gaming = "Game launchers (Lutris, Heroic, Hytale), Proton/GPU tuning, and shader-cache management.";

  flake.homeModules.apps.Gaming =
    { config, ... }:
    let
      gamesDir = "${config.home.homeDirectory}/Games";
      shaderCacheDir = "${gamesDir}/.cache/nv-shaders";
    in
    {
      imports = [
        ./_launchers.nix
        ./_hytale.nix
        ./_proton.nix
        ./_gamesync.nix
        ./_performance.nix
      ];

      _module.args = { inherit gamesDir shaderCacheDir; };
    };
}
