{
  flake.nixosModules.SddmTheme = { pkgs, config, ... }:
  let
    themeConf = pkgs.writeText "theme.conf" ''
      [General]
      background=bg.png
      font=Itim
      themeMode=light
      cursorTheme=${config.vayori.theme.cursorTheme}
      cursorSize=${toString config.vayori.theme.cursorSize}
    '';

    womenUmbrella = pkgs.stdenvNoCC.mkDerivation {
      name = "women-umbrella";

      src = ./Theme;

      installPhase = ''
        mkdir -p $out/share/sddm/themes/women-umbrella
        cp -r . $out/share/sddm/themes/women-umbrella
        install -m 644 ${themeConf} $out/share/sddm/themes/women-umbrella/theme.conf
      '';
    };
  in
  {
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;

    services.displayManager.sddm.theme =
      "${womenUmbrella}/share/sddm/themes/women-umbrella";
  };
}
