{ lib, config, ... }: {
  options.flake.vayumeLib.repoDiscovery = lib.mkOption {
    type = lib.types.unspecified;
    default = {
      relativeDirs = [ "vayume" "dotfiles" ".dotfiles" ];
      absoluteDirs = [ "/etc/nixos" ];
    };
    description = ''
      The candidate locations any Vayume tooling checks to find the
      flake checkout for a given $HOME - see modules/lib/VayumeLib.nix
      and docs/core-vayume-config.md. relativeDirs are joined with a
      $HOME-like shell variable; absoluteDirs are checked as-is. A
      directory counts as a match once it has a flake.nix in it.
    '';
  };

  options.flake.vayumeLib.desktopActions = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default =
      let
        choice = id: label: app: desktop: argv: { inherit id label app desktop argv; };
      in
      {
        terminal = {
          label = "Terminal";
          mimeTypes = [ ];
          choices = [ (choice "kitty" "kitty" "Terminal" "kitty.desktop" [ "kitty" ]) ];
        };
        fileManager = {
          label = "File manager";
          mimeTypes = [ "inode/directory" "x-directory/normal" ];
          choices = [
            (choice "thunar" "Thunar" "Thunar" "thunar.desktop" [ "thunar" ])
            (choice "nautilus" "Nautilus" "Nautilus" "org.gnome.Nautilus.desktop" [ "nautilus" ])
          ];
        };
        editor = {
          label = "Code editor";
          mimeTypes = [
            "text/plain" "text/markdown" "text/x-python" "text/javascript"
            "text/vnd.trolltech.linguist" "application/x-tiled-tsx" "application/json"
            "application/yaml" "application/toml" "application/x-shellscript"
            "text/x-csrc" "text/x-chdr" "text/x-c++src" "text/x-c++hdr" "text/rust"
            "text/x-go" "text/html" "text/css" "application/xml" "text/x-log"
            "text/x-lua" "application/x-ruby" "application/x-php" "application/sql"
          ];
          choices = [
            (choice "code" "VS Code" "Vscode" "code.desktop" [ "code" ])
            (choice "zeditor" "Zed" "Zed" "dev.zed.Zed.desktop" [ "zeditor" ])
            (choice "android-studio" "Android Studio" "AndroidStudio" "android-studio.desktop" [ "android-studio" ])
          ];
        };
        browser = {
          label = "Web browser";
          mimeTypes = [ "x-scheme-handler/http" "x-scheme-handler/https" "application/xhtml+xml" ];
          choices = [
            (choice "zen" "Zen Browser" "ZenBrowser" "zen.desktop" [ "zen" ])
            (choice "firefox" "Firefox" null null [ "firefox" ])
            (choice "chromium" "Chromium" null null [ "chromium" ])
          ];
        };
        browserReload.choices = [ (choice "zen-reload" "Zen reload" "ZenBrowser" null [ "vayume" "zen-reload" ]) ];
        systemMonitor.choices = [ (choice "btop" "btop" "Terminal" null [ "kitty" "-e" "btop" ]) ];
        colorPicker.choices = [ (choice "hyprpicker" "hyprpicker" null null [ "hyprpicker" "-a" ]) ];
      };
    description = ''
      Per action: the programs to try in order (`choices`), and for the
      roles that have a `label`, the MIME types the chosen one becomes
      the default for - see docs/desktop-default-apps.md. A choice with
      an `app` can be picked in vayume.defaultApps; the others are only
      fallbacks. Launched through mkDesktopActions, never directly.
    '';
  };

  options.flake.vayumeLib.mkDesktopActions = lib.mkOption {
    type = lib.types.unspecified;
    readOnly = true;
    description = ''
      pkgs -> { <action> = [ "/nix/store/...-vayume-launch-<action>" ]; }
      - one argv per desktopActions entry: the choice named in
      /etc/vayume/default-apps if it's installed, else the first
      installed choice, else a notification naming the app to enable.
    '';
  };

  config.flake.vayumeLib.mkDesktopActions = pkgs:
    lib.mapAttrs (name: action:
      let
        apps = lib.unique (builtins.filter (a: a != null) (map (c: c.app) action.choices));
        installed = argv: "command -v ${lib.escapeShellArg (builtins.head argv)} >/dev/null 2>&1${
          lib.optionalString (builtins.head argv == "vayume")
            " && vayume --has ${lib.escapeShellArg (builtins.elemAt argv 1)}"
        }";
      in [
      (lib.getExe (pkgs.writeShellScriptBin "vayume-launch-${name}" ''
        preferred=""
        if [ -r /etc/vayume/default-apps ]; then
          while IFS='=' read -r role id; do
            [ "$role" = ${lib.escapeShellArg name} ] && preferred=$id
          done < /etc/vayume/default-apps
        fi
        case "$preferred" in
        ${lib.concatMapStrings (c: ''
          ${lib.escapeShellArg c.id})
            if ${installed c.argv}; then exec ${lib.escapeShellArgs c.argv} "$@"; fi
            ;;
        '') action.choices}
        esac
        ${lib.concatMapStrings (c: ''
          if ${installed c.argv}; then exec ${lib.escapeShellArgs c.argv} "$@"; fi
        '') action.choices}
        exec ${pkgs.libnotify}/bin/notify-send -a Vayume "Nothing installed for ${name}" ${lib.escapeShellArg (
          if apps == [ ] then
            "None of: ${lib.concatMapStringsSep ", " (c: builtins.head c.argv) action.choices}"
          else
            "Enable one of ${lib.concatMapStringsSep ", " (a: "vayume.apps.${a}") apps} in _config.nix, then rebuild."
        )}
      ''))
    ]) config.flake.vayumeLib.desktopActions;
}
