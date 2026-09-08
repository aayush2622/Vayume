{ self, pkgs, config, gamesDir, ... }:
{
  home.packages = with pkgs; [
    umu-launcher
    protonup-qt
    winetricks
    protontricks
    wine
  ];

  home.sessionVariables = {
    WINEPREFIX = "${gamesDir}/.wineprefix";
  };

  home.file.".config/matugen/templates/wine-colors.reg".text = self.matugenTemplates.wine;

  vayume.matugenTemplates.wine = ''
    [templates.wine]
    input_path = '${config.home.homeDirectory}/.config/matugen/templates/wine-colors.reg'
    output_path = '/tmp/wine.reg'
    post_hook = 'test -d "${gamesDir}/.wineprefix" && WINEPREFIX="${gamesDir}/.wineprefix" nohup wine regedit /tmp/wine.reg > /dev/null 2>&1 &'
  '';

  xdg.configFile."lutris/runners/wine.yml" = {
    force = true;
    text = builtins.toJSON {
      wine = {
        version = "ge-proton";
      };
    };
  };
}
