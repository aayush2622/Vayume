{
  flake.nixosModules.Waydroid =
    { pkgs, lib, config, ... }:
    let
      waydroidScriptPython = pkgs.python3.withPackages (ps: with ps; [ tqdm requests inquirerpy ]);

      waydroid-script = pkgs.stdenvNoCC.mkDerivation {
        pname = "waydroid-script";
        version = "0-unstable-2026-01-05";

        src = pkgs.fetchFromGitHub {
          owner = "casualsnek";
          repo = "waydroid_script";
          rev = "d5289cfd8929e86e7f0dc89ecadcef8b66930eec";
          hash = "sha256-zSHZlhHJHWZRE3I5pYWhD4o8aNpa8rTiEtl2qJTuRjw=";
        };

        nativeBuildInputs = [ pkgs.makeWrapper ];
        dontBuild = true;

        installPhase = ''
          runHook preInstall
          install -d "$out/share/waydroid-script"
          cp -r . "$out/share/waydroid-script"
          makeWrapper ${waydroidScriptPython}/bin/python3 "$out/bin/waydroid-script" \
            --add-flags "$out/share/waydroid-script/main.py" \
            --prefix PATH : ${
              lib.makeBinPath [
                pkgs.waydroid
                pkgs.e2fsprogs
                pkgs.util-linux
                pkgs.gnutar
                pkgs.lzip
                pkgs.gzip
              ]
            } \
            --suffix PATH : /run/wrappers/bin \
            --run "cd $out/share/waydroid-script"
          runHook postInstall
        '';

        meta = {
          description = "Add OpenGApps, microG, ARM translation and signature spoofing to Waydroid";
          homepage = "https://github.com/casualsnek/waydroid_script";
          license = lib.licenses.gpl3Only;
          mainProgram = "waydroid-script";
        };
      };

      sigspoofPriv = pkgs.writeShellScript "vayume-waydroid-sigspoof-priv" ''
        set -eu

        if [ ! -e /var/lib/waydroid/images/system.img ]; then
          echo "no system image yet - run 'sudo waydroid init' first" >&2
          exit 1
        fi

        ver="''${WAYDROID_ANDROID_VERSION:-13}"

        echo ":: stopping Waydroid"
        ${lib.getExe pkgs.waydroid} session stop 2>/dev/null || true
        ${pkgs.systemd}/bin/systemctl stop waydroid-container.service 2>/dev/null || true

        echo ":: applying signature-spoofing + data-permission patch (android $ver)"
        ${lib.getExe waydroid-script} -a "$ver" hack nodataperm

        case "''${1:-}" in
          microg | --microg)
            echo ":: installing microG"
            ${lib.getExe waydroid-script} -a "$ver" install microg
            ;;
        esac

        echo ":: restarting Waydroid container"
        ${pkgs.systemd}/bin/systemctl start waydroid-container.service || true

        cat <<'EOF'

        Done. Next:
          - start Waydroid, open its Settings / microG Self-Check
          - grant "Spoof package signature" to the app that needs it
          - stop + start the session once so the new services.jar is picked up
        EOF
      '';

      sigspoof = pkgs.writeShellScriptBin "vayume-waydroid-sigspoof" ''
        exec sudo -n --preserve-env=WAYDROID_ANDROID_VERSION ${sigspoofPriv} "$@"
      '';
    in
    {
      virtualisation.waydroid.enable = true;

      environment.systemPackages = [
        waydroid-script
        sigspoof
        pkgs.waydroid-helper
      ];

      security.sudo.extraRules = lib.mkIf (config ? vayume && config.vayume ? users) (
        map (name: {
          users = [ name ];
          commands = [
            {
              command = "${sigspoofPriv}";
              options = [
                "SETENV"
                "NOPASSWD"
              ];
            }
          ];
        }) (builtins.attrNames config.vayume.users)
      );
    };
}
