{
  flake.appDescriptions.Distrobox = "Ubuntu Distrobox container, with host app/icon integration for AppImages.";

  flake.homeModules.apps.Distrobox =
    {
      pkgs,
      lib,
      config,
      ...
    }:

    let
      cfg = config.vayume.ubuntuBox;

      hostApps = "${config.home.homeDirectory}/.local/share/applications";

      hostIcons = "${config.home.homeDirectory}/.local/share/icons";

      appImageDeps = [
        "fuse3"
        "libfuse2t64"
        "libglib2.0-0t64"
        "libgtk-3-0t64"
        "libnss3"
        "libnspr4"
        "libdbus-1-3"
        "libatk1.0-0t64"
        "libatk-bridge2.0-0t64"
        "libcups2t64"
        "libpango-1.0-0"
        "libcairo2"
        "libx11-6"
        "libx11-xcb1"
        "libxcomposite1"
        "libxdamage1"
        "libxext6"
        "libxfixes3"
        "libxrandr2"
        "libxi6"
        "libsm6"
        "libice6"
        "libxcb1"
        "libxcb-cursor0"
        "libxcb-xkb1"
        "libxkbcommon0"
        "libxkbcommon-x11-0"
        "libgbm1"
        "libexpat1"
        "libudev1"
        "libasound2t64"
        "libpulse0"
        "libatspi2.0-0t64"
        "libcups2t64"
        "libglib2.0-bin"
        "gsettings-desktop-schemas"
        "dconf-gsettings-backend"
        "mutter-common"
        "gnome-shell-common"
        "gnome-settings-daemon-common"
        "dbus"
        "dbus-x11"
        "xdg-utils"
      ];

      clipboardDeps = [
        "wl-clipboard"
        "xclip"
        "xsel"
      ];

      boxSpecs = map (i: {
        boxName = if i == 1 then cfg.name else "${cfg.name}${toString i}";
        homeDir =
          if i == 1 then
            cfg.homeDir
          else
            "${config.home.homeDirectory}/.local/share/vayume-boxes/${cfg.name}${toString i}";
        cmdSuffix = if cfg.count <= 1 then "" else toString i;
      }) (lib.range 1 cfg.count);

      mkBox =
        {
          boxName,
          homeDir,
          cmdSuffix,
        }:
        let
          boxHome = if cfg.isolateHome then homeDir else config.home.homeDirectory;

          createFlags = lib.concatStringsSep " " (
            [
              "--name"
              boxName
              "--image"
              cfg.image
              "--yes"
            ]

            ++ lib.optionals cfg.isolateHome [
              "--home"
              homeDir
            ]

            ++ lib.map (u: "--unshare-${u}") cfg.unshare

            ++ lib.optionals cfg.fuse [
              "--additional-flags"
              "\"--device /dev/fuse\""
            ]

            ++ lib.optionals (cfg.shmSize != "") [
              "--additional-flags"
              "\"--shm-size=${cfg.shmSize}\""
            ]
          );

          boxEnter = ''${pkgs.distrobox}/bin/distrobox enter "${boxName}" --'';

          ensureAppImageDeps = ''
            ${boxEnter} sh -c '
              missing=""

              for p in ${lib.concatStringsSep " " appImageDeps}; do
                dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
              done

              if [ -n "$missing" ]; then
                sudo apt-get update
                sudo apt-get install -y $missing
              fi
            ' || true
          '';

          ensureClipboardDeps = ''
            ${boxEnter} sh -c '
              missing=""

              for p in ${lib.concatStringsSep " " clipboardDeps}; do
                dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
              done

              if [ -n "$missing" ]; then
                sudo apt-get update
                sudo apt-get install -y $missing
              fi
            ' || true
          '';

          ensureDbus = ''
            ${boxEnter} sudo sh -c '
              mkdir -p /run/dbus
              [ -S /run/dbus/system_bus_socket ] ||
                dbus-daemon --system --fork
            ' >/dev/null 2>&1 || true
          '';

          ensureBinfmt = ''
            ${boxEnter} sh -c '
              if [ -e /proc/sys/fs/binfmt_misc/appimage_type_2 ] ||
                 [ ! -e /proc/sys/fs/binfmt_misc/register ]
              then
                sudo mount -t binfmt_misc none /proc/sys/fs/binfmt_misc
              fi
            ' >/dev/null 2>&1 || true
          '';

          ensureBox = ''
            ${lib.optionalString cfg.isolateHome ''
              ${pkgs.coreutils}/bin/mkdir -p \
                ${lib.escapeShellArg homeDir}
            ''}

            if ! ${pkgs.distrobox}/bin/distrobox list 2>/dev/null |
              ${pkgs.gawk}/bin/awk 'NR > 1 {print $3}' |
              ${pkgs.gnugrep}/bin/grep -Fxq "${boxName}"
            then
              echo "Creating '${boxName}' box from ${cfg.image}..."
              ${pkgs.distrobox}/bin/distrobox create ${createFlags}
            fi

            ${ensureBinfmt}
            ${ensureDbus}
            ${ensureClipboardDeps}
          '';

          syncLaunchers = ''
            ${pkgs.coreutils}/bin/mkdir -p \
              ${lib.escapeShellArg hostApps} \
              ${lib.escapeShellArg hostIcons}

            ${lib.optionalString cfg.isolateHome ''
              if [ -d ${lib.escapeShellArg homeDir}/.local/share/applications ]; then
                ${pkgs.rsync}/bin/rsync -rlpt --no-owner --no-group \
                  ${lib.escapeShellArg homeDir}/.local/share/applications/ \
                  ${lib.escapeShellArg hostApps}/ || true
              fi

              if [ -d ${lib.escapeShellArg homeDir}/.local/share/icons ]; then
                ${pkgs.rsync}/bin/rsync -rlpt --no-owner --no-group \
                  ${lib.escapeShellArg homeDir}/.local/share/icons/ \
                  ${lib.escapeShellArg hostIcons}/ || true
              fi
            ''}

            ${pkgs.desktop-file-utils}/bin/update-desktop-database \
              ${lib.escapeShellArg hostApps} \
              2>/dev/null || true
          '';

          box = pkgs.writeShellScriptBin "vayume-box${cmdSuffix}" ''
            set -eu

            ${ensureBox}

            if [ "$#" -eq 0 ]; then
              exec ${pkgs.distrobox}/bin/distrobox enter "${boxName}"
            fi

            exec ${boxEnter} "$@"
          '';

          boxRun = pkgs.writeShellScriptBin "vayume-box${cmdSuffix}-run" ''
            set -eu

            ${ensureBox}

            if [ "$#" -eq 0 ]; then
              echo "usage: vayume-box${cmdSuffix}-run <command> [args...]" >&2
              exit 2
            fi

            target=$1
            shift

            case "$target" in
              "~/"*)
                # only reachable when quoted; the host shell expands a bare ~ first
                target=${lib.escapeShellArg boxHome}/''${target#\~/}
                ;;

              */*)
                ;;

              *)
                if [ -e ${lib.escapeShellArg "${boxHome}/Applications"}/"$target" ]; then
                  target=${lib.escapeShellArg "${boxHome}/Applications"}/"$target"
                fi
                ;;
            esac

            case "$target" in
              *.AppImage|*.appimage)
                ${ensureAppImageDeps}
                ;;
            esac

            exec ${boxEnter} "$target" "$@"
          '';

          boxInstall = pkgs.writeShellScriptBin "vayume-box${cmdSuffix}-install" ''
            set -eu

            if [ "$#" -eq 0 ]; then
              echo "usage: vayume-box${cmdSuffix}-install <file.AppImage|file.deb|apt-package>..." >&2
              exit 2
            fi

            ${ensureBox}

            for item in "$@"; do
              case "$item" in

                *.AppImage|*.appimage)
                  if [ ! -f "$item" ]; then
                    echo "no such file: $item" >&2
                    exit 1
                  fi

                  abs=$(
                    ${pkgs.coreutils}/bin/readlink -f "$item"
                  )

                  base=$(
                    ${pkgs.coreutils}/bin/basename "$abs"
                  )

                  echo "Installing AppImage $base into '${boxName}'..."

                  ${ensureAppImageDeps}

                  ${pkgs.coreutils}/bin/mkdir -p \
                    ${lib.escapeShellArg "${boxHome}/Applications"}

                  ${pkgs.coreutils}/bin/cp -f \
                    "$abs" \
                    ${lib.escapeShellArg "${boxHome}/Applications/"}"$base"

                  ${pkgs.coreutils}/bin/chmod +x \
                    ${lib.escapeShellArg "${boxHome}/Applications/"}"$base"

                  echo
                  echo "Installed:"
                  echo "  ${boxHome}/Applications/$base"
                  echo
                  echo "Run:"
                  echo "  vayume-box${cmdSuffix}-run $base"
                  echo
                  echo "If FUSE fails:"
                  echo "  vayume-box${cmdSuffix}-run $base --appimage-extract-and-run"
                  ;;

                *.deb)
                  if [ ! -f "$item" ]; then
                    echo "no such file: $item" >&2
                    exit 1
                  fi

                  abs=$(
                    ${pkgs.coreutils}/bin/readlink -f "$item"
                  )

                  echo "Installing $abs..."

                  ${boxEnter} sudo apt-get update
                  ${boxEnter} sudo apt-get install -y "$abs"
                  ;;

                *)
                  echo "Installing apt package: $item..."

                  ${boxEnter} sudo apt-get update
                  ${boxEnter} sudo apt-get install -y "$item"
                  ;;

              esac
            done

            echo
            echo "Done."
          '';

          boxApps = pkgs.writeShellScriptBin "vayume-box${cmdSuffix}-apps" ''
            set -eu

            ${ensureBox}

            echo "Installed desktop applications:"
            ${boxEnter} sh -c '
              find \
                /usr/share/applications \
                "$HOME/.local/share/applications" \
                -maxdepth 1 \
                -type f \
                -name "*.desktop" \
                -printf "%f\n" \
                2>/dev/null |
              sed "s/\.desktop$//" |
              sort -u
            '
          '';

          boxExport = pkgs.writeShellScriptBin "vayume-box${cmdSuffix}-export" ''
            set -eu

            if [ "$#" -eq 0 ]; then
              echo "usage: vayume-box${cmdSuffix}-export <app-name>..." >&2
              exit 2
            fi

            ${ensureBox}

            for app in "$@"; do
              echo "Exporting $app..."

              ${boxEnter} distrobox-export \
                --app "$app"
            done

            ${syncLaunchers}

            echo
            echo "Exported to the host launcher."
          '';

          boxSync = pkgs.writeShellScriptBin "vayume-box${cmdSuffix}-sync" ''
            set -eu

            ${ensureBox}

            ${lib.optionalString (cfg.aptPackages != [ ]) ''
              ${boxEnter} sudo apt-get update
              ${boxEnter} sudo apt-get install -y \
                ${lib.escapeShellArgs cfg.aptPackages}
            ''}

            ${lib.concatMapStringsSep "\n" (a: ''
              ${boxEnter} distrobox-export \
                --app ${lib.escapeShellArg a} || true
            '') cfg.exportApps}

            ${syncLaunchers}

            echo "Box '${boxName}' is in sync."
          '';

          boxReset = pkgs.writeShellScriptBin "vayume-box${cmdSuffix}-reset" ''
            set -eu

            echo
            echo "WARNING:"
            echo "This destroys the '${boxName}' container."
            echo "All packages installed inside the container are removed."

            ${lib.optionalString cfg.isolateHome ''
              echo "The isolated home is kept:"
              echo "  ${homeDir}"
            ''}

            echo
            printf 'Continue? [y/N] '
            read -r reply

            case "$reply" in
              y|Y)
                ;;
              *)
                echo "Aborted."
                exit 1
                ;;
            esac

            ${pkgs.distrobox}/bin/distrobox rm \
              --force \
              "${boxName}" \
              2>/dev/null || true

            ${ensureBox}

            echo
            echo "Recreated '${boxName}'."
            echo
            echo "The first command that enters the box runs a one-time"
            echo "setup that pulls its base packages. That takes a few"
            echo "minutes and prints nothing - it is not stuck."
            echo
            echo "Reinstall the AppImage dependencies with:"
            echo "  vayume-box${cmdSuffix}-install <file.AppImage>"
          '';
        in
        [
          box
          boxRun
          boxInstall
          boxApps
          boxExport
          boxSync
          boxReset
        ];

      boxPackages = lib.concatMap mkBox boxSpecs;

    in
    {
      options.vayume.ubuntuBox = {

        count = lib.mkOption {
          type = lib.types.ints.positive;
          default = 2;
          description = ''
            How many independent containers to manage. 1 (the default)
            keeps the original single, unnumbered command set -
            vayume-box, vayume-box-run, vayume-box-install,
            vayume-box-apps, vayume-box-export, vayume-box-sync,
            vayume-box-reset - entering "${cfg.name}".

            More than 1 replaces those with numbered variants instead:
            vayume-box1, vayume-box1-run, ... up through
            vayume-box<count>-reset, each entering its own container.
            box1 is always the exact same container/home as count = 1 -
            "${cfg.name}"/homeDir, unchanged - so raising this from 1
            never orphans a box you already have, it's just addressed
            as vayume-box1 from now on. Only box2..N are new, numbered
            containers ("${cfg.name}2" .. "${cfg.name}<count>"), each
            with its own auto-derived isolated home under
            .local/share/vayume-boxes/. Every other option below -
            image, unshare, fuse, shmSize, aptPackages, exportApps - is
            shared across all of them.
          '';
        };

        name = lib.mkOption {
          type = lib.types.str;
          default = "ubuntu";
          description = ''
            Distrobox container name for box1. Also the prefix for
            box2..N when count > 1, e.g. "ubuntu" gives "ubuntu2" ..
            "ubuntu<count>" (box1 itself stays plain "ubuntu").
          '';
        };

        image = lib.mkOption {
          type = lib.types.str;
          default = "docker.io/library/ubuntu:24.04";
          description = "Container image.";
        };

        isolateHome = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Give the container its own home directory.
            The container does not use the host's normal $HOME.
          '';
        };

        homeDir = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.local/share/vayume-boxes/${cfg.name}";
          description = ''
            Host directory used as box1's container home when
            isolateHome is enabled, at any count. box2..N always get
            their own auto-derived directory instead
            (.local/share/vayume-boxes/<name><n>) and ignore this
            option entirely.
          '';
        };

        unshare = lib.mkOption {
          type = lib.types.listOf (
            lib.types.enum [
              "ipc"
              "process"
              "netns"
              "devsys"
              "groups"
            ]
          );

          default = [
            "ipc"
            "process"
            "devsys"
          ];

          description = ''
            Namespaces to unshare.

            ipc     = isolate IPC
            process = isolate processes
            netns   = isolate network
            devsys  = isolate device/system namespace
            groups  = isolate groups

            netns is intentionally not enabled by default because
            browser applications need network access.
          '';
        };

        fuse = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Expose /dev/fuse to the container for AppImages.
          '';
        };

        shmSize = lib.mkOption {
          type = lib.types.str;
          default = "2g";

          description = ''
            Size of /dev/shm inside the container.

            Chromium-based apps map large shared-memory segments and
            are killed with SIGBUS once /dev/shm is exhausted, which
            looks like the app freezing as soon as a page loads.
            Podman's 64M default is far too small for a real page.

            Set to "" to leave the runtime default alone.

            Changing this only takes effect on a freshly created
            container, so run vayume-box-reset (or vayume-box<n>-reset)
            afterwards.
          '';
        };

        aptPackages = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];

          example = [
            "libwebkit2gtk-4.1-0"
          ];

          description = ''
            Packages kept installed with apt.
          '';
        };

        exportApps = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];

          example = [
            "codetantra"
          ];

          description = ''
            Desktop-entry names to export to the host launcher.
          '';
        };
      };

      config.home.packages = [
        pkgs.distrobox
      ]
      ++ boxPackages;
    };
}
