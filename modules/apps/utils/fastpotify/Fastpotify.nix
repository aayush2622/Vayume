{ inputs, ... }: {
  flake.appDescriptions.Fastpotify = "Spotifast, a lightweight Spotify client themed to match the desktop.";

  flake.homeModules.apps.Fastpotify = { self, pkgs, lib, config, ... }:
  let
    spotifastSettingsSeed = pkgs.writeText "spotifast-settings.json" ''
      { "custom_theme": "dankmatugen.json" }
    '';
  in {
    home.packages = [
      inputs.spotifast.packages.${pkgs.stdenv.hostPlatform.system}.spotifast
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/spotify" = "spotifast.desktop";
    };

    home.file.".config/matugen/templates/spotifast.json".text = self.matugenTemplates.spotifast;

    vayume.matugenTemplates.spotifast = ''
      [templates.spotifast]
      input_path = '${config.home.homeDirectory}/.config/matugen/templates/spotifast.json'
      output_path = '${config.home.homeDirectory}/.config/fastpotify/themes/dankmatugen.json'
    '';

    home.activation.seedSpotifastSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dest="$HOME/.config/fastpotify/settings.json"
      if [ ! -e "$dest" ]; then
        run mkdir -p "$(dirname "$dest")"
        run cp "${spotifastSettingsSeed}" "$dest"
        run chmod u+w "$dest"
      fi
    '';
  };
}
