{
  pkgs,
  lib,
  gamesDir,
  ...
}:
let
  gameSync = pkgs.writeShellApplication {
    name = "vayume-games-sync";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnused
      jq
      procps
    ];
    text = ''
      export GAMES_DIR=${lib.escapeShellArg gamesDir}
      ${builtins.readFile ./_gamesync.sh}
    '';
  };
in
{
  systemd.user.services.steam-heroic-sync = {
    Unit.Description = "Add installed Steam games to Heroic's library";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe gameSync;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.paths.steam-heroic-sync = {
    Unit.Description = "Watch Steam libraries for installs and removals";
    Path = {
      PathChanged = [
        "%h/.local/share/Steam/steamapps"
        "${gamesDir}/Steam/steamapps"
      ];
      Unit = "steam-heroic-sync.service";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # One Proton for every launcher: Steam and Heroic scan this folder, and
  # Lutris/umu can point PROTONPATH at it.
  home.file.".local/share/Steam/compatibilitytools.d/GE-Proton-nix".source =
    pkgs.proton-ge-bin.steamcompattool;
}
