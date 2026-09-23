{ ... }: {
  flake.devLanguages.Nix = {
    vscode = {
      nixpkgsExtensions = [
        "jnoortheen.nix-ide"
        "arrterian.nix-env-selector"
      ];
      marketplaceExtensions = [
        { publisher = "ziyyun"; name = "nix-forge"; }
        { publisher = "pinage404"; name = "nix-extension-pack"; }
      ];
      settings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.formatterPath" = "nixfmt";
        "nix.serverSettings".nixd = {
          formatting.command = [ "nixfmt" ];
          nixpkgs.expr = ''import (builtins.getFlake ("path:" + builtins.toString ./.)).inputs.nixpkgs { }'';
          options = {
            nixos.expr = ''(builtins.getFlake ("path:" + builtins.toString ./.)).nixosConfigurations.Diablo.options'';
            home-manager.expr = ''(builtins.getFlake ("path:" + builtins.toString ./.)).nixosConfigurations.Diablo.options.home-manager.users.type.getSubOptions [ ]'';
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
        { dirName = "NixIDEA"; id = "nix-idea"; }
      ];
    };
    zed = {
      extensions = [ "nix" ];
    };
  };

  flake.appDescriptions.Nix = "Nix language tooling: nixd and nil language servers, nixfmt, editor integrations.";

  flake.homeModules.apps.Nix = { pkgs, ... }: {
    home.packages = with pkgs; [
      nil
      nixd
      nixfmt
    ];
  };
}
