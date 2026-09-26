{ ... }:
let
  flakeExpr = ''(builtins.getFlake ("path:" + builtins.toString ./.))'';

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
