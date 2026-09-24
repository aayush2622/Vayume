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
        "libopengl0"
        "libgl1"
        "libegl1"
        "libglx0"
        "libglu1-mesa"
        "libgl1-mesa-dri"
        "libgbm1"
        "libgtk-3-0t64"
        "libglib2.0-0t64"
        "libglib2.0-bin"
        "libx11-6"
        "libx11-xcb1"
        "libxcb1"
        "libxcb-cursor0"
        "libxcb-xkb1"
        "libxkbcommon0"
        "libxkbcommon-x11-0"
        "libxcomposite1"
        "libxdamage1"
        "libxext6"
        "libxfixes3"
        "libxrandr2"
        "libxi6"
        "libsm6"
        "libice6"
        "libpango-1.0-0"
        "libcairo2"
        "libexpat1"
        "libasound2t64"
        "libpulse0"
        "libnss3"
        "libnspr4"
        "libdbus-1-3"
        "libudev1"
        "libcups2t64"
        "libatk1.0-0t64"
        "libatk-bridge2.0-0t64"
        "libatspi2.0-0t64"
        "gsettings-desktop-schemas"
        "dconf-gsettings-backend"
        "xdg-utils"
        "dbus"
        "dbus-x11"
      ];

      proxySocket = "wayland-focus-proxy";

      guiEnv = lib.concatStringsSep " " [
        "WAYLAND_DISPLAY=${proxySocket}"
        "ELECTRON_OZONE_PLATFORM_HINT=auto"
        "MOZ_ENABLE_WAYLAND=1"
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
        cmdSuffix = if i == 1 then "" else toString i;
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

          enterCmd = ''${pkgs.coreutils}/bin/env ${guiEnv} ${pkgs.distrobox}/bin/distrobox enter "${boxName}"'';
          boxEnter = "${enterCmd} --";

          x11Enter = ''${pkgs.coreutils}/bin/env -u WAYLAND_DISPLAY ELECTRON_OZONE_PLATFORM_HINT=x11 GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb ${pkgs.distrobox}/bin/distrobox enter "${boxName}" --'';

          mkEnsureDeps = deps: ''
            ${boxEnter} sh -c '
              missing=""
              for p in ${lib.concatStringsSep " " deps}; do
                dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
              done
              if [ -n "$missing" ]; then
                sudo apt-get update
                sudo apt-get install -y $missing
              fi
            ' || true
          '';

          ensureAppImageDeps = mkEnsureDeps appImageDeps;
          ensureClipboardDeps = mkEnsureDeps clipboardDeps;

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
              for kind in applications icons; do
                src=${lib.escapeShellArg homeDir}/.local/share/$kind
                dst=${lib.escapeShellArg "${config.home.homeDirectory}/.local/share"}/$kind
                if [ -d "$src" ]; then
                  ${pkgs.rsync}/bin/rsync -rlpt --no-owner --no-group "$src/" "$dst/" || true
                fi
              done
            ''}

            for src in ${lib.escapeShellArg boxHome}/.local/share/applications/*.desktop; do
              [ -f "$src" ] || continue
              desktop=${lib.escapeShellArg hostApps}/''${src##*/}
              [ -f "$desktop" ] || continue
              ${pkgs.gnugrep}/bin/grep -q '^Exec=env WAYLAND_DISPLAY=${proxySocket} ' "$desktop" ||
                ${pkgs.gnused}/bin/sed -i 's|^Exec=|Exec=env ${guiEnv} |' "$desktop"
            done

            ${pkgs.desktop-file-utils}/bin/update-desktop-database \
              ${lib.escapeShellArg hostApps} 2>/dev/null || true
          '';

          box = pkgs.writeShellScriptBin "vayume-box${cmdSuffix}" ''
            set -eu

            ${ensureBox}

            if [ "$#" -eq 0 ]; then
              exec ${enterCmd}
            fi

            exec ${boxEnter} "$@"
          '';

          boxRun = pkgs.writeShellScriptBin "vayume-box${cmdSuffix}-run" ''
                        set -eu

                        ${ensureBox}

                        if [ "$#" -eq 0 ]; then
                          echo "usage: vayume box${cmdSuffix} run <command> [args...]" >&2
                          exit 2
                        fi

                        target=$1
                        shift

                        case "$target" in
                          "~/"*)
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
                            name=''${target##*/}
                            ${boxEnter} sh -c "pkill -f '[''${name:0:1}]''${name:1}'; pkill -f '[.]mount_''${name:0:6}'; sleep 2; pkill -9 -f '[''${name:0:1}]''${name:1}'; pkill -9 -f '[.]mount_''${name:0:6}'; sleep 1" || true
                            ;;
                        esac

            ${lib.optionalString (cfg.x11Apps != [ ]) ''
              case "''${target##*/}" in
                ${lib.concatStringsSep "|" cfg.x11Apps})
                  exec ${x11Enter} "$target" "$@"
                  ;;
              esac
            ''}
                        exec ${boxEnter} "$target" "$@"
          '';

          boxInstall = pkgs.writeShellScriptBin "vayume-box${cmdSuffix}-install" ''
            set -eu

            if [ "$#" -eq 0 ]; then
              echo "usage: vayume box${cmdSuffix} install <file.AppImage|file.deb|apt-package>..." >&2
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
                  echo "  vayume box${cmdSuffix} run $base"
                  echo
                  echo "If FUSE fails:"
                  echo "  vayume box${cmdSuffix} run $base --appimage-extract-and-run"
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
              echo "usage: vayume box${cmdSuffix} export <app-name>..." >&2
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
            echo "  vayume box${cmdSuffix} install <file.AppImage>"
          '';
          entry = sub: script: description: usage: {
            name = "box${cmdSuffix}${lib.optionalString (sub != "") "-${sub}"}";
            value = {
              command = lib.getExe script;
              inherit description usage;
            };
          };
        in
        builtins.listToAttrs [
          (entry "" box "Enter the '${boxName}' Distrobox (or run a command in it)" "[command...]")
          (entry "run" boxRun "Start a GUI app from '${boxName}' through the focus proxy"
            "<command> [args...]"
          )
          (entry "install" boxInstall "Install an AppImage, .deb or apt package into '${boxName}'"
            "<file.AppImage|file.deb|package>..."
          )
          (entry "apps" boxApps "List apps installed in '${boxName}'" "")
          (entry "export" boxExport "Add a '${boxName}' app to the host launcher" "<app-name>...")
          (entry "sync" boxSync "Re-sync '${boxName}' launcher entries and icons to the host" "")
          (entry "reset" boxReset "Delete and recreate '${boxName}' (its home dir is kept)" "")
        ];

      boxCommands = lib.foldl' (acc: spec: acc // mkBox spec) { } boxSpecs;

      wlFocusProxy = pkgs.stdenv.mkDerivation {
        pname = "wl-focus-proxy";
        version = "0.1.0";
        src = ./wl-focus-proxy;

        nativeBuildInputs = [
          pkgs.pkg-config
          pkgs.wayland-scanner
        ];

        buildInputs = [
          pkgs.wayland
          pkgs.wayland-protocols
        ];

        installPhase = ''
          mkdir -p $out/bin
          cp wl-focus-proxy $out/bin/
        '';

        meta.description = "Generic Wayland relay that spoofs perpetual keyboard/pointer focus";
      };

      wlFocusProxyWrapper = pkgs.writeShellScriptBin "wl-focus-proxy-wrapper" ''
        set -u

        runtime_dir="''${XDG_RUNTIME_DIR:-}"
        if [ -z "$runtime_dir" ]; then
          echo "wl-focus-proxy-wrapper: XDG_RUNTIME_DIR is not set" >&2
          exit 1
        fi

        ${pkgs.coreutils}/bin/rm -f "$runtime_dir/${proxySocket}"

        upstream=""
        i=0
        while [ "$i" -lt 100 ]; do
          newest=""
          for s in "$runtime_dir"/wayland-*; do
            [ -S "$s" ] || continue
            name=''${s##*/}
            case "$name" in
              ${proxySocket}|*.lock) continue ;;
            esac
            if [ -z "$newest" ] || [ "$s" -nt "$newest" ]; then
              newest="$s"
            fi
          done
          if [ -n "$newest" ]; then
            upstream=''${newest##*/}
            break
          fi
          i=$((i + 1))
          ${pkgs.coreutils}/bin/sleep 0.2
        done

        if [ -z "$upstream" ]; then
          echo "wl-focus-proxy-wrapper: no compositor socket found in $runtime_dir" >&2
          exit 1
        fi

        echo "wl-focus-proxy-wrapper: relaying to $upstream" >&2
        export WAYLAND_DISPLAY="$upstream"
        exec ${wlFocusProxy}/bin/wl-focus-proxy --listen ${proxySocket}
      '';

    in
    {
      options.vayume.ubuntuBox = {

        count = lib.mkOption {
          type = lib.types.ints.positive;
          default = 2;
          description = ''
            How many independent containers to manage. The first is
            always the unnumbered command set - `vayume box`,
            `vayume box run`, `vayume box install`, `vayume box apps`,
            `vayume box export`, `vayume box sync`, `vayume box reset` -
            entering "${cfg.name}".

            More than 1 adds numbered sets beside it, starting at 2:
            `vayume box2`, `vayume box2 run`, ... up through
            `vayume box<count> reset`, each entering its own container.
            The first box stays the exact same container/home and the
            same commands at any count, so raising this never orphans
            or renames a box you already have. Only box2..N are new, numbered
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
            Distrobox container name for the first box (vayume box). Also the prefix for
            box2..N when count > 1, e.g. "ubuntu" gives "ubuntu2" ..
            "ubuntu<count>" (the first box itself stays plain "ubuntu").
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
            Host directory used as the first box's container home when
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
            container, so run `vayume box reset` (or `vayume box<n> reset`)
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

        x11Apps = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "Neo-Browser*" ];

          example = [
            "Neo-Browser*"
          ];

          description = ''
            Command basenames (shell globs) that `vayume box run` starts
            under XWayland instead of Wayland, for apps that only go
            fullscreen or resize correctly on X11. They bypass the focus
            proxy.
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

      config = {
        home.packages = [
          pkgs.distrobox
          wlFocusProxy
        ];

        vayume.commands = boxCommands;

        systemd.user.services.wl-focus-proxy = {
          Unit = {
            Description = "Wayland relay that spoofs perpetual focus for Distrobox apps";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install.WantedBy = [
            "graphical-session.target"
            "default.target"
          ];
          Service = {
            ExecStart = "${wlFocusProxyWrapper}/bin/wl-focus-proxy-wrapper";
            Restart = "always";
            RestartSec = 2;
          };
        };
      };
    };
}
