{ lib, ... }: {
  options.flake.matugenTemplates = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Raw matugen template content shared across app modules - see modules/desktop/Matugen.nix.";
  };

  config.flake.matugenTemplates = {
    gtk3 = builtins.readFile ./vendor/matugen-gtk/gtk3-colors.css.template;
    gtk4 = builtins.readFile ./vendor/matugen-gtk/gtk4-colors.css.template;

    zed = builtins.readFile ./vendor/matugen-zed/dank-zed-one-dark.json;

    discord = builtins.readFile ../apps/utils/vesktop/vendor/discord.css.template;

    spotifast = builtins.readFile ./vendor/matugen-spotifast/spotifast.json.template;

    btop = builtins.readFile ./vendor/matugen-btop/btop.theme.template;

    cava = builtins.readFile ./vendor/matugen-cava/cava.ini.template;

    heroic = builtins.readFile ./vendor/matugen-heroic/heroic.css.template;

    steam = builtins.readFile ./vendor/matugen-steam/steam.css.template;

    wine = builtins.readFile ./vendor/matugen-wine/wine.reg.template;

    androidStudio = schemeName: builtins.replaceStrings
      [ "VAYUME_SCHEME_TOKEN" ]
      [ schemeName ]
      (builtins.readFile ./vendor/matugen-androidstudio/scheme.xml.template);

    androidStudioTheme = schemeName: colorSchemeName: builtins.replaceStrings
      [ "VAYUME_SCHEME_TOKEN" "VAYUME_COLORSCHEME_TOKEN" ]
      [ schemeName colorSchemeName ]
      (builtins.readFile ./vendor/matugen-androidstudio/theme.json.template);
  };
}
