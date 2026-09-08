{ inputs, ... }: {
  flake.homeModules.apps.Spicetify = { pkgs, vayumeTheme, ... }:
  let
    spicePkgs =
      inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in {
    imports = [
      inputs.spicetify-nix.homeManagerModules.default
    ];

    programs.spicetify = {
      enable = true;

      spicetifyPackage = pkgs.spicetify-cli;

      wayland = true;

      theme = spicePkgs.themes.hazy // {
        extraPkgs = [ vayumeTheme.fontPackage ];
        additionalCss = ''
          :root {
            --font-family: "${vayumeTheme.font}", sans-serif !important;
          }
        '';
      };
      colorScheme = "Base";

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        shuffle
        fullAppDisplay
      ];

      enabledCustomApps = with spicePkgs.apps; [
        lyricsPlus
      ];
    };
  };
}