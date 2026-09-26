{ config, lib, ... }:
let
  discovery = config.flake.vayumeLib.repoDiscovery;

  repoExpr = ''
    (let
      home = builtins.getEnv "HOME";
      candidates = map (d: home + "/" + d) [ ${
        lib.concatMapStringsSep " " (d: ''"${d}"'') discovery.relativeDirs
      } ] ++ [ ${lib.concatMapStringsSep " " (d: ''"${d}"'') discovery.absoluteDirs} ];
      found = builtins.filter (d: builtins.pathExists (d + "/flake.nix")) candidates;
    in if found == [ ] then builtins.toString ./. else builtins.head found)'';

  flakeExpr = ''
    (let
      repo = ${repoExpr};
      lock = builtins.fromJSON (builtins.readFile (repo + "/flake.lock"));
      compat = builtins.head (builtins.filter (n: (n.locked.repo or "") == "flake-compat") (builtins.attrValues lock.nodes));
    in (import (builtins.fetchTree compat.locked) { src = { outPath = repo; }; }).defaultNix)'';

  hostExpr = ''
    (let
      hosts = ${flakeExpr}.nixosConfigurations;
      name = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile /etc/hostname);
    in hosts.''${name} or (builtins.head (builtins.attrValues hosts)))'';
in
{
  flake.devLanguages.Nix = {
    vscode = {
      nixpkgsExtensions = [
        "jnoortheen.nix-ide"
        "arrterian.nix-env-selector"
      ];
      marketplaceExtensions = [
        {
          publisher = "ziyyun";
          name = "nix-forge";
        }
        {
          publisher = "pinage404";
          name = "nix-extension-pack";
        }
      ];
      settings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.formatterPath" = "nixfmt";
        "nix.serverSettings".nixd = {
          formatting.command = [ "nixfmt" ];
          nixpkgs.expr = "import ${flakeExpr}.inputs.nixpkgs { }";
          options = {
            nixos.expr = "${hostExpr}.options";
            home-manager.expr = "${hostExpr}.options.home-manager.users.type.getSubOptions [ ]";
          };
        };
        "[nix]" = {
          "editor.defaultFormatter" = "ZiYyun.nix-forge";
          "editor.formatOnSave" = true;
        };
      };
    };
    androidStudio = {
      autoPlugins = [
        {
          dirName = "NixIDEA";
          id = "nix-idea";
        }
      ];
    };
    zed = {
      extensions = [ "nix" ];
    };
  };

  flake.appMeta.Nix = {
    description = "Nix language tooling: nixd and nil language servers, nixfmt, editor integrations.";
    label = "Nix";
    icon = "nix-snowflake";
    symbol = "ac_unit";
    section = "Languages";
  };

  flake.homeModules.apps.Nix = { pkgs, ... }: {
    home.packages = with pkgs; [
      nil
      nixd
      nixfmt
    ];
  };
}
