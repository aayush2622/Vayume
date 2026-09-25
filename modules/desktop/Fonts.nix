{
  flake.nixosModules.Fonts =
    { pkgs, config, ... }:
    let
      theme = config.vayume.theme;

      aliasedFamilies = [
        "ui-monospace"
        "SFMono-Regular"
        "Menlo"
        "Monaco"
        "Consolas"
        "Courier New"
        "Liberation Mono"
        "DejaVu Sans Mono"
        "Noto Sans Mono"
        "Source Code Pro"
        "Fira Code"
        "Cascadia Code"
        "Roboto Mono"
        "system-ui"
        "ui-sans-serif"
        "-apple-system"
        "BlinkMacSystemFont"
        "Segoe UI"
        "Roboto"
        "Arial"
        "Helvetica"
        "Helvetica Neue"
        "Noto Sans"
        "DejaVu Sans"
        "Liberation Sans"
        "Cantarell"
        "Ubuntu"
        "Open Sans"
        "Inter"
        "Adwaita Sans"
        "ui-serif"
        "Times New Roman"
        "Times"
        "Georgia"
        "Cambria"
        "Noto Serif"
        "DejaVu Serif"
        "Liberation Serif"
      ];

      aliasRules = builtins.concatStringsSep "\n" (
        map (name: ''
          <match target="pattern">
            <test name="family" qual="any">
              <string>${name}</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>${theme.font}</string>
            </edit>
          </match>
        '') aliasedFamilies
      );
    in
    {
      fonts.packages = with pkgs; [
        inter
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        theme.fontPackage

        material-symbols
        nerd-fonts.symbols-only
      ];

      fonts.fontconfig.defaultFonts = {
        sansSerif = [ theme.font ];
        serif = [ theme.font ];
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

        ${aliasRules}
        </fontconfig>
      '';
    };
}
