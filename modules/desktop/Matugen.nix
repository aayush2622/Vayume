{ lib, ... }: {
  options.flake.matugenTemplates = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Raw matugen template content shared across app modules - see modules/desktop/Matugen.nix.";
  };

  config.flake.matugenTemplates = {
    gtk3 = builtins.readFile ./matugen/gtk/gtk3-colors.css.template;
    gtk4 = builtins.readFile ./matugen/gtk/gtk4-colors.css.template;

    zed = builtins.readFile ./matugen/zed/dank-zed-one-dark.json;

    discord = builtins.readFile ../apps/utils/vesktop/theme/discord.css.template;

    spotifast = builtins.readFile ./matugen/spotifast/spotifast.json.template;

    btop = builtins.readFile ./matugen/btop/btop.theme.template;

    cava = builtins.readFile ./matugen/cava/cava.ini.template;

    heroic = builtins.readFile ./matugen/heroic/heroic.css.template;

    steam = builtins.readFile ./matugen/steam/steam.css.template;

    wine = builtins.readFile ./matugen/wine/wine.reg.template;

    androidStudio =
      schemeName:
      builtins.replaceStrings [ "VAYUME_SCHEME_TOKEN" ] [ schemeName ] (
        builtins.readFile ./matugen/androidstudio/scheme.xml.template
      );

    androidStudioTheme =
      schemeName: colorSchemeName:
      builtins.replaceStrings
        [ "VAYUME_SCHEME_TOKEN" "VAYUME_COLORSCHEME_TOKEN" ]
        [ schemeName colorSchemeName ]
        (builtins.readFile ./matugen/androidstudio/theme.json.template);
  };
}
