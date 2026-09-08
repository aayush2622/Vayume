{ inputs, ... }: {
  flake.homeModules.apps.Fastpotify = { self, pkgs, config, ... }: {
    home.packages = [
      inputs.fastpotify.packages.${pkgs.stdenv.hostPlatform.system}.fastpotify
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/spotify" = "fastpotify.desktop";
    };

    home.file.".config/matugen/templates/fastpotify-caelestia.json".text = self.matugenTemplates.fastpotify;

    vayori.matugenTemplates.fastpotify = ''
      [templates.fastpotify]
      input_path = '${config.home.homeDirectory}/.config/matugen/templates/fastpotify-caelestia.json'
      output_path = '${config.home.homeDirectory}/.local/state/caelestia/scheme.json'
    '';
  };
}
