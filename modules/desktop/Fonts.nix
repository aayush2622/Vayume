{
  flake.nixosModules.Fonts = { pkgs, config, ... }:
  let theme = config.vayume.theme; in
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

    fonts.fontconfig.localConf = ''
      <match target="pattern">
        <edit name="family" mode="append" binding="strong">
          <string>Noto Color Emoji</string>
        </edit>
      </match>
    '';
  };
}
