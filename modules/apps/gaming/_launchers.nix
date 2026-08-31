{ self, pkgs, lib, config, gamesDir, ... }:
{
  home.packages = with pkgs; [
    lutris
    heroic
    adwsteamgtk
  ];

  home.file = {
    "Games/.keep".text = "";

    ".local/share/heroic-matugen-theme/matugen.json".text = builtins.toJSON {
      name = "Matugen";
      filename = "matugen.css";
    };

    ".config/matugen/templates/heroic-matugen.css".text = self.matugenTemplates.heroic;
    ".config/matugen/templates/steam-colors.css".text = self.matugenTemplates.steam;
  };

  vayori.matugenTemplates = {
    heroic = ''
      [templates.heroic]
      input_path = '${config.home.homeDirectory}/.config/matugen/templates/heroic-matugen.css'
      output_path = '${config.home.homeDirectory}/.local/share/heroic-matugen-theme/matugen.css'
    '';

    steam = ''
      [templates.steam]
      input_path = '${config.home.homeDirectory}/.config/matugen/templates/steam-colors.css'
      output_path = '${config.home.homeDirectory}/.config/AdwSteamGtk/custom.css'
    '';
  };

  home.activation.gamesBookmark = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    BOOKMARKS="$HOME/.config/gtk-3.0/bookmarks"
    GAMES_URI="file://${gamesDir} Games"
    run mkdir -p "$(dirname "$BOOKMARKS")"
    run touch "$BOOKMARKS"
    grep -qxF "$GAMES_URI" "$BOOKMARKS" 2>/dev/null || run sh -c "printf '%s\n' \"$GAMES_URI\" >> \"$BOOKMARKS\""
  '';
}
