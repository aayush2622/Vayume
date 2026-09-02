{ self, pkgs, lib, config, gamesDir, vayoriTheme, ... }:
{
  home.packages = with pkgs; [
    lutris
    heroic
    adwsteamgtk
  ];

  home.file = {
    "Games/.keep".text = "";

    ".config/heroic/themes/matugen/matugen.json".text = builtins.toJSON {
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
      output_path = '${config.home.homeDirectory}/.config/heroic/themes/matugen/matugen.css'
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

  home.activation.heroicSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    HEROIC_CONFIG="$HOME/.config/heroic/store/config.json"
    run mkdir -p "$(dirname "$HEROIC_CONFIG")"

    if [ ! -f "$HEROIC_CONFIG" ]; then
      run sh -c "printf '{\"settings\":{}}' > '$HEROIC_CONFIG'"
    fi

    HEROIC_CONFIG_TMP="$(mktemp)"

    ${pkgs.jq}/bin/jq \
      --arg themesPath "$HOME/.config/heroic/themes/matugen" \
      --arg font ${lib.escapeShellArg vayoriTheme.font} \
      --arg winePrefix ${lib.escapeShellArg "${gamesDir}/.wineprefix"} \
      '.settings.customThemesPath = $themesPath
       | .theme = "matugen.css"
       | .contentFontFamily = $font
       | .actionsFontFamily = $font
       | .settings.winePrefix = $winePrefix' \
      "$HEROIC_CONFIG" > "$HEROIC_CONFIG_TMP" \
      && run cp "$HEROIC_CONFIG_TMP" "$HEROIC_CONFIG"

    rm -f "$HEROIC_CONFIG_TMP"
  '';
}
