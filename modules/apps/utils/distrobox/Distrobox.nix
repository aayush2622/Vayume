{
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

      boxHome = if cfg.isolateHome then cfg.homeDir else config.home.homeDirectory;

      createFlags = lib.concatStringsSep " " (
        [
          "--name"
          cfg.name
          "--image"
          cfg.image
          "--yes"
        ]

        ++ lib.optionals cfg.isolateHome [
          "--home"
          cfg.homeDir
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

      boxEnter = ''${pkgs.distrobox}/bin/distrobox enter "${cfg.name}" --'';

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
        "libxcomposite1"
        "libxdamage1"
        "libxext6"
        "libxfixes3"
        "libxrandr2"
        "libgbm1"
        "libexpat1"
        "libxkbcommon0"
        "libudev1"
        "libasound2t64"
        "libatspi2.0-0t64"
        "libxcb1"

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
            ${lib.escapeShellArg cfg.homeDir}
        ''}

        if ! ${pkgs.distrobox}/bin/distrobox list 2>/dev/null |
          ${pkgs.gawk}/bin/awk 'NR > 1 {print $3}' |
          ${pkgs.gnugrep}/bin/grep -Fxq "${cfg.name}"
        then
          echo "Creating '${cfg.name}' box from ${cfg.image}..."
          ${pkgs.distrobox}/bin/distrobox create ${createFlags}
        fi

        ${ensureBinfmt}
        ${ensureDbus}
      '';

      syncLaunchers = ''
        ${pkgs.coreutils}/bin/mkdir -p \
          ${lib.escapeShellArg hostApps} \
          ${lib.escapeShellArg hostIcons}

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

        ${pkgs.desktop-file-utils}/bin/update-desktop-database \
          ${lib.escapeShellArg hostApps} \
          2>/dev/null || true
      '';

      # Enter the container.
      box = pkgs.writeShellScriptBin "vayume-box" ''
        set -eu

        ${ensureBox}

        if [ "$#" -eq 0 ]; then
          exec ${pkgs.distrobox}/bin/distrobox enter "${cfg.name}"
        fi

        exec ${boxEnter} "$@"
      '';
      boxRun = pkgs.writeShellScriptBin "vayume-box-run" ''
          set -eu

          ${ensureBox}

          if [ "$#" -eq 0 ]; then
            echo "usage: vayume-box-run <command> [args...]" >&2
            exit 2
          fi

          target=$1
          shift

          case "$target" in
            "~/"*)
              # Only reachable when quoted; the host shell expands a
              # bare ~ before we ever see it.
              target=${lib.escapeShellArg boxHome}/''${target#\~/}
              ;;

            */*)
              # An explicit path: use exactly what was given.
              ;;

            *)
              # A bare name resolves against the box's Applications
              # dir, so "vayume-box-run foo.AppImage" just works.
              # Anything else (ls, apt, ...) falls through untouched.
              if [ -e ${lib.escapeShellArg "${boxHome}/Applications"}/"$target" ]; then
                target=${lib.escapeShellArg "${boxHome}/Applications"}/"$target"
              fi
              ;;
          esac

          # Run the resolved command directly rather than via a shell
          # wrapper, so an AppImage's parent process is its own
          # runtime instead of sh. The rewriting above happens on the
          # HOST, which keeps that parent chain intact.
          exec ${boxEnter} "$target" "$@"
      '';

      boxInstall = pkgs.writeShellScriptBin "vayume-box-install" ''
        set -eu

        if [ "$#" -eq 0 ]; then
          echo "usage: vayume-box-install <file.AppImage|file.deb|apt-package>..." >&2
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

              echo "Installing AppImage $base into '${cfg.name}'..."

              ${ensureAppImageDeps}

              # IMPORTANT:
              # This is the HOST path corresponding to
              # ~/Applications inside the isolated container.
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
              echo "  vayume-box-run $base"
              echo
              echo "If FUSE fails:"
              echo "  vayume-box-run $base --appimage-extract-and-run"
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

      boxApps = pkgs.writeShellScriptBin "vayume-box-apps" ''
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

      boxExport = pkgs.writeShellScriptBin "vayume-box-export" ''
        set -eu

        if [ "$#" -eq 0 ]; then
          echo "usage: vayume-box-export <app-name>..." >&2
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

      boxSync = pkgs.writeShellScriptBin "vayume-box-sync" ''
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

        echo "Box '${cfg.name}' is in sync."
      '';

      boxReset = pkgs.writeShellScriptBin "vayume-box-reset" ''
        set -eu

        echo
        echo "WARNING:"
        echo "This destroys the '${cfg.name}' container."
        echo "All packages installed inside the container are removed."

        ${lib.optionalString cfg.isolateHome ''
          echo "The isolated home is kept:"
          echo "  ${cfg.homeDir}"
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
          "${cfg.name}" \
          2>/dev/null || true

        ${ensureBox}

        echo
        echo "Recreated '${cfg.name}'."
        echo
        echo "The first command that enters the box runs a one-time"
        echo "setup that pulls its base packages. That takes a few"
        echo "minutes and prints nothing - it is not stuck."
        echo
        echo "Reinstall the AppImage dependencies with:"
        echo "  vayume-box-install <file.AppImage>"
      '';

    in
    {
      options.vayume.ubuntuBox = {

        name = lib.mkOption {
          type = lib.types.str;
          default = "ubuntu";
          description = "Distrobox container name.";
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
            Host directory used as the container's home when
            isolateHome is enabled.
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
            container, so run vayume-box-reset afterwards.
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
        box
        boxRun
        boxInstall
        boxApps
        boxExport
        boxSync
        boxReset
      ];
    };
}
