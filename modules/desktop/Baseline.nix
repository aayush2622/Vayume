{
  flake.homeModules.Baseline =
    {
      pkgs,
      lib,
      config,
      vayoriTheme,
      ...
    }:
    let
      theme = vayoriTheme;
      papirusIconsDir = ".local/share/icons/Papirus";
      isPapirus = theme.iconTheme == "Papirus";
    in
    {
      options.vayori.matugenTemplates = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        description = ''
          Extra matugen templates, one `[templates.<id>]` TOML block per
          entry, merged into a single ~/.config/matugen/config.toml -
          exactly the file and format DMS's own docs document
          (https://danklinux.com/docs/dankmaterialshell/application-themes).
          `input_path`/`output_path` are absolute paths of the app module's
          own choosing (only this merged config.toml itself has to live at
          this exact path - see Matugen.nix for where the template bodies
          these blocks point at actually live).
        '';
      };

      config = lib.mkMerge [
        {
          home.file.".config/matugen/config.toml".text =
            "[config]\n\n" + lib.concatStringsSep "\n" (lib.attrValues config.vayori.matugenTemplates);

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

          home.activation.applyDmsGtkColors =
            let
              dmsShareDir = "${config.programs.dank-material-shell.package}/share/quickshell/dms";
            in
            lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              if [ -f "$HOME/.config/gtk-3.0/dank-colors.css" ] || [ -f "$HOME/.config/gtk-4.0/dank-colors.css" ]; then
                run mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
                run ${dmsShareDir}/scripts/gtk.sh "$HOME/.config" false "${dmsShareDir}" || true
              fi
            '';

          home.file.".config/matugen/templates/gtk-reload-trigger".text = "{{ colors.primary.default.hex }}\n";

          vayori.matugenTemplates.gtkLiveReload = ''
            [templates.gtkLiveReload]
            input_path = '${config.home.homeDirectory}/.config/matugen/templates/gtk-reload-trigger'
            output_path = '${config.home.homeDirectory}/.cache/vayori/gtk-reload-trigger'
            post_hook = 'gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null; gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3 2>/dev/null'
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

          home.file = {
            ".local/share/themes/adw-gtk3".source = "${pkgs.adw-gtk3}/share/themes/adw-gtk3";
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

          xdg.userDirs = {
            enable = true;
            createDirectories = true;
            setSessionVariables = true;
          };
        }

        (lib.mkIf isPapirus {
          home.packages = [
            pkgs.papirus-folders
            pkgs.gtk3
          ];

          home.activation.installPapirusIconTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            iconsDir="$HOME/${papirusIconsDir}"
            stampFile="$iconsDir/.vayori-source-path"
            if [ ! -f "$stampFile" ] || [ "$(cat "$stampFile")" != "${theme.iconPackage}" ]; then
              run mkdir -p "$iconsDir"
              run ${pkgs.rsync}/bin/rsync -aL --delete --chmod=u+w "${theme.iconPackage}/share/icons/Papirus/." "$iconsDir/"
              echo -n "${theme.iconPackage}" > "$stampFile"
            fi
          '';

          home.file.".config/matugen/templates/papirus-color".text = "";

          vayori.matugenTemplates.papirusFolders = ''
            [templates.papirusFolders]
            input_path = '${config.home.homeDirectory}/.config/matugen/templates/papirus-color'
            colors_to_compare = [
              { name = "black", color = "#4f4f4f" },
              { name = "blue", color = "#5294e2" },
              { name = "bluegrey", color = "#607d8b" },
              { name = "brown", color = "#ae8e6c" },
              { name = "carmine", color = "#a30002" },
              { name = "cyan", color = "#00bcd4" },
              { name = "darkcyan", color = "#45abb7" },
              { name = "deeporange", color = "#eb6637" },
              { name = "green", color = "#87b158" },
              { name = "grey", color = "#8e8e8e" },
              { name = "indigo", color = "#5c6bc0" },
              { name = "magenta", color = "#ca71df" },
              { name = "nordic", color = "#81a1c1" },
              { name = "orange", color = "#ee923a" },
              { name = "palebrown", color = "#d1bfae" },
              { name = "paleorange", color = "#eeca8f" },
              { name = "pink", color = "#f06292" },
              { name = "red", color = "#e25252" },
              { name = "teal", color = "#16a085" },
              { name = "violet", color = "#7e57c2" },
              { name = "white", color = "#e4e4e4" },
              { name = "yaru", color = "#676767" },
              { name = "yellow", color = "#f9bd30" },
            ]
            compare_to = "{{ colors.primary.default.hex }}"
            post_hook = 'nohup papirus-folders -t "${config.home.homeDirectory}/${papirusIconsDir}" -C {{ closest_color }} -u > /dev/null 2>&1 &'
            index = 1
          '';
        })
      ];
    };
}
