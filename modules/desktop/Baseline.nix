{
  flake.homeModules.Baseline =
    {
      self,
      pkgs,
      lib,
      config,
      vayumeTheme,
      ...
    }:
    let
      theme = vayumeTheme;

      schemaDir = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";

      gtkLiveReloadScript = pkgs.writeShellScript "vayume-gtk-live-reload" ''
        set -u

        themesDir="$HOME/.local/share/themes"
        colors="$HOME/.cache/vayume/gtk3-colors.css"

        if [ -f "$colors" ]; then
          name="vayume-dank-$(${pkgs.coreutils}/bin/date +%s%N)"
          dest="$themesDir/$name/gtk-3.0"
          ${pkgs.coreutils}/bin/mkdir -p "$dest"

          ${pkgs.coreutils}/bin/cp ${./vendor/matugen-gtk/gtk3.css} "$dest/gtk.css"
          ${pkgs.coreutils}/bin/cp ${./vendor/matugen-gtk/gtk3.css} "$dest/gtk-dark.css"
          ${pkgs.coreutils}/bin/cp "$colors" "$dest/colors.css"
          ${pkgs.coreutils}/bin/chmod u+w "$dest/gtk.css" "$dest/gtk-dark.css" "$dest/colors.css"

          ${pkgs.coreutils}/bin/ln -sfn "${pkgs.adw-gtk3}/share/themes/adw-gtk3/gtk-3.0/assets" "$dest/assets" 2>/dev/null || true

          if GSETTINGS_SCHEMA_DIR=${schemaDir} \
            ${pkgs.glib.bin}/bin/gsettings set org.gnome.desktop.interface gtk-theme "$name"
          then
            for d in "$themesDir"/vayume-dank-*; do
              [ -d "$d" ] || continue
              [ "$d" = "$themesDir/$name" ] || ${pkgs.coreutils}/bin/rm -rf "$d"
            done
          fi
        fi

        exit 0
      '';
    in
    {
      options.vayume.matugenTemplates = lib.mkOption {
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
            "[config]\n" + lib.concatStringsSep "\n" (lib.attrValues config.vayume.matugenTemplates);

          ".local/share/themes/adw-gtk3".source = "${pkgs.adw-gtk3}/share/themes/adw-gtk3";

          ".config/gtk-3.0/gtk.css".text = "";

          ".config/gtk-4.0/gtk.css".source = ./vendor/matugen-gtk/gtk4.css;

          ".config/matugen/templates/gtk3-colors.css".text = self.matugenTemplates.gtk3;
          ".config/matugen/templates/gtk4-colors.css".text = self.matugenTemplates.gtk4;

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
        vayume.matugenTemplates.gtk = ''
          [templates.gtk3]
          input_path = '${config.home.homeDirectory}/.config/matugen/templates/gtk3-colors.css'
          output_path = '${config.home.homeDirectory}/.cache/vayume/gtk3-colors.css'
          post_hook = '${gtkLiveReloadScript}'

          [templates.gtk4]
          input_path = '${config.home.homeDirectory}/.config/matugen/templates/gtk4-colors.css'
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
