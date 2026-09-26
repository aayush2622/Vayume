{ lib, ... }:
{
  flake.nixosModules.Storage =
    { config, pkgs, ... }:
    let
      cfg = config.vayume.storage;

      cachePaths = [
        ".cache/vscode-cpptools"
        ".cache/appimage-run"
        ".cache/thumbnails"
        ".cache/pip"
        ".cache/pnpm"
        ".cache/yarn"
        ".cache/go-build"
        ".cache/nix"
        ".npm/_cacache"
      ];

      prelude = ''
        caches=(${lib.escapeShellArgs cachePaths})
        project_roots=(${
          lib.concatMapStringsSep " " (d: ''"$HOME"/${lib.escapeShellArg d}'') cfg.projectDirs
        })
        ${builtins.readFile ./_storage_common.sh}
      '';

      diskReport = pkgs.writeShellApplication {
        name = "vayume-disk";
        runtimeInputs = with pkgs; [
          coreutils
          findutils
          gawk
          gnused
          nix
          systemd
        ];
        text = ''
          ${prelude}
          keep_generations=5
          ${builtins.readFile ./_storage_disk.sh}
        '';
      };

      cleaner = pkgs.writeShellApplication {
        name = "vayume-clean";
        runtimeInputs = with pkgs; [
          coreutils
          findutils
          trash-cli
        ];
        text = ''
          ${prelude}
          ${builtins.readFile ./_storage_clean.sh}
        '';
      };
    in
    {
      options.vayume.storage.projectDirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "Development"
          "Projects"
          "Code"
        ];
        description = "Folders in your home directory that `vayume clean artifacts` scans for regenerable build output (node_modules, target, .venv, Flutter build folders). Only folders that exist are scanned.";
      };

      config = {
        systemd.coredump.settings.Coredump = {
          MaxUse = lib.mkDefault "200M";
          KeepFree = lib.mkDefault "2G";
        };

        services.btrfs.autoScrub =
          lib.mkIf ((config.fileSystems ? "/") && config.fileSystems."/".fsType == "btrfs")
            {
              enable = lib.mkDefault true;
              interval = lib.mkDefault "monthly";
              fileSystems = lib.mkDefault [ "/" ];
            };

        documentation.info.enable = lib.mkDefault false;
        documentation.doc.enable = lib.mkDefault false;

        vayume.commands = {
          disk = {
            command = lib.getExe diskReport;
            description = "Where the disk space goes, and what is safe to reclaim";
            usage = "[--full]";
            panel = {
              label = "Disk usage report";
              icon = "storage";
              page = "storage";
            };
          };
          clean = {
            command = lib.getExe cleaner;
            description = "Reclaim space: regenerable caches, old trash, project build artifacts (asks first)";
            usage = "<caches|trash [days]|artifacts> [--yes]";
            confirm = true;
            panel = {
              label = "Clean regenerable caches";
              icon = "cleaning_services";
              page = "storage";
              args = [
                "caches"
                "--yes"
              ];
            };
          };
        };
      };
    };
}
