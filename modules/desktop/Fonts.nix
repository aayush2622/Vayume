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
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <edit name="family" mode="append" binding="strong">
            <string>Noto Color Emoji</string>
          </edit>
        </match>

        <match target="pattern">
          <test name="prgname">
            <string>WebKitWebProcess</string>
          </test>
          <test target="pattern" name="family">
            <string>sans-serif</string>
          </test>
          <edit name="family" mode="assign" binding="strong">
            <string>${theme.font}</string>
          </edit>
        </match>
      </fontconfig>
    '';
  };
}
