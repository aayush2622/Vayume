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
      self,
      inputs,
      pkgs,
      config,
      ...
    }:
    {
      home.packages = [
        inputs.dartotsu.packages.${pkgs.stdenv.hostPlatform.system}.stable
      ];

      home.file.".config/matugen/templates/dartotsu.json".text = self.matugenTemplates.dartotsu;

      vayume.matugenTemplates.dartotsu = ''
        [templates.dartotsu]
        input_path = '${config.home.homeDirectory}/.config/matugen/templates/dartotsu.json'
        output_path = '${config.home.homeDirectory}/.config/dartotsu/theme.json'
      '';
    };
}
