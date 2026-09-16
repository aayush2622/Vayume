{ inputs, ... }: {
  flake.homeModules.apps.Fastpotify = { self, pkgs, lib, config, ... }:
  let
    spotifastSettingsSeed = pkgs.writeText "spotifast-settings.json" ''
      { "custom_theme": "dankmatugen.json" }
    '';
  in {
    home.packages = [
      (self.vayumeLib.loadOrBuild { inherit self pkgs; } "spotifast"
        inputs.spotifast.packages.${pkgs.stdenv.hostPlatform.system}.spotifast)
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

    # Spotifast only picks up a custom theme once it's selected under
    # Settings > Appearance > Theme - there's no env var or CLI flag for
    # it, just this field in settings.json (still under the old
    # `fastpotify` config dir - upstream kept that path on purpose when
    # renaming, see docs/_reference/settings-and-files.md). Seeded once,
    # same as thunar.xml in Thunar.nix - the app owns this file
    # afterwards (bitrate, sidebar order, sign-in state, ...), so a
    # symlink or an unconditional overwrite would either fail every write
    # or blow away real settings on every rebuild. Only helps a install
    # that's never launched before; an existing settings.json still needs
    # that one manual selection - matches upstream's own documented flow.
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
