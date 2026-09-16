{ lib, ... }: {
  flake.nixosModules.Theme = { pkgs, lib, ... }: {
    options.vayume.theme = lib.mkOption {
      description = "System-wide look & feel - one place to set the font, cursor theme, and icon theme, used everywhere they're needed.";
      default = { };
      type = lib.types.submodule {
        options = {
          font = lib.mkOption {
            type = lib.types.str;
            default = "JetBrainsMono Nerd Font";
            description = "UI/monospace font family, used by fontconfig, GTK, kitty, and DMS.";
          };
          fontPackage = lib.mkOption {
            type = lib.types.package;
            default = pkgs.nerd-fonts.jetbrains-mono;
            description = "Package providing `font`.";
          };
          fontSize = lib.mkOption {
            type = lib.types.int;
            default = 11;
          };

          cursorTheme = lib.mkOption {
            type = lib.types.str;
            default = "Bibata-Modern-Ice";
            description = "Xcursor theme name, used by GTK, SDDM, and XCURSOR_THEME.";
          };
          cursorPackage = lib.mkOption {
            type = lib.types.package;
            default = pkgs.bibata-cursors;
            description = "Package providing `cursorTheme`.";
          };
          cursorSize = lib.mkOption {
            type = lib.types.int;
            default = 24;
          };

          iconTheme = lib.mkOption {
            type = lib.types.str;
            default = "Adwaita";
            description = "GTK icon theme name.";
          };
          iconPackage = lib.mkOption {
            type = lib.types.package;
            default = pkgs.adwaita-icon-theme;
            description = "Package providing `iconTheme`.";
          };
        };
      };
    };
  };
}
