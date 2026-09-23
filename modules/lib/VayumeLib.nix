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
    default = {
      terminal = { apps = [ "Terminal" ]; candidates = [ [ "kitty" ] ]; };
      fileManager = { apps = [ "Thunar" "Nautilus" ]; candidates = [ [ "thunar" ] [ "nautilus" ] ]; };
      editor = { apps = [ "Vscode" "Zed" "AndroidStudio" ]; candidates = [ [ "code" ] [ "zeditor" ] [ "android-studio" ] ]; };
      browser = { apps = [ "ZenBrowser" ]; candidates = [ [ "zen" ] [ "firefox" ] [ "chromium" ] ]; };
      browserReload = { apps = [ "ZenBrowser" ]; candidates = [ [ "vayume" "zen-reload" ] ]; };
      systemMonitor = { apps = [ "Terminal" ]; candidates = [ [ "kitty" "-e" "btop" ] ]; };
      colorPicker = { apps = [ ]; candidates = [ [ "hyprpicker" "-a" ] ]; };
    };
    description = ''
      Per action: the commands to try in order, and which vayume.apps
      provide them - see docs/desktop-hyprland.md. Read through
      mkDesktopActions, never directly.
    '';
  };

  options.flake.vayumeLib.mkDesktopActions = lib.mkOption {
    type = lib.types.unspecified;
    readOnly = true;
    description = ''
      pkgs -> { <action> = [ "/nix/store/...-vayume-launch-<action>" ]; }
      - one argv per desktopActions entry, running the first installed
      candidate or explaining which app to enable.
    '';
  };

  config.flake.vayumeLib.mkDesktopActions = pkgs:
    lib.mapAttrs (name: action: [
      (lib.getExe (pkgs.writeShellScriptBin "vayume-launch-${name}" ''
        ${lib.concatMapStrings (argv: ''
          if command -v ${lib.escapeShellArg (builtins.head argv)} >/dev/null 2>&1${
            lib.optionalString (builtins.head argv == "vayume")
              " && vayume --has ${lib.escapeShellArg (builtins.elemAt argv 1)}"
          }; then
            exec ${lib.escapeShellArgs argv} "$@"
          fi
        '') action.candidates}
        exec ${pkgs.libnotify}/bin/notify-send -a Vayume "Nothing installed for ${name}" ${lib.escapeShellArg (
          if action.apps == [ ] then
            "None of: ${lib.concatMapStringsSep ", " builtins.head action.candidates}"
          else
            "Enable one of ${lib.concatMapStringsSep ", " (a: "vayume.apps.${a}") action.apps} in _config.nix, then rebuild."
        )}
      ''))
    ]) config.flake.vayumeLib.desktopActions;
}
