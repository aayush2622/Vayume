{
  flake.homeModules.Baseline =
    {
      self,
      pkgs,
      lib,
      config,
      vayoriTheme,
      ...
    }:
    let
      theme = vayoriTheme;
    in
    {
      options.vayori.matugenTemplates = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        description = ''
          Extra matugen templates, one `[templates.<id>]` TOML block per
          entry, merged into a single ~/.config/matugen/config.toml.
        '';
      };

      config = {
        home.file = {
          ".config/matugen/config.toml".text =
            "[config]\n" + lib.concatStringsSep "\n" (lib.attrValues config.vayori.matugenTemplates);

          ".local/share/themes/adw-gtk3".source = "${pkgs.adw-gtk3}/share/themes/adw-gtk3";

          ".config/matugen/templates/gtk-matugen.css".text = self.matugenTemplates.gtk;

          ".config/qt5ct/qt5ct.conf" = {
            force = true;
            text = ''
              [Appearance]
              custom_palette=true
              color_scheme_path=${config.home.homeDirectory}/.config/qt5ct/colors/matugen.conf
              icon_theme=${theme.iconTheme}
              style=Fusion
            '';
          };

          ".config/qt6ct/qt6ct.conf" = {
            force = true;
            text = ''
              [Appearance]
              custom_palette=true
              color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/matugen.conf
              icon_theme=${theme.iconTheme}
              style=Fusion
            '';
          };
        };

        gtk = {
          enable = true;

          theme = {
            name = "adw-gtk3";
            package = pkgs.adw-gtk3;
          };

          gtk4.theme = null;

          iconTheme = {
            name = theme.iconTheme;
            package = theme.iconPackage;
          };

          cursorTheme = {
            name = theme.cursorTheme;
            package = theme.cursorPackage;
            size = theme.cursorSize;
          };

          font = {
            name = theme.font;
            size = theme.fontSize;
          };
        };
        vayori.matugenTemplates.gtk = ''
          [templates.gtk3]
          input_path = '${config.home.homeDirectory}/.config/matugen/templates/gtk-matugen.css'
          output_path = '${config.home.homeDirectory}/.config/gtk-3.0/colors.css'
          post_hook = 'gsettings set org.gnome.desktop.interface gtk-theme ""; gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-{{mode}}'

          [templates.gtk4]
          input_path = '${config.home.homeDirectory}/.config/matugen/templates/gtk-matugen.css'
          output_path = '${config.home.homeDirectory}/.config/gtk-4.0/colors.css'
          post_hook = 'gsettings set org.gnome.desktop.interface color-scheme default; gsettings set org.gnome.desktop.interface color-scheme prefer-{{mode}}'
        '';

        home.pointerCursor = {
          enable = true;
          gtk.enable = true;

          package = theme.cursorPackage;
          name = theme.cursorTheme;
          size = theme.cursorSize;
        };

        qt = {
          enable = true;
          platformTheme.name = "qtct";
        };

        home.packages = with pkgs; [
          libsForQt5.qt5ct
          qt6Packages.qt6ct
        ];

        xdg.userDirs = {
          enable = true;
          createDirectories = true;
          setSessionVariables = true;
        };
      };
    };
}
