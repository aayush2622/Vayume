{
  self,
  pkgs,
  lib,
  config,
  gamesDir,
  vayumeTheme,
  ...
}:
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

  vayume.matugenTemplates = {
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

  home.activation.steamLibrary = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    STEAMAPPS="$HOME/.local/share/Steam/steamapps"
    GAMES_STEAM=${lib.escapeShellArg "${gamesDir}/Steam/steamapps"}
    if [ ! -e "$STEAMAPPS" ] && [ ! -L "$STEAMAPPS" ]; then
      run mkdir -p "$GAMES_STEAM" "$(dirname "$STEAMAPPS")"
      run ln -s "$GAMES_STEAM" "$STEAMAPPS"
    fi
  '';

  home.activation.heroicSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    HEROIC_CONFIG="$HOME/.config/heroic/store/config.json"
    HEROIC_MAIN_CONFIG="$HOME/.config/heroic/config.json"
    HEROIC_PREFIX=${lib.escapeShellArg "${gamesDir}/.wineprefix"}
    run mkdir -p "$(dirname "$HEROIC_CONFIG")" "$HEROIC_PREFIX"

    if [ ! -s "$HEROIC_CONFIG" ] || ! ${pkgs.jq}/bin/jq -e . "$HEROIC_CONFIG" > /dev/null 2>&1; then
      run sh -c "printf '{\"settings\":{}}' > '$HEROIC_CONFIG'"
    fi

    HEROIC_CONFIG_TMP="$HEROIC_CONFIG.vayume-tmp"

    if ${pkgs.jq}/bin/jq \
      --arg themesPath "$HOME/.config/heroic/themes/matugen" \
      --arg font ${lib.escapeShellArg vayumeTheme.font} \
      --arg winePrefix "$HEROIC_PREFIX" \
      '.settings.customThemesPath = $themesPath
       | .theme = "matugen.css"
       | .contentFontFamily = $font
       | .actionsFontFamily = $font
       | .settings.winePrefix = $winePrefix' \
      "$HEROIC_CONFIG" > "$HEROIC_CONFIG_TMP" && [ -s "$HEROIC_CONFIG_TMP" ]; then
      run mv -f "$HEROIC_CONFIG_TMP" "$HEROIC_CONFIG"
    else
      echo "heroicSettings: jq merge failed, leaving $HEROIC_CONFIG untouched" >&2
      rm -f "$HEROIC_CONFIG_TMP"
    fi

    if [ -s "$HEROIC_MAIN_CONFIG" ] && ${pkgs.jq}/bin/jq -e . "$HEROIC_MAIN_CONFIG" > /dev/null 2>&1; then
      HEROIC_MAIN_TMP="$HEROIC_MAIN_CONFIG.vayume-tmp"
      if ${pkgs.jq}/bin/jq \
        --arg installPath ${lib.escapeShellArg "${gamesDir}/Heroic"} \
        --arg winePrefix "$HEROIC_PREFIX" \
        --arg steamPath "$HOME/.local/share/Steam" \
        '.defaultSettings.defaultInstallPath = $installPath
         | .defaultSettings.winePrefix = $winePrefix
         | .defaultSettings.defaultSteamPath = $steamPath
         | .defaultSettings.downloadProtonToSteam = true' \
        "$HEROIC_MAIN_CONFIG" > "$HEROIC_MAIN_TMP" && [ -s "$HEROIC_MAIN_TMP" ]; then
        run mv -f "$HEROIC_MAIN_TMP" "$HEROIC_MAIN_CONFIG"
      else
        rm -f "$HEROIC_MAIN_TMP"
      fi
    fi
  '';
}
