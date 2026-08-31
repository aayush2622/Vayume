{
  flake.nixosModules.Fonts = { pkgs, config, ... }:
  let theme = config.vayori.theme; in
  {
    fonts.packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-color-emoji
      theme.fontPackage
      material-symbols
    ];

    fonts.fontconfig.defaultFonts = {
      sansSerif = [ theme.font ];
      monospace = [ theme.font ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
