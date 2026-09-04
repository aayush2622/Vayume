{
  flake.homeModules.apps.Distrobox =
    { pkgs, lib, config, ... }:
    let
      cfg = config.vayori.ubuntuBox;

      hostApps = "${config.home.homeDirectory}/.local/share/applications";
      hostIcons = "${config.home.homeDirectory}/.local/share/icons";

      boxHome = if cfg.isolateHome then cfg.homeDir else config.home.homeDirectory;

      unshareFlags = lib.concatMapStringsSep " " (u: "--unshare-${u}") cfg.unshare;

      createFlags = lib.concatStringsSep " " (
        [ "--name" cfg.name "--image" cfg.image "--yes" ]
        ++ lib.optionals cfg.isolateHome [ "--home" cfg.homeDir ]
        ++ lib.optional (cfg.unshare != [ ]) unshareFlags
        ++ lib.optionals cfg.fuse [ "--additional-flags" "\"--device /dev/fuse\"" ]
      );

      ensureFuse = ''
        ${boxEnter} sh -c 'dpkg -s libfuse2t64 >/dev/null 2>&1 || dpkg -s libfuse2 >/dev/null 2>&1 \
          || (sudo apt-get update && (sudo apt-get install -y libfuse2t64 || sudo apt-get install -y libfuse2))' || true
      '';

      ensureBox = ''
        ${lib.optionalString cfg.isolateHome ''
          ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.homeDir}
        ''}
        if ! ${pkgs.distrobox}/bin/distrobox list 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $3}' | ${pkgs.gnugrep}/bin/grep -qx "${cfg.name}"; then
          echo "Creating '${cfg.name}' box from ${cfg.image} (first run downloads the image)..."
          ${pkgs.distrobox}/bin/distrobox create ${createFlags}
        fi
      '';

      boxEnter = ''${pkgs.distrobox}/bin/distrobox enter "${cfg.name}" --'';

      syncLaunchers = ''
        ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg hostApps} ${lib.escapeShellArg hostIcons}
        ${lib.optionalString cfg.isolateHome ''
          if [ -d ${lib.escapeShellArg cfg.homeDir}/.local/share/applications ]; then
            ${pkgs.rsync}/bin/rsync -rlpt --no-owner --no-group \
              ${lib.escapeShellArg cfg.homeDir}/.local/share/applications/ \
              ${lib.escapeShellArg hostApps}/ || true
          fi
          if [ -d ${lib.escapeShellArg cfg.homeDir}/.local/share/icons ]; then
            ${pkgs.rsync}/bin/rsync -rlpt --no-owner --no-group \
              ${lib.escapeShellArg cfg.homeDir}/.local/share/icons/ \
              ${lib.escapeShellArg hostIcons}/ || true
          fi
        ''}
        ${pkgs.desktop-file-utils}/bin/update-desktop-database ${lib.escapeShellArg hostApps} 2>/dev/null || true
      '';

      box = pkgs.writeShellScriptBin "vayori-box" ''
        set -eu
        ${ensureBox}
        if [ "$#" -eq 0 ]; then
          exec ${pkgs.distrobox}/bin/distrobox enter "${cfg.name}"
        fi
        exec ${boxEnter} "$@"
      '';

      boxInstall = pkgs.writeShellScriptBin "vayori-box-install" ''
        set -eu
        if [ "$#" -eq 0 ]; then
          echo "usage: vayori-box-install <package.deb|apt-package-name>..." >&2
          exit 2
        fi
        ${ensureBox}

        ${boxEnter} sudo apt-get update

        for item in "$@"; do
          case "$item" in
            *.AppImage|*.appimage)
              if [ ! -f "$item" ]; then
                echo "no such file: $item" >&2
                exit 1
              fi
              abs=$(${pkgs.coreutils}/bin/readlink -f "$item")
              base=$(${pkgs.coreutils}/bin/basename "$abs")
              echo "Installing AppImage $base into the box..."
              ${ensureFuse}
              ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg boxHome}/Applications
              ${pkgs.coreutils}/bin/cp -f "$abs" ${lib.escapeShellArg boxHome}/Applications/"$base"
              ${pkgs.coreutils}/bin/chmod +x ${lib.escapeShellArg boxHome}/Applications/"$base"
              echo "  run it with:  vayori-box ~/Applications/$base"
              echo "  if it reports a FUSE error, add: --appimage-extract-and-run"
              ;;
            *.deb)
              if [ ! -f "$item" ]; then
                echo "no such file: $item" >&2
                exit 1
              fi
              abs=$(${pkgs.coreutils}/bin/readlink -f "$item")
              echo "Installing $abs ..."
              ${boxEnter} sudo apt-get install -y "$abs"
              ;;
            *)
              echo "Installing apt package $item ..."
              ${boxEnter} sudo apt-get install -y "$item"
              ;;
          esac
        done

        echo
        echo "Done. Export a launcher entry with:  vayori-box-export <app-name>"
        echo "List what the box now provides with: vayori-box-apps"
      '';

      boxApps = pkgs.writeShellScriptBin "vayori-box-apps" ''
        set -eu
        ${ensureBox}
        ${boxEnter} sh -c 'ls -1 /usr/share/applications/*.desktop 2>/dev/null | xargs -r -n1 basename | sed "s/\.desktop$//"'
      '';

      boxExport = pkgs.writeShellScriptBin "vayori-box-export" ''
        set -eu
        if [ "$#" -eq 0 ]; then
          echo "usage: vayori-box-export <app-name>...   (see: vayori-box-apps)" >&2
          exit 2
        fi
        ${ensureBox}
        for app in "$@"; do
          echo "Exporting $app to the host launcher..."
          ${boxEnter} distrobox-export --app "$app"
        done
        ${syncLaunchers}
        echo "Exported. They now show up in the app launcher."
      '';

      boxSync = pkgs.writeShellScriptBin "vayori-box-sync" ''
        set -eu
        ${ensureBox}
        ${lib.optionalString (cfg.aptPackages != [ ]) ''
          ${boxEnter} sudo apt-get update
          ${boxEnter} sudo apt-get install -y ${lib.escapeShellArgs cfg.aptPackages}
        ''}
        ${lib.concatMapStringsSep "\n" (a: ''
          ${boxEnter} distrobox-export --app ${lib.escapeShellArg a} || true
        '') cfg.exportApps}
        ${syncLaunchers}
        echo "Box '${cfg.name}' is in sync."
      '';

      boxReset = pkgs.writeShellScriptBin "vayori-box-reset" ''
        set -eu
        echo "This destroys the '${cfg.name}' box and everything installed in it."
        ${lib.optionalString cfg.isolateHome ''
          echo "Its home (${cfg.homeDir}) is kept."
        ''}
        printf 'Continue? [y/N] '
        read -r reply
        case "$reply" in
          y|Y) ;;
          *) echo "Aborted."; exit 1 ;;
        esac
        ${pkgs.distrobox}/bin/distrobox rm --force "${cfg.name}" 2>/dev/null || true
        ${ensureBox}
        echo "Recreated '${cfg.name}'. Re-run vayori-box-sync to reinstall declared packages."
      '';
    in
    {
      options.vayori.ubuntuBox = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "ubuntu";
          description = "distrobox container name used for Debian/Ubuntu-only apps.";
        };

        image = lib.mkOption {
          type = lib.types.str;
          default = "docker.io/library/ubuntu:24.04";
          description = "Container image the box is built from.";
        };

        isolateHome = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Give the box its own home directory instead of sharing the
            host's. distrobox shares all of `$HOME` by default, which
            means anything installed in the box can read every file you
            own - the wrong default for software you don't control.
            Launcher entries are copied back out to the host so exported
            apps still appear in the app launcher.
          '';
        };

        homeDir = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.local/share/vayori-boxes/${cfg.name}";
          description = "Home directory the box gets when `isolateHome` is on.";
        };

        unshare = lib.mkOption {
          type = lib.types.listOf (lib.types.enum [ "ipc" "process" "netns" "devsys" "groups" ]);
          default = [ "ipc" "process" ];
          description = ''
            Namespaces the box does not share with the host. `ipc` and
            `process` are safe defaults. `netns` cuts the box off the
            network and `devsys` hides host devices - either will break
            a networked or GPU-accelerated GUI app, so neither is on by
            default.
          '';
        };

        fuse = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Pass `/dev/fuse` into the box. AppImages mount their own
            payload through libfuse and cannot start without it; a
            rootless container gets no FUSE device otherwise. Applied at
            creation only - run `vayori-box-reset` on an existing box.
          '';
        };

        aptPackages = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "libwebkit2gtk-4.1-0" ];
          description = ''
            apt packages `vayori-box-sync` keeps installed in the box.
            Only for things that genuinely have no nixpkgs equivalent -
            anything packaged for Nix belongs in `home.packages` instead.
          '';
        };

        exportApps = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "codetantra" ];
          description = ''
            Desktop-entry names `vayori-box-sync` exports to the host
            launcher. Names come from `vayori-box-apps`.
          '';
        };
      };

      config = {
        home.packages = [
          pkgs.distrobox
          box
          boxInstall
          boxApps
          boxExport
          boxSync
          boxReset
        ];
      };
    };
}
