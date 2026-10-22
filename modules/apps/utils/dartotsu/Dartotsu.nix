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
      config,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.dartotsu.homeManagerModules.default ];

      programs.dartotsu = {
        enable = true;
        channel = "alpha"; # or "stable" / "alpha"
        registerLinkHandlers = true; # default handler for dartotsu://, mangayomi://, ... (stable only)
      };
      home.packages = [ pkgs.piper-tts ];
      home.file.".local/share/piper/en_US-lessac-high.onnx".source = pkgs.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/high/en_US-lessac-high.onnx";
        sha256 = "02cyrp5xsr5pr4y892i270zzxm1j4191c5aaycvp209qlv1zgasc";
      };
      home.file.".local/share/piper/en_US-lessac-high.onnx.json".source = pkgs.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/high/en_US-lessac-high.onnx.json";
        sha256 = "0bs1j8d97v6bsvfp82h50a23kckz1scfvf312ny5gwjrk1yvjhnv";
      };
      home.file.".config/matugen/templates/dartotsu.json".text = self.matugenTemplates.dartotsu;

      vayume.matugenTemplates.dartotsu = ''
        [templates.dartotsu]
        input_path = '${config.home.homeDirectory}/.config/matugen/templates/dartotsu.json'
        output_path = '${config.home.homeDirectory}/.config/dartotsu/theme.json'
      '';
    };
}
