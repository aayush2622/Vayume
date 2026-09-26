{
  flake.nixosModules.SddmTheme =
    { pkgs, config, ... }:
    let
      themeConf = pkgs.writeText "theme.conf" ''
        [General]
        background=bg.jpg
        font=Itim
        fontFamily=${config.vayume.theme.font}
        cursorTheme=${config.vayume.theme.cursorTheme}
        cursorSize=${toString config.vayume.theme.cursorSize}
      '';

      vayoriTheme = pkgs.stdenvNoCC.mkDerivation {
        name = "vayori";

        src = ./Theme;

        installPhase = ''
          mkdir -p $out/share/sddm/themes/vayori
          cp -r . $out/share/sddm/themes/vayori
          cp -r ${../lockscreen/vayori} $out/share/sddm/themes/vayori/vayori
          install -m 644 ${../../assets/wallpapers/blue-girl-among-flowers.jpg} $out/share/sddm/themes/vayori/bg.jpg
          install -m 644 ${themeConf} $out/share/sddm/themes/vayori/theme.conf
        '';
      };
    in
    {
      services.displayManager.sddm.enable = true;
      services.displayManager.sddm.wayland.enable = true;

      services.displayManager.sddm.theme = "${vayoriTheme}/share/sddm/themes/vayori";
    };
}
