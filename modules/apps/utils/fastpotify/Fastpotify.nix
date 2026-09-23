{ inputs, ... }: {
  flake.appDescriptions.Fastpotify = "Spotifast, a lightweight Spotify client themed to match the desktop.";

  flake.homeModules.apps.Fastpotify = { self, pkgs, lib, config, ... }:
  let
    spotifastSettingsSeed = pkgs.writeText "spotifast-settings.json" ''
      { "custom_theme": "dankmatugen.json" }
    '';

    spotifast = pkgs.stdenv.mkDerivation rec {
      pname = "spotifast";
      version = "0.9.1";

      src = pkgs.fetchurl {
        url = "https://github.com/crmne/spotifast/releases/download/v${version}/spotifast-v${version}-x86_64-unknown-linux-gnu.tar.gz";
        hash = "sha256-tv7ixet5Netb5UQ/D0bGXDs3XiCQXeK2ozMssfODViE=";
      };

      sourceRoot = "spotifast-v${version}-x86_64-unknown-linux-gnu";

      nativeBuildInputs = [ pkgs.autoPatchelfHook ];

      buildInputs = [
        pkgs.stdenv.cc.cc.lib
        pkgs.alsa-lib
        pkgs.libpulseaudio
      ];

      runtimeDependencies = with pkgs; [
        (lib.getLib dbus)
        libxkbcommon
        wayland
        libGL
        libx11
        libxcursor
        libxi
        libxrandr
      ];

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        install -Dm755 spotifast $out/bin/spotifast
        ln -s spotifast $out/bin/fastpotify
        install -Dm644 packaging/applications/spotifast.desktop $out/share/applications/spotifast.desktop
        install -Dm644 packaging/icons/spotifast.svg $out/share/icons/hicolor/scalable/apps/spotifast.svg
        runHook postInstall
      '';

      meta = {
        description = "Spotify, native and fast";
        homepage = "https://github.com/crmne/spotifast";
        license = lib.licenses.mit;
        mainProgram = "spotifast";
        platforms = [ "x86_64-linux" ];
      };
    };
  in {
    home.packages = [ spotifast ];

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
