{
  flake.nixosModules.Waydroid =
    { pkgs, lib, config, ... }:
    let
      waydroidPackage = pkgs.waydroid-nftables;
      android11Zips = {
        system = pkgs.fetchurl {
          url = "https://downloads.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-18.1-20250628-VANILLA-waydroid_x86_64-system.zip";
          hash = "sha256-ZiViqnGNoaWEUgNns522jwAdtTU+vL8M+TAFCI0oQJc=";
        };
        vendor = pkgs.fetchurl {
          url = "https://downloads.sourceforge.net/project/waydroid/images/vendor/waydroid_x86_64/lineage-18.1-20250628-MAINLINE-waydroid_x86_64-vendor.zip";
          hash = "sha256-VBSic6yXKqGmW8yll9XTKTPYRt0WKM/ckkE7faUzIYk=";
        };
      };

      android11Images = pkgs.runCommand "waydroid-android11-images" { nativeBuildInputs = [ pkgs.unzip ]; } ''
        mkdir -p $out
        unzip -q ${android11Zips.system} system.img -d $out
        unzip -q ${android11Zips.vendor} vendor.img -d $out
      '';

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
                waydroidPackage
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

      android11Priv = pkgs.writeShellScript "vayume-waydroid-android11-priv" ''
        set -eu

        user="''${SUDO_USER:-}"
        if [ -z "$user" ]; then
          echo "run this through sudo from your own user" >&2
          exit 1
        fi
        home=$(${pkgs.getent}/bin/getent passwd "$user" | ${pkgs.coreutils}/bin/cut -d: -f6)

        echo ":: stopping Waydroid"
        ${lib.getExe waydroidPackage} session stop 2>/dev/null || true
        ${pkgs.systemd}/bin/systemctl stop waydroid-container.service 2>/dev/null || true

        echo ":: clearing Android data and overlays (Android 13 data cannot be reused)"
        ${pkgs.coreutils}/bin/rm -rf \
          /var/lib/waydroid/overlay \
          /var/lib/waydroid/overlay_rw \
          "$home/.local/share/waydroid"

        echo ":: initialising Waydroid from the pinned Android 11 images"
        ${lib.getExe waydroidPackage} init -f

        echo ":: installing microG"
        ${lib.getExe waydroid-script} -a 11 install microg

        ${pkgs.systemd}/bin/systemctl start waydroid-container.service || true

        cat <<'EOF'

        Done. Start Waydroid and give the first boot a few minutes.
        Then open microG Settings, run the Self-Check, and grant
        "Spoof package signature" to the apps that need it.
        EOF
      '';

      android11 = pkgs.writeShellScriptBin "vayume-waydroid-android11" ''
        exec sudo -n ${android11Priv}
      '';

      unpatchPriv = pkgs.writeShellScript "vayume-waydroid-unpatch-priv" ''
        set -eu

        overlay=/var/lib/waydroid/overlay/system

        ${lib.getExe waydroidPackage} session stop 2>/dev/null || true
        ${pkgs.systemd}/bin/systemctl stop waydroid-container.service 2>/dev/null || true

        ${pkgs.coreutils}/bin/rm -f \
          "$overlay/framework/services.jar" \
          "$overlay/framework/services.jar.prof" \
          "$overlay/framework/services.jar.bprof" \
          "$overlay/etc/nodataperm.sh" \
          "$overlay/etc/init/nodataperm.rc"

        ${pkgs.systemd}/bin/systemctl start waydroid-container.service

        echo "Patch removed. Start Waydroid again."
      '';

      unpatch = pkgs.writeShellScriptBin "vayume-waydroid-unpatch" ''
        exec sudo -n ${unpatchPriv}
      '';
    in
    {
      virtualisation.waydroid = {
        enable = true;
        package = pkgs.waydroid-nftables;
      };

      environment.etc."waydroid-extra/images".source = android11Images;

      environment.systemPackages = [
        waydroid-script
        unpatch
        android11
        pkgs.waydroid-helper
      ];

      security.sudo.extraRules = lib.mkIf (config ? vayume && config.vayume ? users) (
        map (name: {
          users = [ name ];
          commands = [
            {
              command = "${unpatchPriv}";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${android11Priv}";
              options = [ "NOPASSWD" ];
            }
          ];
        }) (builtins.attrNames config.vayume.users)
      );
    };
}
