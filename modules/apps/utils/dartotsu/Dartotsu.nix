{
  flake.appMeta.Dartotsu = {
    description = "Dartotsu, a hybrid AniList / MyAnimeList / Simkl client for tracking anime and manga.";
    label = "Dartotsu";
    icon = "dartotsu";
    symbol = "movie";
    section = "Internet";
  };

  flake.homeModules.apps.Dartotsu =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      home.packages = [
        inputs.dartotsu.packages.${pkgs.stdenv.hostPlatform.system}.stable
      ];
    };
}
