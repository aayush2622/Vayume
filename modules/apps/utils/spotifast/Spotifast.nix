{ inputs, ... }: {
  flake.appDescriptions.Spotifast = "Spotifast, a lightweight Spotify client themed to match the desktop.";

  flake.homeModules.apps.Spotifast =
    {
      self,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      spotifastSettingsSeed = pkgs.writeText "spotifast-settings.json" ''
        { "custom_theme": "dankmatugen.json" }
      '';

      themeHook = pkgs.writeShellScript "spotifast-theme-hook" ''
        src="$HOME/.config/matugen/spotifast-dankmatugen.json"
        [ -f "$src" ] || exit 0

        for dir in "$HOME/.config/spotifast" "$HOME/.config/fastpotify"; do
          if [ -d "$dir" ]; then
            ${pkgs.coreutils}/bin/mkdir -p "$dir/themes"
            ${pkgs.coreutils}/bin/install -m 644 "$src" "$dir/themes/dankmatugen.json"
          fi
        done

        ${spotifast}/bin/spotifast reload-themes >/dev/null 2>&1 || true
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
    in
    {
      home.packages = [ spotifast ];

      xdg.mimeApps = {
        enable = true;
        defaultApplications."x-scheme-handler/spotify" = "spotifast.desktop";
      };

      home.file.".config/matugen/templates/spotifast.json".text = self.matugenTemplates.spotifast;

      vayume.matugenTemplates.spotifast = ''
        [templates.spotifast]
        input_path = '${config.home.homeDirectory}/.config/matugen/templates/spotifast.json'
        output_path = '${config.home.homeDirectory}/.config/matugen/spotifast-dankmatugen.json'
        post_hook = '${themeHook}'
      '';

      home.activation.seedSpotifastSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dest="$HOME/.config/spotifast/settings.json"
        unmigrated=0
        if [ -d "$HOME/.config/fastpotify" ] && [ ! -d "$HOME/.config/spotifast" ]; then
          unmigrated=1
        fi
        if [ "$unmigrated" = 0 ] && [ ! -e "$dest" ]; then
          run mkdir -p "$(dirname "$dest")"
          run cp "${spotifastSettingsSeed}" "$dest"
          run chmod u+w "$dest"
        fi
      '';
    };
}
